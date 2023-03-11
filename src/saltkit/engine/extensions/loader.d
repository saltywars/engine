module saltkit.engine.extensions.loader;

import saltkit.engine.extensions.path;
import saltkit.engine.log;
import std.file;
import std.path;

@safe:

enum metaFileName = "saltkit-extension.ini";

struct ExtensionInfos
{
    ExtensionInfo[] core;
    ExtensionInfo[] distro;
    ExtensionInfo[] addons;
}

struct ExtensionInfo
{
    string name;
    string version_;
    string copyright;
    string authors;
    ExtensionDirectory directory;
    Dependency[] dependencies;
}

struct ExtensionDirectory
{
    string path;
    string metaFilePath;
}

struct Dependency
{
    string name;
    string versionConstraint;
}

ExtensionInfos discoverExtensions(const ExtensionDirectoryPaths dirPaths)
{
    auto result = ExtensionInfos();

    logTrace("Discovering core extensions");
    result.core = discoverExtensions(dirPaths.core);

    logTrace("Discovering distro extensions");
    result.distro = discoverExtensions(dirPaths.distro);

    logTrace("Discovering addon extensions");
    result.addons = discoverExtensions(dirPaths.addons);

    return result;
}

ExtensionInfo[] discoverExtensions(string directoryPath)
{
    ExtensionInfo[] result;
    foreach (entry; directoryPath.dirEntries(SpanMode.shallow))
    {
        logTrace("Discovering extension: ", entry);

        if (!entry.isDir)
        {
            logTrace(entry, ": Skipped, not a directory");
            continue;
        }

        ExtensionDirectory extDir;
        if (!discoverExtension(entry, extDir))
        {
            logWarning(entry, ": Not a valid extension");
            continue;
        }

        ExtensionInfo extInfo;
        if (!loadExtensionInfo(extDir, extInfo))
        {
            logError(entry, ": Bad extension");
            continue;
        }

        result ~= extInfo;
    }

    return result;
}

bool discoverExtension(const string directoryPath, out ExtensionDirectory result)
{
    immutable metaFilePath = directoryPath.buildPath(metaFileName);
    if (!directoryPath.exists)
        return false;

    result = ExtensionDirectory(directoryPath, metaFilePath);

    return true;
}

bool loadExtensionInfo(const ExtensionDirectory extDir, out ExtensionInfo result)
{
    import inilike.read : iniLikeStringReader;
    import inilike.common : isComment, parseKeyValue;

    auto ini = iniLikeStringReader(extDir.metaFilePath.readText);

    result = ExtensionInfo();

    foreach (group; ini.byGroup)
    {
        switch (group.groupName)
        {
        case "extension":
            {
                foreach (entry; group.byEntry)
                {
                    // skip empty lines and comments
                    if ((entry.length == 0) || entry.isComment)
                        continue;

                    auto kvp = parseKeyValue(entry);

                    switch (kvp.key)
                    {
                        enum simpleCase(string name, string prop = name) =
                            `case "` ~ name ~ `": `
                            ~ `if (result.` ~ prop ~ ` !is null)`
                            ~ `logWarning(extDir.metaFilePath, ": Duplicate [extension] key ` ~ '`' ~ name ~ '`' ~ `");`
                            ~ `result.` ~ prop ~ ` = stripQuotes(kvp.value);`
                            ~ `break;`;
                        mixin(simpleCase!"name");
                        mixin(simpleCase!("version", "version_"));
                        mixin(simpleCase!"copyright");
                        mixin(simpleCase!"authors");
                    default:
                        logTrace("Skipping unknown INI [pathmap] entry: ", kvp.value);
                        break;
                    }
                }

                break;
            }

        case "dependencies":
            {
                foreach (entry; group.byEntry)
                {
                    // skip empty lines and comments
                    if ((entry.length == 0) || entry.isComment)
                        continue;

                    auto kvp = parseKeyValue(entry);
                    result.dependencies ~= Dependency(kvp.key, kvp.value);
                }

                break;
            }

        default:
            logTrace("Skipping unknown ");
            break;
        }
    }

    bool success = true;

    if (result.name is null)
    {
        logError(extDir.metaFilePath, ": [extension] `name` missing");
        success = false;
    }

    if (result.version_ is null)
        logWarning(extDir.metaFilePath, ": [extension] `version` missing");

    result.directory = extDir;
    return success;
}

string stripQuotes(char quote = '"')(scope return const string input)
{
    if (input.length > 2)
        if (input[0] == quote)
            if (input[$ - 1] == quote)
                return input[1 .. ($ - 1)];

    return input;
}
