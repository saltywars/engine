module saltkit.engine.extensions.path;

import saltkit.engine.log;
import saltkit.engine.util.path;
import std.file;
import std.path;

@safe:

enum fileName = "paths.ini";

///
struct ExtensionDirectoryPaths
{
    string core = null;
    string distro = null;
    string addons = null;
}

/++
    Loads the pathmap file
 +/
bool loadPathMap(out ExtensionDirectoryPaths result)
{
    import inilike.read : iniLikeStringReader;
    import inilike.common : isComment, parseKeyValue;

    logTrace("Reading pathmap from ", fileName);

    auto ini = iniLikeStringReader(
        thisExeDir
            .buildPath(fileName)
            .readText
    );

    result = ExtensionDirectoryPaths();

    bool groupFound = false;
    foreach (group; ini.byGroup)
    {
        if (group.groupName != "pathmap")
            continue;

        groupFound = true;

        foreach (entry; group.byEntry)
        {
            // skip empty lines and comments
            if ((entry.length == 0) || entry.isComment)
                continue;

            // parse value
            auto kvp = parseKeyValue(entry);

            // process value
            switch (kvp.key)
            {
                enum simpleCase(string name) =
                    `case "` ~ name ~ `":`
                    ~ `if (result.` ~ name ~ ` !is null)`
                    ~ `logWarning(fileName, ": Duplicate [pathmap] entry ` ~ '`' ~ name ~ '`' ~ `");`
                    ~ `result.` ~ name ~ ` = kvp.value;`
                    ~ `break;`;

                mixin(simpleCase!"core");
                mixin(simpleCase!"distro");
                mixin(simpleCase!"addons");

            default:
                // unknown
                logTrace(fileName, ": Skipping unknown INI [pathmap] entry `", kvp.value, '`');
                break;
            }
        }
    }

    // pathmap group not found?
    if (!groupFound)
    {
        logCritical(fileName, ": section [pathmap] is missing");
        return false;
    }

    // validate
    bool success = true;

    if (result.core is null)
    {
        logCritical(fileName, ": Missing path for directory `core`");
        success = false;
    }

    if (result.distro is null)
    {
        logCritical(fileName, ": Missing path for directory `distro`");
        success = false;
    }

    if (result.addons is null)
    {
        logCritical(fileName, ": Missing path for directory `addons");
        success = false;
    }

    return success;
}

/++
    Expands the paths (relative to the current executable) to absolute paths
 +/
ExtensionDirectoryPaths expandPaths(in ExtensionDirectoryPaths pathMap)
{
    logTrace("Expanding paths");
    return ExtensionDirectoryPaths(
        thisExeDir.buildNormalizedPath(pathMap.core),
        thisExeDir.buildNormalizedPath(pathMap.distro),
        thisExeDir.buildNormalizedPath(pathMap.addons),
    );
}

/++
    Checks whether the paths exist and are directories
 +/
bool checkDirectoryPaths(in ExtensionDirectoryPaths paths)
{
    bool error = false;

    if (!paths.core.exists)
    {
        logCritical("Invalid extension directory (core): `", paths.core, "` does not exists");
        error = true;
    }
    else if (!paths.core.isDir)
    {
        logCritical("Invalid extension directory (core): Path `", paths.core, "` is not a directory");
        error = true;
    }

    if (!paths.distro.exists)
    {
        logCritical("Invalid extension directory (distro): `", paths.distro, "` does not exists");
        error = true;
    }
    else if (!paths.distro.isDir)
    {
        logCritical("Invalid extension directory (distro): Path `", paths.distro, "` is not a directory");
        error = true;
    }

    if (!paths.addons.exists)
    {
        logCritical("Invalid extension directory (addons: `", paths.addons, "` does not exists");
        error = true;
    }
    else if (!paths.addons.isDir)
    {
        logCritical("Invalid extension directory (addons: Path `", paths.addons, "` is not a directory");
        error = true;
    }

    return !error;
}
