[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [string]$Source = 'https://api.nuget.org/v3/index.json',
    [ValidateSet('Debug','Release')]
    [string]$Configuration = 'Release',
    [switch]$SkipPack
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $repoRoot
try {
    if (-not $SkipPack) {
        dotnet pack Khaos.Logging.sln --configuration $Configuration
    }

    $packageFiles = Get-ChildItem -Path (Join-Path $repoRoot 'artifacts') -Filter '*.nupkg' -File -ErrorAction Stop |
                    Where-Object { $_.Name -notlike '*.symbols.nupkg' }

    foreach ($package in $packageFiles) {
        dotnet nuget push $package.FullName --api-key $ApiKey --source $Source --skip-duplicate
    }

    $symbolPackages = Get-ChildItem -Path (Join-Path $repoRoot 'artifacts') -Filter '*.snupkg' -File -ErrorAction SilentlyContinue
    foreach ($symbols in $symbolPackages) {
        dotnet nuget push $symbols.FullName --api-key $ApiKey --source $Source --skip-duplicate
    }
}
finally {
    Pop-Location
}
