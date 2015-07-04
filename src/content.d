module content;

import vibe.d;
import app;
import std.file;
import std.path;
import std.ascii;
import vibe.db.redis.redis;
import view;


class ContentInterface {

    private bool[string] contentList;
    string contentDir = "content/";

    URLRouter register(ViewData data, string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", mixin(routeDelegate!"getListing"));
        router.get("/article/:article", mixin(routeDelegate!"getContent"));
        router.get("/projects", mixin(routeDelegate!"getListing"));
        router.get("/project/:project", mixin(routeDelegate!"getContent"));
        //router.get("/privacy", mixin(routeDelegate!"getPage"));
        router.get("/", mixin(routeDelegate!"getIndex"));

        return router;
    }

    this()
    {
        generateContentList(contentDir);

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

        while(true) {
            watcher.readChanges(changes);
            foreach(c; changes)
                updateContentList(c);
        }
    }

    /**
     * Updates the contentList cache to reflect any changes to files within the
     * content folder.
     *
     * Params:
     *  change = The type of modification that was made, and the path to the
     *      respective file.
     */
    void updateContentList(DirectoryChange change)
    {
        string name = stripExtension(change.path.toString[contentDir.length..$]);
        if (!isLower(name[0]) || !endsWith(name, ".md"))
            return;

        switch(change.type) {
            case DirectoryChangeType.added:
                contentList[name] = false;
                break;
            case DirectoryChangeType.modified:
                contentList[name] = false;
                break;
            case DirectoryChangeType.removed:
                contentList.remove(name);
                break;
            default:
        }
    }

    /**
     * Inserts the list of content files into the contentHash.
     *
     * This operation destroys the existing contentList.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan
     */
    void generateContentList(const string dir)
    {
        bool[string] tmpList;

        foreach(s; getContentList(dir))
            tmpList[s] = false;

        tmpList.rehash;
        contentList = tmpList;
    }

    /**
     * Finds and returns a rendered content document
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
    string readContent(string name, RedisDatabase db)
    {
        if (!(name in contentList))
            throw new HTTPStatusException(HTTPStatus.notFound);

        string text;

        if (contentList[name]) {
            text = db.get(name);
            if (!text)
                contentList["name"] = false;
        }

        if (!contentList[name]) {
           string path = contentDir ~ name ~ ".md";
            if (!exists(path)) {
                contentList[name] = false;
                throw new HTTPStatusException(HTTPStatus.notFound);
            }

            text = parseMarkdown(readText(path));
            contentList[name] = true;
            db.set(name, text);
        }

        return text;
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
        res.render!("listing.dt");
    }

    void getContent(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
    {
        string content = readContent(req.path[1..$], data.db);
        res.render!("content.dt", content);
    }

    /**
     * Scans a directory for markdown documents
     *
     * Ignores filenames beginning with an uppercase letter. Returns a listing of
     * files found in the directory, stripping the base path and the file extension.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan.
     */
    private string[] getContentList(const string dir)
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
