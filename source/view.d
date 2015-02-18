module helper.view;

import vibe.d;
import app;
import std.datetime;
import std.array;
import tinyredis.redis;

class View
{
    Date date;
    RedisReply!string pageList;
    string[string] page;

    this()
    {
        date = cast(Date)Clock.currTime;
    }

    static string[string] loadHmap(ref Response arr)
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


