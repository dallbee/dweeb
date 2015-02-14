module types;

import vibe.d;
import app;
import std.datetime;
import std.array;
import tinyredis.redis;

class Data
{
    Date date;
    RedisReply!string pageList;
    string[string] page;

    this()
    {
        date = cast(Date)Clock.currTime;
    }
}

string[string] unzipArray(Response arr)
{
    string[string] content;
    string* key;
    while(!arr.empty) {
        key = &(arr.front.value);
        arr.popFront;
        content[*key] = arr.front.value;
        arr.popFront;
    }

    return content;
}
