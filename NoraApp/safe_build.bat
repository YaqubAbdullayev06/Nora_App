@echo off
set "TEMP=C:\Temp"
set "TMP=C:\Temp"
set "HOME=C:\safehome"
set "USERPROFILE=C:\safehome"
set "HOMEPATH=\safehome"
set "HOMEDRIVE=C:"

call ""C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat""

REM Override again after vcvars sets them
set "TEMP=C:\Temp"
set "TMP=C:\Temp"
set "HOME=C:\safehome"
set "USERPROFILE=C:\safehome"
set "HOMEPATH=\safehome"
set "HOMEDRIVE=C:"

echo === Verifying env ===
echo TEMP=%TEMP%
echo TMP=%TMP%
echo HOME=%HOME%
echo USERPROFILE=%USERPROFILE%
echo HOMEPATH=%HOMEPATH%
echo HOMEDRIVE=%HOMEDRIVE%

cd /d C:\NoraApp
echo.
echo === Running flutter build ===
flutter build windows --debug 2>&1
echo.
echo === Build exit code: %ERRORLEVEL% ===
