module content;

import vibe.d;
import app;
//import helper.view;

/**
 * Scans a directory for markdown documents
 *
 * Ignores filenames beginning with an uppercase letter. Returns a listing of
 * files found in the directory, stripping the base path and the file extension.
 *
 * Params:
 *  dir = The path (relative or absolute) to the directory to scan.
 */
string[] getContentList(const string dir)
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

class ContentInterface {

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", &(getPage));
        router.get("/article/:article", &(getPage));
        router.get("/projects", &(getPage));
        router.get("/project/:project", &(getPage));
        router.get("/privacy", &(getPage));
        router.get("/", &(getPage));
        import std.stdio; writeln(getContentList("content"));

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        //view.req = req;
        //view.res = res;
        /*view.page = view.loadHmap(redis.send("hgetall", "page:" ~ req.params.get("page", "")));

        switch (view.page.get("type", ""))
        {
            mixin(makeGetRender("index", "index.dt"));
            mixin(makeGetRender("list", "list.dt"));
            mixin(makeGetRender("article", "content.dt"));
            default: break;
        }*/
    }

    void getIndex()
    {
        /*view.pageList = view.loadList(redis.send("zrange", "list:index", 0, 5));
        foreach(e; view.pageList)
            view.data[e] = view.loadHmap(redis.send("hgetall", "page:" ~ e));
        */
    }

    void getList()
    {

    }

    void getArticle()
    {

    }
}
