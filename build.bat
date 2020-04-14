@echo off
setlocal

if not "%1"=="" goto %1

:release
set ldflags=/RELEASE
set asflags=
goto build

:debug
set ldflags=/DEBUG
set asflags=-g

:build
pushd "%~dp0"

if not exist env.bat goto init_env
call env.bat

set bld=target
set ldflags=/NOLOGO /SUBSYSTEM:CONSOLE /ENTRY:start /MACHINE:X64 %ldflags%

if not exist %bld% (mkdir %bld%) else (del /f /q %bld%\*.*)

nasm -f win64 %asflags% -o %bld%\git.obj src\git.asm
if %errorlevel% neq 0 goto end

link %ldflags% /OUT:%bld%\git.exe %bld%\git.obj kernel32.lib
goto end

:init_env
rem Create starter env.bat
(
echo set lib="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.18362.0\um\x64"
echo set path="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.25.28610\bin\Hostx64\x64";%%path%%
) > env.bat

echo New env.bat was created. Please edit variables in env.bat and run build.bat again.

:end
popd
