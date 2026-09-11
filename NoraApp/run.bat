@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set PATH=C:\tools\cmake-3.31.6\bin;C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%

REM Clean PATH of entries with parentheses
for /f "tokens=*" %%i in ('echo.%PATH%') do set "CLEANPATH=%%i"

cd /d C:\NoraApp
flutter pub get

REM Step 1: Use CMake 3.x to configure with Ninja (avoids VS generator issues)
echo.
echo === Configuring with CMake 3.31.6 + Ninja ===
"C:\tools\cmake-3.31.6\bin\cmake.exe" -G "Ninja" -DCMAKE_MAKE_PROGRAM="C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" -DCMAKE_BUILD_TYPE=Debug -DFLUTTER_TARGET_PLATFORM=windows-x64 -S "C:\NoraApp\windows" -B "C:\NoraApp\build\windows-ninja"
echo === CMake configure exit: %ERRORLEVEL% ===

REM Step 2: Build with CMake 3.x + Ninja
echo.
echo === Building ===
"C:\tools\cmake-3.31.6\bin\cmake.exe" --build "C:\NoraApp\build\windows-ninja" --config Debug
echo === Build exit: %ERRORLEVEL% ===
