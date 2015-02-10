module content;

import vibe.d;
import app;
import types;

class ContentInterface {

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);

        // ContentInterface Routes
        router.get("/", &getPage);
        router.get("/:page", &getPage);

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        string page = "";

        if ("page" in req.params)
            page = req.params["page"];

        data.page = unzipArray(redis.hgetAll("page:" ~ page));

        if ("type" in data.page) {
            switch (data.page["type"]) {
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
        render!("content.dt", data)(res);
    }

    void getList(HTTPServerRequest req, HTTPServerResponse res)
    {
        import std.stdio;

        /*if ("list" in data.page) {
            writeln(redis.zget)
        }*/
        render!("content.dt", data)(res);
    }

    void getArticle(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("content.dt", data)(res);
    }

}
