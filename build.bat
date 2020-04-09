@echo off

if not "%1"=="" goto %1

:release
set bldtype=release
set ldflags=/RELEASE
set asflags=
goto build

:debug
set bldtype=debug
set ldflags=/DEBUG
set asflags=-g
goto build

:build
pushd "%~dp0"
set bld=target\%bldtype%
set ldflags=/NOLOGO /SUBSYSTEM:CONSOLE /ENTRY:start /MACHINE:X64 /LIBPATH:lib %ldflags%

if not exist %bld% mkdir %bld%

tools\nasm -f win64 %asflags% -o %bld%\git.obj src\git.asm
if %errorlevel% neq 0 goto end

tools\vc\link %ldflags% /OUT:%bld%\git.exe %bld%\git.obj kernel32.lib

:end
popd
