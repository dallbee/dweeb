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
    DateTime date;
    RedisDatabase db;
    HTTPServerRequest req;
    HTTPServerResponse res;

    this()
    {
        date = cast(DateTime)Clock.currTime;
    }

    string timestamp()
    {
        return removechars(date.toISOString, "^0-9");
    }
}

string parseMarkdown(string text)
{
    text = removechars(text, "\r");
    return cast(string)cmark_markdown_to_html(text.toStringz, cast(int)text.length, 0).fromStringz;
}