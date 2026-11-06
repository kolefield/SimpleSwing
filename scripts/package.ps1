$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$addon = Join-Path $repo 'SimpleSwing'
$toc = Get-Content -LiteralPath (Join-Path $addon 'SimpleSwing.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version: ([0-9.]+)').Groups[1].Value
if (-not $version) { throw 'Missing addon version' }
$output = Join-Path $repo 'dist'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$zip = Join-Path $output "SimpleSwing-$version.zip"
Compress-Archive -LiteralPath $addon -DestinationPath $zip -Force
Write-Output $zip
