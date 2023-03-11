module saltkit.engine.bootstrapper;

import saltkit.engine.extensions.loader;
import saltkit.engine.extensions.path;
import saltkit.engine.extensions.host;
import saltkit.engine.log;

@safe:

int bootstrap()
{
    logTrace("Starting up");

    ExtensionDirectoryPaths extDirPaths;
    if (!loadPathMap(extDirPaths))
        return 1;

    extDirPaths = extDirPaths.expandPaths();

    if (!checkDirectoryPaths(extDirPaths))
        return 1;

    ExtensionInfos extInfos = discoverExtensions(extDirPaths);

    logTrace("Config loaded");

    try
    {
        run(extInfos);
    }
    catch (Exception ex)
    {
        logException(ex);
        return 1;
    }

    return 0;
}
