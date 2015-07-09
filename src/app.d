import vibe.d;
import vibe.db.redis.redis;
import content;
import view;

shared static this()
{
    // Initialize resources
    //setLogFile("log.txt", LogLevel.info);
    auto server = new HTTPServerSettings;
    server.bindAddresses = ["0.0.0.0"];
    server.port = 8000;
    server.errorPageHandler = toDelegate(&errorPage);
    server.useCompressionIfPossible = true;
    server.serverString = "allbee";

    auto view = new ViewData;

    // Database initialization
    auto redis = new RedisClient;
    view.db = redis.getDatabase(0);
    view.db.deleteAll();

    // Routing assignments
    auto router = new URLRouter;
    router.get("*", serveStaticFiles("static/public/"));
    router.any("*", mixin(routeDelegate!"preRequest"));

    // Load interface routes
    //auto manageInterface = new ManageInterface;
    auto contentInterface = new ContentInterface(view.db);

    // Interface routing assignments
    router.any("*", contentInterface.register(view));
    router.get("*", serveStaticFiles("./static/public/"));

    // Begin the server
    listenHTTP(server, router);
}

/**
 * Hooks into the request before any other routing is done
 */
void preRequest(ViewData view)
{
    import std.conv;
    import std.stdio;

    string agent = view.req.headers.get("User-Agent", "Unknown");
    string browser = agent[lastIndexOf(agent, " ")+1..$].replace("/", " v");
    string os = agent[indexOf(agent, ";")+1..lastIndexOf(agent, ";")].replace(";", "");

    view.context["browser"] = browser;
    view.context["ip"] = view.req.headers.get("X-REAL-IP", view.req.peer);
    view.context["os"] = os;
    view.context["referer"] = view.req.headers.get("Referer", "None");
    view.context["cookies"] = view.req.headers.get("Cookies", "None");
}

/**
 * Handles error page output to the user
 */
void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    res.render!("error.dt", req, error);
}
