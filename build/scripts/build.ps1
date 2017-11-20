mkdir .\documentation 2>&1 | Out-Null
mkdir .\documentation\html 2>&1 | Out-Null
mkdir .\build 2>&1 | Out-Null
mkdir .\build\executables 2>&1 | Out-Null
mkdir .\build\interfaces 2>&1 | Out-Null
mkdir .\build\libraries 2>&1 | Out-Null
mkdir .\build\objects 2>&1 | Out-Null

dmd `
.\source\cli.d `
-Dd".\\documentation\\html\\" `
-Hd".\\build\\interfaces" `
-op `
-of".\\build\\libraries\\cli.lib" `
-Xf".\\documentation\\cli.json" `
-lib `
-cov `
-O `
-profile `
-release

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
Remove-Item -path .\build\executables\* -include *.o