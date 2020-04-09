@echo off

if not "%1"=="" goto %1

:setup
if not exist setup_env.bat (
    echo "setup_env.bat" is missing. Use "setup.bat init" to generate starter file.
    goto end
)

call setup_env.bat

if exist lib rmdir /s /q lib
mkdir lib
mklink lib\kernel32.lib %sdklibdir%\kernel32.lib

if exist tools rmdir /s /q tools
mkdir tools
mklink /D tools\vc %msvcdir%
mklink tools\nasm.exe %nasm%

goto end

:init

(
echo set sdklibdir="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.18362.0\um\x64"
echo set msvcdir="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.25.28610\bin\Hostx64\x64"
echo set nasm="C:\Users\vahur\Tools\nasm.exe"
) > setup_env.bat

:end
