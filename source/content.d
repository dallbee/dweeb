module content;

import vibe.d;
import app;
import helper.view;

class ContentInterface {

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);

        // ContentInterface Routes
        router.get("/", &getPage);
        router.get("/:page", &getPage);

        // All routes call view, no renders in routes?
        // Can we get rid of req/res boilerplate?
        // MIXIN? http://forum.dlang.org/thread/pivjmohvywssolnmuzzu@forum.dlang.org

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        string page = "";

        if ("page" in req.params)
            page = req.params["page"];

        view.page = loadHmap(redis.send("hgetall", "page:"));

        // call pointer &("type")?

        if ("type" in view.page)
        {
            switch (view.page["type"]) {
                case "index":
                    getIndex(req, res);
                    break;
                case "list":
                    getList(req, res);
                    break;
                case "article":
                    getArticle(req, res);
                    break;
                default:
                    break;
            }
        }
    }

    void getIndex(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("content.dt", view)(res);

    }

    void getList(HTTPServerRequest req, HTTPServerResponse res)
    {
        import std.stdio;

        /*if ("list" in data.page) {
            writeln(redis.zget)
        }*/
        render!("content.dt", view)(res);
    }

    void getArticle(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("content.dt", view)(res);
    }

}
