module helper.view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import tinyredis.redis;

class View
{
    DateTime date;
    string[string] page;
    string[] pageList;
    HTTPServerRequest req;
    HTTPServerResponse res;

    this()
    {
        date = cast(DateTime)Clock.currTime;
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

    static string[] loadList(Response arr)
    {
        string[] list;
        foreach(e; arr)
        {
            list ~= e.value;
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
