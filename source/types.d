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
    import std.stdio;
    string[string] content;
    /*foreach(ref v; arr.values) {
        string key = v.value;
        
        v.popFront;
        content[key] = v.front.value;
        writeln(key);
        writeln(v.front.value);
    }*/

    return content;
}
