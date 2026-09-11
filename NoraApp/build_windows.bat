@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set PATH=C:\tools\cmake-3.31.6\bin;C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%

cd /d C:\NoraApp
flutter pub get
flutter run -d windows 2>&1
echo --- Exit code: %ERRORLEVEL% ---
