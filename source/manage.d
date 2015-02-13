module manage;

import vibe.d;
import app;
import scrypt.password;
import std.stdio;

class ManageInterface {

    string prefix;

    URLRouter register(string prefix = null)
    {
        this.prefix = prefix;
        auto router = new URLRouter(prefix);

        // Login
        router.get("/login", &getLogin);
        router.post("/login", &postLogin);
        router.get("/logout", &getLogout);

        // Authentication
        router.any("*", &checkAuth);

        // Overview
        router.get("", &getIndex);
        router.get("/", &getIndex);

        // Content
        router.get("/content", &getContent);
        router.get("/content/:val", &getContent);
        router.post("/content", &postContent);

        return router;
    }

    void checkAuth(HTTPServerRequest req, HTTPServerResponse res)
    {
        if (!req.session.get!bool("admin"))
            res.redirect(prefix ~ "/login");
    }

    void getLogin(HTTPServerRequest req, HTTPServerResponse res)
    {
        if (req.session.isKeySet("admin"))
            res.redirect(prefix);

        render!("manage/login.dt", data)(res);
    }

    void postLogin(HTTPServerRequest req, HTTPServerResponse res)
    {
        string hash = redis.hget("settings", "password");

        if (hash.length && checkScryptPasswordHash(hash, req.form["password"])) {
            req.session.set("admin", true);
        }

        res.redirect(prefix);
    }


    void getLogout(HTTPServerRequest req, HTTPServerResponse res)
    {
        res.terminateSession();
        res.redirect("/");
    }


    void getIndex(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("manage/overview.dt", data)(res);
    }


    void getContent(HTTPServerRequest req, HTTPServerResponse res)
    {
        writeln("a");
        data.pageList = redis.keys("page:*");
        redis.keys("page:*");
        redis.keys("page:*");
        redis.keys("page:*");
        writeln("b");
        render!("manage/content.dt", data)(res);
    }

    void postContent(HTTPServerRequest req, HTTPServerResponse res)
    {
        redis.hset("content", req.form["title"], req.form["content"].filterMarkdown);

        res.redirect(prefix);
    }
}
