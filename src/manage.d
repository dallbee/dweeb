/*module manage;

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

        // Session
        router.any("*", &checkSession);

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
        router.get("/content/page/", &getContent);
        router.get("/content/page/:page", &getContent);
        router.post("/content", &postContent);

        return router;
    }

    void checkSession(HTTPServerRequest req, HTTPServerResponse res)
    {
        if (!req.session)
            req.session = res.startSession();
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

        render!("manage/login.dt", view)(res);
    }

    void postLogin(HTTPServerRequest req, HTTPServerResponse res)
    {
        string hash = redis.send!string("hget settings password");

        if (hash.length && checkScryptPasswordHash(hash, req.form.get("password", "")))
            req.session.set("admin", true);

        res.redirect(prefix);
    }


    void getLogout(HTTPServerRequest req, HTTPServerResponse res)
    {
        res.terminateSession();
        res.redirect("/");
    }


    void getIndex(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("manage/overview.dt", view)(res);
    }


    void getContent(HTTPServerRequest req, HTTPServerResponse res)
    {
        view.uri = req.params.get("page", "");
        view.pageList = view.loadList(redis.send("keys", "page:*"), 5);
        view.data[view.uri] = view.loadHmap(redis.send("hgetall", "page:" ~ view.uri));
        render!("manage/content.dt", view)(res);
    }

    void postContent(HTTPServerRequest req, HTTPServerResponse res)
    {
        redis.send("hmset", "page:" ~ req.form.get("uri", ""),
                   "title", req.form.get("title", ""),
                   "type", req.form.get("type", ""),
                   "description", req.form.get("description", ""),
                   "abstract", req.form.get("abstract", ""),
                   "content", req.form.get("content", ""),
                   "timestamp", view.timestamp
                );

        redis.send("zadd", "list:" ~ req.form.get("type", ""),
            view.timestamp, req.form.get("uri", ""));

        res.redirect(prefix);
    }
}
*/