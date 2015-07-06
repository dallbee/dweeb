import vibe.d;
import vibe.db.redis.redis;
import content;
import view;

shared static this()
{
    // Initialize resources
    //setLogFile("log.txt", LogLevel.info);
    auto server = new HTTPServerSettings;
    server.port = 8000;
    server.errorPageHandler = toDelegate(&errorPage);
    server.useCompressionIfPossible = true;
    server.serverString = "allbee";

    auto data = new ViewData;

    // Database initialization
    auto redis = new RedisClient("allbee.org");
    data.db = redis.getDatabase(0);
    data.db.deleteAll();

    // Routing assignments
    auto router = new URLRouter;
    router.get("*", serveStaticFiles("static/public/"));
    router.any("*", mixin(routeDelegate!"preRequest"));

    // Load interface routes
    //auto manageInterface = new ManageInterface;
    auto contentInterface = new ContentInterface(data.db);

    // Interface routing assignments
    router.any("*", contentInterface.register(data));
    router.get("*", serveStaticFiles("./static/public/"));

    // Begin the server
    listenHTTP(server, router);
}

/**
 * Hooks into the request before any other routing is done
 */
void preRequest(HTTPServerRequest req, HTTPServerResponse res, ViewData data)
{
}

/**
 * Handles error page output to the user
 */
void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    res.render!("error.dt", req, error);
}
