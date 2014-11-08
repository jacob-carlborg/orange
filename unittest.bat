@echo off
REM ___Builds and runs Orange unit tests___


rem Test for 'delayed environment variable expansion':
set TESTVAR=before
if "%TESTVAR%" == "before" (
	set TESTVAR=after
	if not "!TESTVAR!" == "after" (
		rem Enabling env var expansion with /V, to build the list of .d files:
		cmd.exe /V /C unittest.bat
		exit /B
	)
)


rem Build list of .d files:
set dfiles=
for %%D in (
	orange\core
	orange\serialization
	orange\serialization\archives
	orange\test
	orange\util
	orange\util\collection
	orange\xml
	tests
) do (
	for %%X in (%%D\*.d) do (
		set dfiles=!dfiles! %%X
	)
)


rem Compile:
dmd -unittest -ofunittest %dfiles%


rem Run (only if compilation succeded):
if "%errorlevel%" == "0" (
	.\unittest.exe
)