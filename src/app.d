/++
    App entry point
 +/
module app;

import saltkit.engine.bootstrapper;
import saltkit.engine.log;

private int main(string[] args) @safe
{
    bool verbose = false;

    foreach (arg; args)
        if (arg == "-v")
            verbose = true;

    LogLevel logLevel = (verbose) ? LogLevel.trace : LogLevel.info;
    setLogLevel(logLevel);

    return bootstrap();
}
