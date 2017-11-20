@echo off
mkdir .\documentation > nul
mkdir .\documentation\html > nul
mkdir .\build > nul
mkdir .\build\executables > nul
mkdir .\build\interfaces > nul
mkdir .\build\libraries > nul
mkdir .\build\objects > nul

dmd ^
.\source\cli.d ^
-Dd.\documentation\html\ ^
-Hd.\build\interfaces ^
-op ^
-of.\build\libraries\cli.lib ^
-Xf.\documentation\cli.json ^
-lib ^
-cov ^
-O ^
-profile ^
-release

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
del .\build\executables\*.o