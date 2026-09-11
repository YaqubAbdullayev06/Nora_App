$ErrorActionPreference = "Stop"

# Set up VS environment first
$vsBuildDir = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools"
cmd /c "`"$vsBuildDir\VC\Auxiliary\Build\vcvars64.bat`" && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

# Override ALL problematic environment variables
[Environment]::SetEnvironmentVariable("TEMP", "C:\Temp", 'Process')
[Environment]::SetEnvironmentVariable("TMP", "C:\Temp", 'Process')
[Environment]::SetEnvironmentVariable("HOME", "C:\safehome", 'Process')
[Environment]::SetEnvironmentVariable("USERPROFILE", "C:\safehome", 'Process')
[Environment]::SetEnvironmentVariable("HOMEPATH", "\safehome", 'Process')
[Environment]::SetEnvironmentVariable("HOMEDRIVE", "C:", 'Process')

# Clean PATH - remove entries with parentheses
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -and $_ -notmatch '\(' -and $_ -notmatch '\)' }
$env:PATH = ($pathEntries -join ';')

# Also add cmake and flutter back
$env:PATH = "C:\tools\cmake-3.31.6\bin;$env:PATH"

# Verify
Write-Host "=== Env vars ==="
Write-Host "TEMP=$env:TEMP"
Write-Host "TMP=$env:TMP"
Write-Host "HOME=$env:HOME"
Write-Host "USERPROFILE=$env:USERPROFILE"
Write-Host "HOMEPATH=$env:HOMEPATH"
Write-Host "HOMEDRIVE=$env:HOMEDRIVE"
Write-Host "PATH=$env:PATH"

# Configure and build
cd C:\NoraApp
Write-Host "`n=== Running flutter pub get ==="
flutter pub get

Write-Host "`n=== Running flutter build windows ==="
flutter build windows --debug -v 2>&1 | Select-Object -Last 40
