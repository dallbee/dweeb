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

        return router;
    }

    void getPage(HTTPServerRequest req, HTTPServerResponse res)
    {
        view.req = req;
        view.res = res;
        view.page = view.loadHmap(redis.send("hgetall", "page:" ~ req.params.get("page", "")));

        switch (view.page.get("type", "")) 
        {
            mixin(makeGetRender("index", "content.dt"));
            mixin(makeGetRender("list", "content.dt"));
            mixin(makeGetRender("article", "content.dt"));
            default: break;
        }
    }
    
    void getIndex()
    {

    }

    void getList()
    {
        
    }

    void getArticle()
    {

    }
}
