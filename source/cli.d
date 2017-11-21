/**
    A module for parsing command line options and arguments, providing both
    POSIX-compliant parsers and Windows-style parsers. It is very simple in
    that it merely maps command-line options to callbacks, and

    It provides the following classes that give you the ability to parse
    command-line options in different ways:

    $(UL
        $(LI MSDOSCLIParser (For commands of the form "command /s /f:file.txt ..."))
        $(LI POSIXCLIParser (For commands of the form "command -sv -f file.txt ..."))
        $(LI GNUCLIParser (For commands of the form "command -sv --long-opt -f file.txt ..."))
    )

    $(LINK2 https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html, 
        Program Argument Syntax Conventions) says the following:

    $(I
        An option and its argument may or may not appear as separate tokens. 
        (In other words, the whitespace separating them is optional.) Thus, 
        ‘-o foo’ and ‘-ofoo’ are equivalent.
    )

    But because of the ambiguities that introduces, this library will treat all
    groups of multiple characters preceded by a single dash '-' as several 
    bundled options, rather than one option followed by an argument with no 
    space between them. In other words $(D ./foo -bbaz) will be equivalent to
    $(D ./foo -b -b -a -z), not $(D ./foo -b baz).

    If an option is not supplied with an argument, the associated callback is
    executed with the second parameter, $(D argument), set to an empty string.
    It is on the developer to handle the absence of an argument within the 
    callback if one is expected for a given option.

    Author: 
        $(LINK2 http://jonathan.wilbur.space, Jonathan M. Wilbur) 
            $(LINK2 mailto:jonathan@wilbur.space, jonathan@wilbur.space)
    Version: 1.0.0
    Date: November 21st, 2017
    License: $(https://mit-license.org/, MIT License)
    Standards:
        $(LINK2 https://standards.ieee.org/findstds/standard/1003.1-2008.html, POSIX)
    See_Also:
        $(LINK2 https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html, Program Argument Syntax Conventions)
    Examples:
    ---
    void testeroni (string value)
    {
        import std.stdio : writeln;
        writeln("Made it here with value: ", value);
    }

    void main(string[] args)
    {
        // executable -b
        // POSIXCLIParser cli = new POSIXCLIParser(
        //     CLIOption("b", &testeroni)
        // );

        // executable -b --blap argument
        // GNUCLIParser cli = new GNUCLIParser(
        //     CLIOption("blap", &testeroni),
        //     CLIOption("b", &testeroni)
        // );

        // executable /blap:argument
        MSDOSCLIParser cli = new MSDOSCLIParser(
            CLIOption("blap", &testeroni)
        );

        cli.parse(args[1 .. $]);
    }

    ---
*/
module cli;
import std.ascii : isAlphaNum, isGraphical;
import std.stdio : writeln;

version (unittest)
{
    import std.exception : assertThrown;
}

// NOTE: There is no need to handle quotes. The shell does that already.
// TODO: Invariants

///
public alias CLIException = CommandLineInterfaceException;
/// An exception that gets thrown if a command-line option is not recognized
public 
class CommandLineInterfaceException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
public alias CLIOption = CommandLineInterfaceOption;
/// A mapping between a command-line option and a callback
public
struct CommandLineInterfaceOption
{
    immutable public string token;
    immutable public void delegate (string) callback;

    /// Constructor that accepts a delegate
    public nothrow @safe
    this (in string token, in void delegate (string) callback)
    {
        this.token = token;
        this.callback = callback;
    }

    /// Constructor that accepts a function
    public nothrow @system
    this (in string token, in void function (string) callback)
    {
        import std.functional : toDelegate;
        this.token = token;
        this.callback = toDelegate(callback);
    }
}

///
public alias CLIParser = CommandLineInterfaceParser;
/// An abstract class from which all command-line parsers will inherit
public abstract
class CommandLineInterfaceParser
{
    /*
        Whether a $(D CLIException) should be thrown if an unrecognized
        option is encountered
    */
    public bool permitUnrecognizedOptions = false;

    /// The list of options that will be recognized by this CLI parser
    const public CLIOption[] recognizedOptions;

    /* 
        Interpret a sequence of tokens, typically obtained from the arguments 
        passed into $(D main()).
    */
    abstract public 
    void parse(in string[] tokens ...) const;

    /// Constructor that accepts the list of options to parse
    public @safe nothrow 
    this (CLIOption[] options ...)
    {
        this.recognizedOptions = options;
    }

    /*
        Searches the list of recognizedOptions for a matching option, and 
        executes the associated callbacks, optionally throwing a 
        $(D CLIException) if configured to do so when no matching option
        is found.
    */
    private @system
    void executeCallbacksAssociatedWith (in string option, in string value) const
    {        
        bool optionRecognized = false;
        foreach (ro; this.recognizedOptions)
        {
            if (option == ro.token) 
            {
                ro.callback(value);
                optionRecognized = true;
            }
        }

        if (!permitUnrecognizedOptions && !optionRecognized)
            throw new CLIException
            ("Unrecognized option: " ~ option);
    }
}

///
public alias POSIXCLIParser = 
    PortableOperatingSystemInterfaceCommandLineInterfaceParser;
///
public alias POSIXCommandLineInterfaceParser = 
    PortableOperatingSystemInterfaceCommandLineInterfaceParser;
///
public alias PortableOperatingSystemInterfaceCLIParser = 
    PortableOperatingSystemInterfaceCommandLineInterfaceParser;
/**
    A command-line parser that strictly follows POSIX rules for command-line
    options, meaning that it accepts command-line options in short form, such
    as $(D -o), but not long form, such as $(D --option). To use long form,
    use $(D GNUCLIParser).
*/
public
class PortableOperatingSystemInterfaceCommandLineInterfaceParser : CLIParser
{
    /* 
        Interpret a sequence of tokens, typically obtained from the arguments 
        passed into $(D main()).
    */
    public override @system
    void parse (in string[] tokens ...) const
    {
        for (size_t i = 0u; i < tokens.length; i++)
        {
            // Parse the next token ahead of time to determine if it is an argument.
            string argument = "";
            if ((i+1 < tokens.length) && (tokens[i+1][0] != '-'))
                argument = tokens[i+1];

            // Parse the current token
            string[] currentOptions = []; // Array, because bundling is possible.
            string token = tokens[i];
            if (token.length >= 2u && token[0] == '-') // An option
            {
                if (token.length == 2u && token[1] == '-') break;
                string option = token[1 .. $];
                foreach (character; option)
                {
                    if (!character.isAlphaNum)
                        throw new CLIException
                        ("Invalid option. All characters of option must be ASCII alphanumerics.");
                }
                foreach (character; option)
                {
                    currentOptions ~= cast(string) [character];
                }
            }

            foreach (option; currentOptions)
            {
                this.executeCallbacksAssociatedWith(option, argument);
            }
        }
    }

    /// Constructor that accepts the list of options to parse
    public @safe
    this (CLIOption[] options ...)
    {
        foreach (option; options)
        {
            if (option.token.length != 1u)
                throw new CLIException
                ("Invalid option. All options for POSIXCLIParsers must be exactly one character in length.");

            if (!option.token[0].isAlphaNum)
                throw new CLIException
                ("Invalid option. All characters of option must be ASCII alphanumerics.");
        }
        super(options);
    }
}

@system
unittest
{
    ubyte callbackCalled;
    string argument = "";
    void callback (string value) { callbackCalled++; argument = value; }

    POSIXCLIParser cli = new POSIXCLIParser(
        CLIOption("c", &callback)
    );

    callbackCalled = 0u;
    cli.parse("-c");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "-c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-cc");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "blap", "-c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "-c", "blap");
    assert(callbackCalled == 2u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("-cc", "blap", "-c");
    assert(callbackCalled == 3u);
    assert(argument == "");

    // Throws because all options for POSIXCLIParser must be only one character in length.
    assertThrown!CLIException(new POSIXCLIParser(CLIOption("gt2", &callback)));
    assertThrown!CLIException(cli.parse("-="));
    assertThrown!CLIException(cli.parse("-?"));
}

///
public alias GNUCLIParser = GnusNotUnixCommandLineInterfaceParser;
///
public alias GNUCommandLineInterfaceParser = GnusNotUnixCommandLineInterfaceParser;
///
public alias GnusNotUnixCLIParser = GnusNotUnixCommandLineInterfaceParser;
/**
    A command-line parser that slightly deviates from the POSIX rules by 
    allowing long-form options, as are common in GNU/Linux executables.
    The long-form options can be separated from their arguments either by
    whitespace or by an equal sign. 
*/
public
class GnusNotUnixCommandLineInterfaceParser : CLIParser
{
    /* 
        Interpret a sequence of tokens, typically obtained from the arguments 
        passed into $(D main()).
    */
    public override @system
    void parse (in string[] tokens ...) const
    {
        for (size_t i = 0u; i < tokens.length; i++)
        {
            // Parse the next token ahead of time to determine if it is an argument.
            string argument = "";
            if ((i+1 < tokens.length) && (tokens[i+1][0] != '-'))
                argument = tokens[i+1];

            // Parse the current token
            string[] currentOptions = []; // Array, because bundling is possible.
            string token = tokens[i];
            if (token.length >= 2u && token[0] == '-') // An option
            {
                if (token[1] == '-') // Long option or End-of-Options
                {
                    if (token.length == 2u) break; // If end of options token "--" encountered.
                    size_t j = 1u;
                    while (j < token.length)
                    {
                        if (token[j] == '=') break;
                        j++;
                    }
                    currentOptions ~= token[2 .. j]; // Otherwise, it is a long option.
                    if (j < token.length) argument = token[j+1 .. $];
                }
                else // Short option
                {
                    foreach (character; token[1 .. $])
                    {
                        currentOptions ~= cast(string) [character];
                    }
                }
            }

            foreach (option; currentOptions)
            {
                if (option.length == 0u)
                    throw new CLIException
                    ("Invalid option. Options may not be empty strings.");

                foreach (character; option)
                {
                    if (!character.isAlphaNum && character != '-')
                        throw new CLIException
                        ("Invalid option. All characters of option must be ASCII alphanumerics or dashes.");
                }
                this.executeCallbacksAssociatedWith(option, argument);
            }
        }
    }

    /// Constructor that accepts the list of options to parse
    public @safe
    this (CLIOption[] options ...)
    {
        foreach (option; options)
        {
            if (option.token.length == 0u)
                throw new CLIException
                ("Invalid option. Option tokens may not be empty strings.");

            foreach (character; option.token)
            {
                if (!character.isAlphaNum && character != '-')
                    throw new CLIException
                    ("Invalid option. All characters of option must be ASCII alphanumerics.");
            }
        }
        super(options);
    }
}

@system
unittest
{
    ubyte callbackCalled;
    string argument = "";
    void callback (string value) { callbackCalled++; argument = value; }

    GNUCLIParser cli = new GNUCLIParser(
        CLIOption("c", &callback),
        CLIOption("cback", &callback),
        CLIOption("call-back", &callback),
    );

    callbackCalled = 0u;
    cli.parse("-c");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "-c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-cc");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "blap", "-c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "-c", "blap");
    assert(callbackCalled == 2u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("-cc", "blap", "-c");
    assert(callbackCalled == 3u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--call-back");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback", "--cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback", "-c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("-c", "--cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback", "blap", "--cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback", "--cback", "blap");
    assert(callbackCalled == 2u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("-cc", "blap", "--cback");
    assert(callbackCalled == 3u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback=");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("--cback=blap");
    assert(callbackCalled == 1u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("--cback=");
    assert(callbackCalled == 1u);
    assert(argument == "");

    assertThrown!CLIException(cli.parse("-="));
    assertThrown!CLIException(cli.parse("-?"));
    assertThrown!CLIException(cli.parse("--="));
    assertThrown!CLIException(cli.parse("-?"));
}

///
public alias MSDOSCLIParser = 
    MicrosoftDiskOperatingSystemCommandLineInterfaceParser;
///
public alias MSDOSCommandLineInterfaceParser = 
    MicrosoftDiskOperatingSystemCommandLineInterfaceParser;
///
public alias MicrosoftDiskOperatingSystemCLIParser = 
    MicrosoftDiskOperatingSystemCommandLineInterfaceParser;
///
public
class MicrosoftDiskOperatingSystemCommandLineInterfaceParser : CLIParser
{
    /* 
        Interpret a sequence of tokens, typically obtained from the arguments 
        passed into $(D main()).
    */
    public override @system
    void parse (in string[] tokens ...) const
    {
        for (size_t i = 0u; i < tokens.length; i++)
        {
            string token = tokens[i];
            if (token.length >= 2u && token[0] == '/')
            {
                string option = "";
                string argument = "";
                for (size_t j = 1u; j < token.length; j++)
                {
                    if (token[j] == ':')
                    {
                        option = token[1 .. j];
                        argument = token[j+1 .. $];
                        break;
                    }
                }
                if (option == "") option = token[1 .. $];

                if (option != "?")
                {
                    foreach (character; option)
                    {
                        if (!character.isAlphaNum)
                            throw new CLIException
                            ("Invalid option. All characters of CLI option must be ASCII alphanumerics or '?'.");
                    }
                }

                foreach (character; argument)
                {
                    if (!character.isGraphical)
                        throw new CLIException
                        ("Invalid option. All characters of CLI argument must be graphical.");
                }

                this.executeCallbacksAssociatedWith(option, argument);
            }
        }
    }

    /// Constructor that accepts the list of options to parse
    public @safe
    this (CLIOption[] options ...)
    {
        foreach (option; options)
        {
            if (option.token.length == 0u)
                throw new CLIException
                ("Invalid option. Option tokens may not be empty strings.");

            foreach (character; option.token)
            {
                if (!character.isGraphical)
                    throw new CLIException
                    ("Invalid option. All characters of CLI option must be ASCII alphanumerics or '?'.");
            }
        }
        super(options);
    }
}

@system
unittest
{
    ubyte callbackCalled;
    string argument = "";
    void callback (string value) { callbackCalled++; argument = value; }

    MSDOSCLIParser cli = new MSDOSCLIParser(
        CLIOption("c", &callback),
        CLIOption("cback", &callback)
    );

    callbackCalled = 0u;
    cli.parse("/c");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/c", "/c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/c:blap", "/c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/c", "/c:blap");
    assert(callbackCalled == 2u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("/cback");
    assert(callbackCalled == 1u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/cback", "/cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/cback", "/c");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/c", "/cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/cback:blap", "/cback");
    assert(callbackCalled == 2u);
    assert(argument == "");

    callbackCalled = 0u;
    cli.parse("/cback", "/cback:blap");
    assert(callbackCalled == 2u);
    assert(argument == "blap");

    callbackCalled = 0u;
    cli.parse("/cback:");
    assert(callbackCalled == 1u);
    assert(argument == "");

    assertThrown!CLIException(cli.parse("/:"));
    assertThrown!CLIException(cli.parse("/%:"));
}