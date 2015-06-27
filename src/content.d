module content;

import vibe.d;
import app;
import std.file;
//import helper.view;

extern (C) char * cmark_markdown_to_html(const char *, int, int);

class ContentInterface {

    private bool[string] contentList;
    string contentDir = "content/";

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/articles", &getListing);
        router.get("/article/:article", &getContent);
        router.get("/projects", &getListing);
        router.get("/project/:project", &getContent);
        //router.get("/privacy", &getPage);
        router.get("/", &getIndex);
        import std.stdio; writeln(getContentList("content"));

        return router;
    }

    /**
     * Inserts the list of content files into the contentHash.
     *
     * Sets any outdated entries to False. This operation is considered to be
     * expensive and should be used with care.
     *
     * Params:
     *  dir = The path (relative or absolute) to the directory to scan
     */
    void refreshContentList(const string dir)
    {
        // Invalidate all existing entries
        foreach(value; contentList)
            value = false;

        foreach(s; getContentList(dir))
            contentList[s] = true;

        contentList.rehash;
    }

    string readContent(string name)
    {
        if (!(name in contentList)) {
            // Throw error
        }

        // Get from redis

        string path = contentDir ~ name ~ ".md";
        if (!exists(path)) {
            // throw error
        }

        string text = parseMarkdown(readText(path));

        // Update redis entry

        return text;
    }

    string parseMarkdown(string text)
    {
        text = removechars(text, "\r");
        return cast(string)cmark_markdown_to_html(text.toStringz, cast(int)text.length, 0).fromStringz;
    }

    void getIndex(HTTPServerRequest req, HTTPServerResponse res)
    {
        /*view.pageList = view.loadList(redis.send("zrange", "list:index", 0, 5));
        foreach(e; view.pageList)
            view.data[e] = view.loadHmap(redis.send("hgetall", "page:" ~ e));
        */
        render!("index.dt");
    }

    void getListing(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("listing.dt");
    }

    void getContent(HTTPServerRequest req, HTTPServerResponse res)
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
        import std.algorithm: filter;
        import std.array: array;
        import std.path: stripExtension;
        import std.ascii: isLower;

        uint pos = cast(uint)dir.length + 1;

        return dirEntries(dir, SpanMode.depth)
            .filter!(a => a.isFile && endsWith(a.name, ".md") && isLower(a[pos]))
            .map!(a => stripExtension(a.name)[(pos)..$])
            .array;
    }
}
