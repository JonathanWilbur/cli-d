# Command-Line Interface D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2017
* License: [MIT License](https://mit-license.org/)
* Version: [0.1.0](http://semver.org/)

## Why?

I found a problem with the [D Programming Language](https://dlang.org/) 
[Standard Library](https://dlang.org/phobos/index.html)'s 
[std.getopt](https://dlang.org/phobos/std_getopt.html)
module in the process of creating my own command-line tools for my 
[ASN.1 Library](https://github.com/JonathanWilbur/asn1-d). After developing the 
library for almost a year, I realized--to my chagrin--that 
[std.getopt.getopt](https://dlang.org/phobos/std_getopt.html#.getopt) does not
execute the callbacks associated with command-line options in the exact order
that the command-line options appear.

In other words, if your 
[std.getopt.getopt](https://dlang.org/phobos/std_getopt.html#.getopt)
looks like this:

```d
GetoptResult getOptResult = getopt(
    args,
    "i|int|integer", &encodeInteger,
    "n|null", &encodeNull
);
```

and your command looks like this: `./executable -n -i 15 -n`, the 
`encodeNull` callback will be executed twice, then the `encodeInteger`
callback will be executed. If the command-line tool you are using 
depends upon the order in which options appear, then you are S.O.L.

I consider this behavior both unintuitive and subtle; it would be all too easy
for a developer using [std.getopt](https://dlang.org/phobos/std_getopt.html)
to accidentally introduce a bug into a production environment. For that reason,
I insist upon creating my own similar library, which I might submit to the
[Standard Library](https://dlang.org/phobos/index.html), since it appears that
[they would like a new implementation anyways](https://wiki.dlang.org/Wish_list).

## Competitors and Their Shortcomings

There are three alternatives that already exist for 
[std.getopt](https://dlang.org/phobos/std_getopt.html), which are:

* [Darg](https://github.com/jasonwhite/darg) by [Jason White](https://github.com/jasonwhite).
* [Commando](https://github.com/SirTony/commando) by [Tony J. Ellis](https://github.com/SirTony).
* [FunOpt](https://github.com/CyberShadow/ae/blob/master/utils/funopt.d) by [Vladimir Panteleev](https://github.com/CyberShadow).

And while all of them are decent for parsing command-line options as far as I
can see, I have the following objections to them:

* No support for Windows / DOS-Style arguments
* Unclear support for redundant options
* Built-in `--help` instead of leaving it to the developer.
* Unclear order of execution

Further, I believe that what has taken the developers of these other libraries
no less than 600 lines of code can be done in about half of that. Also, some 
of them, such as [FunOpt](https://github.com/CyberShadow/ae/blob/master/utils/funopt.d), 
are released under the 
[Mozilla Public License (MPL)](https://www.mozilla.org/en-US/MPL/2.0/). I'm
sure it is a reasonable license, but since I do not know what including it in 
my projects would entail, I cannot trust it.

## Compile and Install

In `build/scripts` there are three scripts you can use to build the library.
When the library is built, it will be located in `build/libraries`.

### On POSIX-Compliant Machines (Linux, Mac OS X)

Run `./build/scripts/build.sh`.
If you get a permissions error, you need to set that file to be executable
using the `chmod` command.

### On Windows

Run `.\build\scripts\build.bat` from a `cmd` or run `.\build\scripts\build.ps1`
from the PowerShell command line. If you get a warning about needing a 
cryptographic signature for the PowerShell script, it is probably because
your system is blocking running unsigned PowerShell scripts. Just run the
other script if that is the case.

## Usage

## See Also

* [Program Argument Syntax Conventions for POSIX / GNU Operating Systems](https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html).

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
comment on this on GitHub. If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space). :boar: