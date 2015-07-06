module view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import std.string;
import vibe.db.redis.redis;

extern (C) char * cmark_markdown_to_html(const char *, int, int);

template routeDelegate(string route)
{
    const char[] routeDelegate =
        `delegate (HTTPServerRequest req, HTTPServerResponse res) => ` ~ route ~ `(req, res, data)`;
}

class ViewData
{
    RedisDatabase db;
}

string parseMarkdown(string content)
{
    import std.conv;

    content = content.removechars("\r");
    return cmark_markdown_to_html(content.toStringz, content.length.to!int, 0).to!string;
}