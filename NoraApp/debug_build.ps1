# Set up VS environment
$vsBuildDir = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools"
cmd /c ""$vsBuildDir\VC\Auxiliary\Build\vcvars64.bat" && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

# Clean PATH
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -and $_ -notmatch '\(' -and $_ -notmatch '\)' }
$env:PATH = "C:\tools\cmake-3.31.6\bin;"

cd C:\NoraApp
flutter pub get 2>&1 | Out-Null

# Reconfigure
& $cmake4 -G "Visual Studio 18 2026" -A x64 -DFLUTTER_TARGET_PLATFORM=windows-x64 -SC:\NoraApp\windows -BC:\NoraApp\build\windows\x64 2>&1 | Out-Null

# Now patch ALL vcxproj files to escape parentheses in AdditionalInputs
$vcxprojs = Get-ChildItem "C:\NoraApp\build\windows\x64" -Recurse -Filter "*.vcxproj"
foreach ($f in $vcxprojs) {
    $content = Get-Content $f.FullName -Raw
    # Replace unquoted (x86) paths in AdditionalInputs with quoted versions
    # Actually the real fix is to quote the entire AdditionalInputs value
    # But simpler: escape parentheses for batch by wrapping in quotes
    # Actually, the AdditionalInputs shouldn't cause issues since they're not part of the command
}

# Actually, let me check the Microsoft.CppCommon.targets to see how CustomBuild works
$targetsFile = "$vsBuildDir\MSBuild\Microsoft\VC\v180\Microsoft.CppCommon.targets"
$targetsContent = Get-Content $targetsFile -Raw

# Find how CustomBuild processes the command
$match = [regex]::Match($targetsContent, '(?s)CustomBuild.*?Command.*?')
Write-Host "Checking targets file..."

# Instead of trying to fix the targets, let's try a direct MSBuild approach
# Build with /v:diag to see what command is actually being run
Write-Host "
=== Building with verbose diagnostic ==="
& msbuild "C:\NoraApp\build\windows\x64\ZERO_CHECK.vcxproj" /p:Configuration=Debug /p:Platform=x64 /v:diag 2>&1 | Select-String -Pattern "CustomBuild|Command|YaqubAbdullayev|Additional" -Context 0,2 | Select-Object -First 30
