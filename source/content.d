module content;

import vibe.d;
import app;
import std.stdio;

class ContentInterface {

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);

        // ContentInterface Routes
        router.get("/", &getPage);
        router.get("/:page", &getPage);
        router.get("/:page/:subpage", &getPage);

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!("main.dt")(res);
    }

}
