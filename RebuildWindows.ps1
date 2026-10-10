param(
    [switch]$DeleteConfig,
    [switch]$Release
)

$repositoryRoot = $PSScriptRoot
$buildDirectory = Join-Path $repositoryRoot 'build\windows'

try {
    if (Test-Path -LiteralPath $buildDirectory -PathType Container) {
        foreach ($child in Get-ChildItem -LiteralPath $buildDirectory -Force -ErrorAction Stop) {
            if ($child.Name -eq 'third_party' -and $child.PSIsContainer) {
                continue
            }
            
            if ($child.Name -eq 'config.toml' -and -not $DeleteConfig) {
                continue
            }
            
            Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction Stop
        }
    }
} catch {
    Write-Error $_
    exit 1
}

Push-Location $repositoryRoot
try {
    $configureArguments = @()
    if ($Release) {
        $configureArguments += '--release'
    }
    
    python configure.py @configureArguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    ninja windows
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    
    Write-Host ``
    Write-Host "Rebuild completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ``
} catch {
    Write-Error $_
    exit 1
} finally {
    Pop-Location
}