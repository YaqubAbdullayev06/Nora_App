@echo off
title NoraApp Builder

:: Set clean environment (fixes unbalanced parentheses in username)
SET PATH=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin;C:\flutter\bin;C:\flutter\bin\cache\dart-sdk\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd
SET USERPROFILE=C:\Users\YaqubAbdullayevMush
SET HOMEDRIVE=C:
SET HOMEPATH=\Users\YaqubAbdullayevMush
SET APPDATA=C:\Users\YaqubAbdullayevMush\AppData\Roaming
SET LOCALAPPDATA=C:\Users\YaqubAbdullayevMush\AppData\Local
SET TEMP=C:\Users\YaqubAbdullayevMush\AppData\Local\Temp
SET TMP=C:\Users\YaqubAbdullayevMush\AppData\Local\Temp

set PROJECT=C:\MyProjects\Project\NoraApp
set RELEASE=%PROJECT%\build\windows\x64\runner\Release
set DATA=%RELEASE%\data

cd /d %PROJECT%

:MENU
echo.
echo ============================
echo  NoraApp Build Menu
echo ============================
echo  1. Windows (Release) - Quick
echo  2. Windows (Release) - Clean
echo  3. Android APK (Release)
echo  4. Android APK (Debug)
echo  5. Run app only
echo  0. Exit
echo ============================
echo.
set /p choice="Select: "

if "%choice%"=="1" goto WIN_RELEASE
if "%choice%"=="2" goto CLEAN_WIN
if "%choice%"=="3" goto ANDROID_RELEASE
if "%choice%"=="4" goto ANDROID_DEBUG
if "%choice%"=="5" goto RUN_APP
if "%choice%"=="0" exit
goto MENU

:WIN_RELEASE
echo.
echo Building Windows Release...
call flutter build windows --release --no-tree-shake-icons 2>&1
echo.

echo Copying files...
if not exist "%DATA%" mkdir "%DATA%"
copy /y "%PROJECT%\windows\flutter\ephemeral\flutter_windows.dll" "%RELEASE%\" >nul
copy /y "%PROJECT%\build\windows\app.so" "%DATA%\app.so" >nul 2>nul
copy /y "%PROJECT%\windows\flutter\ephemeral\app.so" "%DATA%\app.so" >nul 2>nul
copy /y "%PROJECT%\windows\flutter\ephemeral\icudtl.dat" "%DATA%\" >nul 2>nul

if exist "%RELEASE%\nora_app.exe" (
    if exist "%DATA%\app.so" (
        echo.
        echo BUILD OK! Starting app...
        start "" "%RELEASE%\nora_app.exe"
    ) else (
        echo.
        echo BUILD PARTIAL - app.so missing, app may not start
        start "" "%RELEASE%\nora_app.exe"
    )
) else (
    echo BUILD FAILED
)
pause
goto MENU

:CLEAN_WIN
echo.
echo Cleaning build directory...
rd /s /q "%PROJECT%\build" 2>nul
rd /s /q "%PROJECT%\windows\flutter\ephemeral" 2>nul

echo Building Windows Release (clean)...
call flutter build windows --release --no-tree-shake-icons 2>&1
echo.

echo Copying files...
if not exist "%DATA%" mkdir "%DATA%"
copy /y "%PROJECT%\windows\flutter\ephemeral\flutter_windows.dll" "%RELEASE%\" >nul
copy /y "%PROJECT%\build\windows\app.so" "%DATA%\app.so" >nul 2>nul
copy /y "%PROJECT%\windows\flutter\ephemeral\app.so" "%DATA%\app.so" >nul 2>nul
copy /y "%PROJECT%\windows\flutter\ephemeral\icudtl.dat" "%DATA%\" >nul 2>nul

if exist "%DATA%\app.so" (
    echo.
    echo BUILD OK! Starting app...
    start "" "%RELEASE%\nora_app.exe"
) else (
    echo BUILD FAILED - app.so not found
)
pause
goto MENU

:ANDROID_RELEASE
echo.
echo Building Android Release APK (split per ABI + debug info)...
call flutter build apk --release --split-per-abi --split-debug-info=build/app/outputs/symbols
echo.
if exist "%PROJECT%\build\app\outputs\flutter-apk\app-release.apk" (
    echo BUILD OK: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo BUILD FAILED
)
pause
goto MENU

:ANDROID_DEBUG
echo.
echo Building Android Debug APK...
call flutter build apk --debug
echo.
if exist "%PROJECT%\build\app\outputs\flutter-apk\app-debug.apk" (
    echo BUILD OK: build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo BUILD FAILED
)
pause
goto MENU

:RUN_APP
echo.
if exist "%RELEASE%\nora_app.exe" (
    start "" "%RELEASE%\nora_app.exe"
) else (
    echo No built app found. Build first with option 1 or 2.
)
pause
goto MENU
