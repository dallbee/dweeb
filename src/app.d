import vibe.d;
import tinyredis.redis;
//import helper.view;
import content;

//Redis redis;
//View view;

shared static this()
{
    // Initialize resources
    //setLogFile("log.txt", LogLevel.info);
    auto server = new HTTPServerSettings;
    server.port = 8080;
    server.errorPageHandler = toDelegate(&errorPage);
    server.useCompressionIfPossible = true;
    server.serverString = "allbee";

    // Database initialization
    //redis = new Redis("allbee.org");

    // Render data initialization
    //view = new View;

    // Routing assignments
    auto router = new URLRouter;
    router.get("*", serveStaticFiles("static/public/"));
    router.any("*", &preRequest);

    // Load interface routes
    //auto manageInterface = new ManageInterface;
    auto contentInterface = new ContentInterface;

    // Interface routing assignments
    router.any("*", contentInterface.register());
    router.get("*", serveStaticFiles("./static/public/"));

    // Begin the server
    listenHTTP(server, router);
}

/**
 * Hooks into the request before any other routing is done
 */
void preRequest(HTTPServerRequest req, HTTPServerResponse res)
{
}

/**
 * Handles error page output to the user
 */
void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    res.render!("error.dt", req, error);
}
