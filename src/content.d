module content;

import vibe.d;
import app;
//import helper.view;



class ContentInterface {

    private bool[string] contentHash;

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", &getListing);
        router.get("/article/:article", &getContent);
        router.get("/projects", &getListing);
        router.get("/project/:project", &getContent);
        router.get("/privacy", &getPage);
        router.get("/", &getIndex);
        import std.stdio; writeln(getContentList("content"));

        return router;
    }

    /**
     * Inserts the list of content files into the contentHash.
     *
     * Does not remove any outdated entries.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan
     */
    void updatePageCache(const string dir)
    {
        foreach(string s; getContentList(dir))
            contentHash[s] = True;

        contentHash.rehash;
    }

    private void getIndex(HTTPServerRequest req, HTTPServerResponse res)
    {
        /*view.pageList = view.loadList(redis.send("zrange", "list:index", 0, 5));
        foreach(e; view.pageList)
            view.data[e] = view.loadHmap(redis.send("hgetall", "page:" ~ e));
        */
        render!("index.dt");
    }

    private void getListing(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("listing.dt");
    }

    private void getContent(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("content.dt");
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
        import std.file: dirEntries, SpanMode;
        import std.algorithm: filter;
        import std.array: array;
        import std.path: stripExtension;
        import std.ascii: isLower;

        uint pos = dir.length + 1;

        return dirEntries(dir, SpanMode.depth)
            .filter!(a => a.isFile && endsWith(a.name, ".md") && isLower(a[pos]))
            .map!(a => stripExtension(a.name)[(pos)..$])
            .array;
    }
}
