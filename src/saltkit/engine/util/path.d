module saltkit.engine.util.path;

import std.file;
import std.path;

@safe:

/++
    Returns: folder where the program's executable is located in
 +/
string thisExeDir()
{
    return thisExePath.dirName;
}
