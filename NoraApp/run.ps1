$env:PATH = "C:\tools\cmake-3.31.6\bin;C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;$env:PATH"

# Strip any PATH entries containing parentheses (user profile dirs with 'YaqubAbdullayev(Mush')
$pathEntries = $env:PATH -split ';'
$cleanPath = $pathEntries | Where-Object { $_.Trim() -ne '' -and $_ -notmatch 'YaqubAbdullayev' -and $_ -notmatch 'Program Files \(x86\)' -or $_ -match 'Microsoft Visual Studio\\18\\BuildTools' -or $_ -match 'cmake-3\.31' -or $_ -match 'Ninja' -or $_ -match 'flutter' -or $_ -match 'dart' -or $_ -match 'PubCache' -or $_ -match 'jdk' -or $_ -match 'Java' -or $_ -match 'Windows' -or $_ -match 'System32' -or $_ -match 'SysWOW64' -or $_ -match 'WindowsApps' }

# More aggressive: only keep essential paths
$safePaths = @()
foreach ($entry in $pathEntries) {
    $e = $entry.Trim()
    if ($e -eq '' -or $e -eq '.') { continue }
    # Skip any path containing parentheses
    if ($e -match '\(' -or $e -match '\)') { continue }
    $safePaths += $e
}
$env:PATH = $safePaths -join ';'
Write-Host "Clean PATH: $env:PATH"

cd C:\NoraApp
flutter pub get
flutter run -d windows 2>&1
Write-Host "=== EXIT: $LASTEXITCODE ==="
