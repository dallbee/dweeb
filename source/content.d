module content;

import vibe.d;
import app;
import helper.view;

class ContentInterface {

    URLRouter register(string prefix = null)
    {
        auto router = new URLRouter(prefix);
        router.get("/", &(getPage));
        router.get("/:page", &(getPage));
        router.get("/:page/:data", &(getPage));

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        view.req = req;
        view.res = res;
        view.page = view.loadHmap(redis.send("hgetall", "page:" ~ req.params.get("page", "")));

        switch (view.page.get("type", ""))
        {
            mixin(makeGetRender("index", "index.dt"));
            mixin(makeGetRender("list", "list.dt"));
            mixin(makeGetRender("article", "content.dt"));
            default: break;
        }
    }

    void getIndex()
    {
        view.pageList = view.loadList(redis.send("zrange", "list:index", 0, 5));
        foreach(e; view.pageList)
            view.data[e] = view.loadHmap(redis.send("hgetall", "page:" ~ e));
    }

    void getList()
    {

    }

    void getArticle()
    {

    }
}
