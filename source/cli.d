/**
    A module for parsing command line options and arguments, providing both
    POSIX-compliant parsers and Windows-style parsers.

    It provides the following classes that give you the ability to parse
    command-line options in different ways:

    $(UL
        $(LI MSDOSCLIParser (For commands of the form "command /s /f:file.txt ..."))
        $(LI POSIXCLIParser (For commands of the form "command -sv -f file.txt ..."))
        $(LI GNUCLIParser (For commands of the form "command -sv --long-opt -f file.txt ..."))
    )

    Author: 
        $(LINK2 http://jonathan.wilbur.space, Jonathan M. Wilbur) 
            $(LINK2 mailto:jonathan@wilbur.space, jonathan@wilbur.space)
    Version: 0.1.0
    Date: November 20th, 2017
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

// NOTE: There is no need to handle quotes. The shell does that already.
// FIXME: An option and its argument may or may not appear as separate tokens. (In other words, the whitespace separating them is optional.) Thus, ‘-o foo’ and ‘-ofoo’ are equivalent.

///
public alias CLIException = CommandLineInterfaceException;
///
public 
class CommandLineInterfaceException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
public alias CLIOption = CommandLineInterfaceOption;
///
public
struct CommandLineInterfaceOption
{
    immutable public string token;
    immutable public void function (string) callback;
}

///
public alias CLIParser = CommandLineInterfaceParser;
///
public abstract
class CommandLineInterfaceParser
{
    public bool permitUnrecognizedOptions = false;
    public CLIOption[] recognizedOptions;

    abstract public 
    void parse(string[] tokens ...);

    // TODO:
    // void printUsage();

    public @safe nothrow 
    this (CLIOption[] options ...)
    {
        this.recognizedOptions = options;
    }

    private @system
    void executeCallbacksAssociatedWith (string option, string value)
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
///
public
class PortableOperatingSystemInterfaceCommandLineInterfaceParser : CLIParser
{
    public override
    void parse (string[] tokens ...)
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
                validateAllOptionCharacters(option);
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

    public @safe nothrow 
    this (CLIOption[] options ...)
    {
        super(options);
    }
}

// FIXME: Support --long-option=value syntax.
///
public alias GNUCLIParser = GnusNotUnixCommandLineInterfaceParser;
///
public alias GNUCommandLineInterfaceParser = GnusNotUnixCommandLineInterfaceParser;
///
public alias GnusNotUnixCLIParser = GnusNotUnixCommandLineInterfaceParser;
///
public
class GnusNotUnixCommandLineInterfaceParser : CLIParser
{
    public override
    void parse (string[] tokens ...)
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
                    currentOptions ~= token[2 .. $]; // Otherwise, it is a long option.
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
                validateAllOptionCharacters(option);
                this.executeCallbacksAssociatedWith(option, argument);
            }
        }
    }

    public @safe nothrow 
    this (CLIOption[] options ...)
    {
        super(options);
    }
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
    public override
    void parse (string[] tokens ...)
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

    public @safe nothrow 
    this (CLIOption[] options ...)
    {
        super(options);
    }
}

pragma(inline, true);
void validateAllOptionCharacters(string str)
{
    foreach (character; str)
    {
        if (!character.isAlphaNum)
            throw new CLIException
            ("Invalid option. All characters of token must be ASCII alphanumerics.");
    }
}