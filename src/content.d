module content;

import vibe.d;
import app;
import std.file;
import std.path;
import std.ascii;
import std.parallelism;
import vibe.db.redis.redis;
import vibe.db.redis.types;
import mustache;
import view;

alias MustacheEngine!(string) Mustache;

class ContentInterface {

    string contentDir = "content/";

    URLRouter register(ViewData view, string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", mixin(routeDelegate!"getListing"));
        router.get("/article/:article", mixin(routeDelegate!"getContent"));
        router.get("/projects", mixin(routeDelegate!"getListing"));
        router.get("/project/:project", mixin(routeDelegate!"getContent"));
        router.get("/:content", mixin(routeDelegate!"getContent"));
        router.get("/", mixin(routeDelegate!"getIndex"));

        return router;
    }

    /**
     * Initializes a ContentInterface instance.
     *
     * Should not be initialized more than once, as the class is not context
     * independent.
     *
     * Params:
     *  db = A database instance to a redis connection pool
     */
    this(RedisDatabase db)
    {
        try {
            generateContentCache(contentDir, db);
        } catch(Exception exc) {
            // This is a temporary workaround.
        }

        logInfo("Content parsing complete.");

        runTask({
            watchContent(db);
        });
    }

    /**
     * Renders the index page
     *
     * Provides the index template with a "featured" article and project, as well
     * as metadata specified by index.md, and the data for the about.md file.
     */
    void getIndex(ViewData view)
    {
        string[string] article = readContent(view.db.zrevRange("list:article", 0, 0).front, view.db);
        string[string] project = readContent(view.db.zrevRange("list:project", 0, 0).front, view.db);
        string[string] about = readContent("about", view.db);
        string[string] content = readContent("index", view.db);

        view.res.render!("index.dt", article, project, about, content);
    }

    /**
     * Renders a listing of a content type specified by the request url.
     *
     * Lists are sorted by publish date in descending order.
     */
    void getListing(ViewData view)
    {
        immutable type = view.req.path[1..($-1)];
        string[string][string] contents;

        // Currently lacks a lookup limit. Future improvement: pagination.
        auto zrange = view.db.zrevRange("list:" ~ type, 0, -1);
        foreach(name; parallel(zrange))
            contents[name] = readContent(name, view.db);

        view.res.render!("listing.dt", contents, type);
    }

    /**
     * Renders the content item specified by the request url.
     */
    void getContent(ViewData view)
    {
        Mustache mustache;

        string[string] content = readContent(view.req.path[1..$], view.db);
        content["body"] = mustache.renderString(content["body"], view.context);
        view.res.render!("content.dt", content);
    }

    /**
     * Listen for changes to content directory, and update caches appropriately.
     *
     * Params:
     *  db = A database instance to a redis connection pool
     */
    private void watchContent(RedisDatabase db)
    {
        DirectoryWatcher watcher;
        DirectoryChange[] changes;

        watcher = watchDirectory("content/");

        while (true) {
            watcher.readChanges(changes);
            foreach(c; changes)
                updateContentCache(c, db);
        }
    }

    /**
     * Updates the contentSet cache to reflect any changes to markdown files
     * within the content folder.
     *
     * Filenames beginning with an uppercase letter are ignored.
     *
     * Params:
     *  change = The type of modification that was made, and the path to the
     *      respective file.
     *  db = A database instance to a redis connection pool
     */
    private void updateContentCache(DirectoryChange change, RedisDatabase db)
    {
        immutable pos = contentDir.length;
        string name = change.path.toString;

        if (!isLower(name[pos]) || !endsWith(name, ".md"))
            return;

        name = stripExtension(name[pos..$]);
        immutable type = name[0..max(name.indexOf('/'), 0)];

        switch (change.type) {
            case DirectoryChangeType.added:
                logInfo("Found new file: %s. Adding to cache.", change.path);
                db.zadd("list:" ~ type, readContent(name, db)["date"], name);
                break;
            case DirectoryChangeType.modified:
                logInfo("File %s was modified. Updating cache.", change.path);
                db.del(name);
                db.zadd("list:" ~ type, readContent(name, db)["date"], name);
                break;
            case DirectoryChangeType.removed:
                logInfo("File %s was removed. Clearing cache.", change.path);
                db.del(name);
                db.zrem("list:" ~ type, name);
                break;
            default:
        }
    }

    /**
     * Reads the content directory and parses all documents for metadata
     * and markdown. Results are stored in the Redis instance
     *
     * Params:
     *  dir = The content directory
     *  db = A database instance to a redis connection pool
     */
    private void generateContentCache(string dir, RedisDatabase db)
    {
        DirectoryChange change;

        foreach(path; parallel(dirEntries(dir, SpanMode.depth))) {
            change.path = Path(path);
            change.type = DirectoryChangeType.added;
            updateContentCache(change, db);
        }
    }

    /**
     * Parses metadata out of the first lines of a content document
     *
     * Metadata should be in the following format:
     * [key] value
     *
     * Metadata must be enclosed by an html comment <!-- --> and the beginning
     * and end tokens must be on their own line.
     *
     * Params:
     *  content = The fulltext string to parse.
     */
    private string[string] parseContent(string content)
    {
        string[string] data;
        import std.string;
        import std.regex;
        import std.algorithm;

        // Matches [key] value
        auto metaRegex = ctRegex!(`\[(\w*)\] *(.*)`);
        ulong end;

        bool hasMeta = content.startsWith("<!--");

        while (hasMeta) {
            hasMeta = !content.startsWith("-->");
            end = content[0..$].indexOf('\n');

            // Reminder: end is unsigned
            if (end >= content.length - 1)
                break;

            auto match = matchFirst(content[0..end++], metaRegex);
            content = content[end..$];

            if (match.empty)
                continue;

            data[match[1]] = match[2];
        }

        data["body"] = parseMarkdown(content);
        return data;
    }

    /**
     * Finds and returns a rendered content hash
     *
     * If a rendered version of a document cannot be found in the cache, the
     * raw markdown content is pulled from the filesystem, parsed, and inserted
     * into the cache.
     *
     * Params:
     *  name = The path of the file relative to the content directory, without
     *      an extension.
     *  db = A handle to the Redis connection pool
     */
    private string[string] readContent(string name, RedisDatabase db)
    {
        import std.datetime;
        string[string] contentHash;
        RedisHash!string dbHash = db.getAsHash(name);

        // Refuse to read content which was not picked up by the directory scan
        if (db.zscore("list:" ~ name[0..max(name.indexOf('/'), 0)], name).empty())
            throw new HTTPStatusException(HTTPStatus.notFound);

        // Check for content item in the DB
        if (!db.exists(name)) {
            string path = contentDir ~ name ~ ".md";
            if (!exists(path)) {
                db.del(name);
                throw new HTTPStatusException(HTTPStatus.notFound);
            }

            contentHash = parseContent(readText(path));

            // Explicitly set keys to promise safety
            dbHash["title"] = contentHash.get("title", "");
            dbHash["description"] = contentHash.get("description", "");
            dbHash["abstract"] = contentHash.get("abstract", "");
            dbHash["body"] = contentHash.get("body", "");

            try {
                dbHash["date"] = Date()
                    .fromSimpleString(contentHash.get("date", ""))
                    .toISOString;
            } catch (Exception exc) {
                logError("Invalid date specified in %s", path);
                dbHash["date"] = "";
            }
        }

        foreach(key, value; dbHash)
            contentHash[key] = value;

        return contentHash;
    }
}
