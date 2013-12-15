@echo off

Rem windows batch file to build smokeview from the command line

IF "%SETUP_IFORT_COMPILER%"=="1" GOTO envexist

set SETUP_IFORT_COMPILER=1

echo Setting up compiler environment
call "%IFORT_COMPILER14%\bin\compilervars" ia32 %VS_VERSION%
if exist "%VS_COMPILER%\vcvars32x86_amd64.bat" call "%VS_COMPILER%\vcvars32x86_amd64"
:envexist

erase *.obj
erase *.mod
make -f ..\Makefile intel_win_32
pause
