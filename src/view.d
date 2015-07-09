module view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import std.string;
import vibe.db.redis.redis;
import mustache;

alias MustacheEngine!(string) Mustache;

extern (C) char * cmark_markdown_to_html(const char *, int, int);

template routeDelegate(string route)
{
    const char[] routeDelegate =
        `(HTTPServerRequest req, HTTPServerResponse res) {`
            ~ `view.req = req;`
            ~ `view.res = res;`
            ~ route ~ `(view);`
            ~ `}`;
}

class ViewData
{
    RedisDatabase db;
    HTTPServerRequest req;
    HTTPServerResponse res;
    Mustache.Context context;

    this()
    {
        context = new Mustache.Context;
    }
}

string parseMarkdown(string content)
{
    import std.conv;

    content = content.removechars("\r");
    return cmark_markdown_to_html(content.toStringz, content.length.to!int, 0).to!string;
}