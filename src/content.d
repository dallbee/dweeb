module content;

import vibe.d;
import app;
import std.file;
import std.path;
import std.ascii;
import vibe.db.redis.redis;
import vibe.db.redis.types;
import view;


class ContentInterface {

    private bool[string] contentSet;
    string contentDir = "content/";

    URLRouter register(ViewData data, string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", mixin(routeDelegate!"getListing"));
        router.get("/article/:article", mixin(routeDelegate!"getContent"));
        router.get("/projects", mixin(routeDelegate!"getListing"));
        router.get("/project/:project", mixin(routeDelegate!"getContent"));
        router.get("/resources", mixin(routeDelegate!"getContent"));
        router.get("/about", mixin(routeDelegate!"getContent"));
        router.get("/privacy", mixin(routeDelegate!"getPrivacy"));
        router.get("/", mixin(routeDelegate!"getIndex"));

        return router;
    }

    this()
    {
        generateContentSet(contentDir);

        runTask({
            watchContent();
        });
    }

    /**
     * Listen for changes to content directory, and update caches appropriately.
     */
    void watchContent()
    {
        DirectoryWatcher watcher;
        DirectoryChange[] changes;

        watcher = watchDirectory("content/");

        while (true) {
            watcher.readChanges(changes);
            foreach(c; changes)
                updateContentSet(c);
        }
    }

    /**
     * Updates the contentSet cache to reflect any changes to files within the
     * content folder.
     *
     * Filenames beginning with an uppercase letter are ignored.
     *
     * Params:
     *  change = The type of modification that was made, and the path to the
     *      respective file.
     */
    void updateContentSet(DirectoryChange change)
    {
        string name = change.path.toString[contentDir.length..$];
        if (!isLower(name[0]) || !endsWith(name, ".md"))
            return;

        name = stripExtension(name);

        switch (change.type) {
            case DirectoryChangeType.added:
                contentSet[name] = false;
                break;
            case DirectoryChangeType.modified:
                contentSet[name] = false;
                break;
            case DirectoryChangeType.removed:
                contentSet.remove(name);
                break;
            default:
        }
    }

    /**
     * Inserts the list of content files into the contentSet.
     *
     * This operation destroys the existing contentSet.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan
     */
    void generateContentSet(const string dir)
    {
        bool[string] tmpList;

        foreach(s; getcontentSet(dir))
            tmpList[s] = false;

        tmpList.rehash;
        contentSet = tmpList;
    }

    /**
     * Parses metadata out of the first lines of a content document
     *
     * Metadata should be in the following format:
     * [key] value
     *
     * The first line not matching that format will stop the parse, and the
     * rest of the document is then treated as markdown content.
     *
     * Params:
     *  content = The fulltext string to parse.
     */
    string[string] parseContent(string content)
    {
        string[string] data;
        import std.string;
        import std.regex;

        string line;
        ulong end;

        // Matches [key] value
        auto pattern = ctRegex!(`\[(\w*)\] *(.*)`);

        while (true) {
            end = content[0..$].indexOf('\n');

            // Reminder: end is unsigned
            if (end >= content.length - 1)
                break;

            auto match = matchFirst(content[0..end++], pattern);

            if (match.empty)
                break;

            data[match[1]] = match[2];
            content = content[end..$];
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
    string[string] readContent(string name, RedisDatabase db)
    {
        string[string] contentHash;
        RedisHash!string dbHash = db.getAsHash(name);

        // Refuse to read content which was not picked up by the directory scan
        if (!(name in contentSet))
            throw new HTTPStatusException(HTTPStatus.notFound);

        // Check for content item in the DB
        if (contentSet[name]) {
            if (!db.exists(name))
                contentSet["name"] = false;
        }

        // No valid entry in the DB exists, create one
        if (!contentSet[name]) {
           string path = contentDir ~ name ~ ".md";
            if (!exists(path)) {
                contentSet[name] = false;
                throw new HTTPStatusException(HTTPStatus.notFound);
            }

            contentHash = parseContent(readText(path));

            // Explicitly set keys to promise safety
            dbHash["title"] = contentHash.get("title", "");
            dbHash["description"] = contentHash.get("description", "");
            dbHash["abstract"] = contentHash.get("abstract", "");
            dbHash["date"] = contentHash.get("date", "");
            dbHash["body"] = contentHash.get("body", "");

            contentSet[name] = true;
        }

        // Inefficent when contentHash is already available, but safe
        foreach(key, value; dbHash)
            contentHash[key] = value;

        return contentHash;
    }

    void getIndex(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
    {
        /*view.pageList = view.loadList(redis.send("zrange", "list:index", 0, 5));
        foreach(e; view.pageList)
            view.data[e] = view.loadHmap(redis.send("hgetall", "page:" ~ e));
        */
        res.render!("index.dt");
    }

    void getListing(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
    {
        import std.algorithm: filter, startsWith;

        string[string][string] contents;
        string prefix = req.path[1..($-1)];

        auto list = contentSet.byKey
            .filter!(a => startsWith(a, prefix));

        foreach(name; list)
            contents[name] = readContent(name, data.db);

        res.render!("listing.dt", contents, prefix);
    }

    void getContent(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
    {
        string[string] content = readContent(req.path[1..$], data.db);
        res.render!("content.dt", content);
    }

    void getPrivacy(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
    {
        string[string] content = readContent(req.path[1..$], data.db);
        res.render!("content.dt", content);
    }
    /**
     * Scans a directory for markdown documents
     *
     * Ignores filenames beginning with an uppercase letter. Returns a listing of
     * files found in the directory, stripping the base path and the file extension.
     *
     * Filenames beginning with an uppercase letter are ignored.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan.
     */
    private string[] getcontentSet(const string dir)
    {
        import std.algorithm: filter;
        import std.array: array;

        uint pos = cast(uint)dir.length;

        return dirEntries(dir, SpanMode.depth)
            .filter!(a => a.isFile && endsWith(a.name, ".md") && isLower(a[pos]))
            .map!(a => stripExtension(a.name)[pos..$])
            .array;
    }
}
