module helper.view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import std.string;
import tinyredis.redis;

extern (C) char * cmark_markdown_to_html(const char *, int);

class View
{
    DateTime date;
    string uri;
    string[string] page;
    string[string][string] data;
    string[] pageList;
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

    static string[string] loadHmap(Response arr)
    {
        string[string] map;
        string* key;

        while(!arr.empty)
        {
            key = &(arr.front.value);
            arr.popFront;
            map[*key] = arr.front.value;
            arr.popFront;
        }

        return map;
    }

    static string[] loadList(Response arr, size_t prefixLength = 0)
    {
        string[] list;
        foreach(e; arr)
        {
            list ~= e.value[prefixLength..$];
        }

        return list;
    }
}

string makeGetRender(string pageType, string dietTemplate)
{
    import std.string;
    return `case "` ~ pageType ~ `": `
        `get` ~ capitalize(pageType) ~ `(); `
        `render!("` ~ dietTemplate ~ `", view)(res); `
        `break;`;
}

string parseMarkdown(string text)
{
    text = removechars(text, "\r");
    return cast(string)cmark_markdown_to_html(text.toStringz, cast(int)text.length).fromStringz;
}
