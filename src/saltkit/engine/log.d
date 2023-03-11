module saltkit.engine.log;

import std.logger : defaultLogFunction;
public import std.logger : LogLevel;

@safe:

/// Logs a trace/debug message
alias logTrace = defaultLogFunction!(LogLevel.trace);

/// Logs an informational message
alias logInfo = defaultLogFunction!(LogLevel.info);

/// Logs a warning
alias logWarning = defaultLogFunction!(LogLevel.warning);

/// Logs an non-critical error
alias logError = defaultLogFunction!(LogLevel.error);

/// Logs a critical error
alias logCritical = defaultLogFunction!(LogLevel.critical);

/// Logs a fatal error and raises an Error to halt execution by crashing the application
alias logFatalAndCrash = defaultLogFunction!(LogLevel.fatal);

///
alias log = logInfo;

/++
    Logs an exception (including a stack trace)
 +/
void logException(LogLevel logLevel = LogLevel.error, LogLevel details = LogLevel.trace)(
    Throwable exception,
    string description = "Exception",
    int line = __LINE__,
    string file = __FILE__,
    string funcName = __FUNCTION__,
    string prettyFuncName = __PRETTY_FUNCTION__,
    string moduleName = __MODULE__,
)
@safe nothrow
{
    import std.logger : log;
    import std.string : format;

    try
    {
        log(
            logLevel,
            line, file, funcName, prettyFuncName, moduleName,
            format!"%s: %s"(description, exception.msg)
        );

        try
        {
            log(
                details,
                line, file, funcName, prettyFuncName, moduleName,
                format!"Details: %s"(() @trusted { return exception.toString(); }())
            );
        }
        catch (Exception ex)
        {
            logTrace(format!"Failed to log details: %s"(ex.msg));
        }
    }
    catch (Exception)
    {
        // suppress
    }
}

/++
    Sets the [LogLevel] of the default logger (also known as `sharedLog`)
 +/
void setLogLevel(LogLevel logLevel)
{
    import std.logger : Logger, sharedLog;

    Logger l = (() @trusted { return (cast() sharedLog); })();
    l.logLevel = logLevel;
}