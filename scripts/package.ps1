$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$addon = $repo
$toc = Get-Content -LiteralPath (Join-Path $addon 'SimpleSwing.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version: ([0-9.]+)').Groups[1].Value
if (-not $version) { throw 'Missing addon version' }
$output = Join-Path $repo 'dist'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$zip = Join-Path $output "SimpleSwing-$version.zip"
$stage = Join-Path $output ([guid]::NewGuid().ToString('N'))
$stageAddon = Join-Path $stage 'SimpleSwing'
New-Item -ItemType Directory -Path $stageAddon | Out-Null
try {
    foreach ($entry in @('SimpleSwing.toc', 'SimpleSwing.lua', 'Timer.lua', 'Libs', 'README.txt', 'LICENSE.txt', 'CHANGELOG.md')) {
        Copy-Item -LiteralPath (Join-Path $addon $entry) -Destination $stageAddon -Recurse
    }
    Compress-Archive -LiteralPath $stageAddon -DestinationPath $zip -Force
} finally {
    $resolvedStage = (Resolve-Path -LiteralPath $stage).Path
    if (-not $resolvedStage.StartsWith($output + [IO.Path]::DirectorySeparatorChar)) { throw 'Unsafe staging path' }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
}
Write-Output $zip
