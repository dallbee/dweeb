module helper.view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import tinyredis.redis;

class View
{
    Date date;
    string[string] page;
    //RedisReply!string pageList;
    Response[string] data;
    HTTPServerRequest req;
    HTTPServerResponse res;

    this()
    {
        date = cast(Date)Clock.currTime;
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
}

string makeGetRender(string page, string dietTemplate)
{
    import std.string;
    return `case "` ~ page ~ `": `
        `get` ~ capitalize(page) ~ `(); `
        `render!("` ~ dietTemplate ~ `", view)(res); `
        `break;`;
}
