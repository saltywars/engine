module saltkit.engine.extensions.host;

import saltkit.engine.log;
import saltkit.engine.extensions.loader;
import std.process;

@safe:

void run(ExtensionInfos extensionInfos)
{
    foreach (ext; extensionInfos.core)
        logInfo(ext);
}
