import vibe.d;
import manage;
import content;
import types;
import tinyredis.redis;

Redis redis;
Data data;

shared static this()
{
    // Initialize resources
    //setLogFile("log.txt", LogLevel.info);
    auto server = new HTTPServerSettings;
    server.port = 8080;
    server.errorPageHandler = toDelegate(&errorPage);
    server.useCompressionIfPossible = true;
    server.serverString = "dallbee";
    server.sessionStore = new MemorySessionStore;
    server.sessionIdCookie = "session";

    // Database initialization
    redis = new Redis("dallbee.com");

    // Render data initialization
    data = new Data;

    // Routing assignments
    auto router = new URLRouter;
    router.get("*", serveStaticFiles("static/public/"));
    router.any("*", &preRequest);

    // Load interface routes
    auto manageInterface = new ManageInterface;
    auto contentInterface = new ContentInterface;

    // Interface routing assignments
    router.any("*", manageInterface.register("/manage"));
    router.any("*", contentInterface.register());

    // Begin the server
    listenHTTP(server, router);
}

/**
 * Hooks into the request before any other routing is done
 */
void preRequest(HTTPServerRequest req, HTTPServerResponse res)
{
    if (!req.session)
        req.session = res.startSession();
}

/**
 * Handles error page output to the user
 */
void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    res.render!("error.dt", req, error);
}
