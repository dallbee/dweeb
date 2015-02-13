module types;

import vibe.d;
import app;
import std.datetime;
import std.array;

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

string[string] unzipArray(RedisReply!string arr)
{
    string[string] content;
    foreach(string s; arr) {
        arr.popFront;
        content[s] = arr.front;
    }

    return content;
}