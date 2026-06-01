param(
    [Parameter(Position=0)]
    [string]$Version,

    [switch]$Patch,
    [switch]$Minor,
    [switch]$Major
)

$ErrorActionPreference = "Stop"
$gh = "C:\Program Files\GitHub CLI\gh.exe"

function Get-CurrentVersion {
    $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
    return $pkg.version
}

function Bump-Version {
    param([string]$current, [string]$type)
    $parts = $current.Split('.')
    if ($parts.Count -ne 3) { throw "Invalid version format: $current" }

    switch ($type) {
        'major' { $parts[0] = [int]$parts[0] + 1; $parts[1] = 0; $parts[2] = 0 }
        'minor' { $parts[1] = [int]$parts[1] + 1; $parts[2] = 0 }
        'patch' { $parts[2] = [int]$parts[2] + 1 }
    }
    return ($parts -join '.')
}

# Determine target version
if ($Patch -or $Minor -or $Major) {
    $current = Get-CurrentVersion
    if ($Patch) { $Version = Bump-Version $current 'patch' }
    elseif ($Minor) { $Version = Bump-Version $current 'minor' }
    elseif ($Major) { $Version = Bump-Version $current 'major' }
    Write-Host "Current version: $current → New version: $Version" -ForegroundColor Yellow
}
elseif (-not $Version) {
    Write-Error "Please provide a version (e.g. 26.4.5) or use -Patch / -Minor / -Major"
    exit 1
}

Write-Host "=== Deplao Release Script ===" -ForegroundColor Cyan
Write-Host "Target Version: $Version" -ForegroundColor Yellow

# Pre-checks
Write-Host "`n[Check] Verifying environment..." -ForegroundColor Green
$authStatus = & $gh auth status 2>&1
if ($authStatus -notmatch "Logged in to github.com") {
    Write-Error "You are not logged in to GitHub CLI. Run: gh auth login"
    exit 1
}

$remotes = git remote
if ($remotes -notcontains "myfork") {
    Write-Error "Remote 'myfork' not found. Please add it first."
    exit 1
}

# 1. Update package.json
Write-Host "`n[1/7] Updating version in package.json..." -ForegroundColor Green
$package = Get-Content "package.json" -Raw | ConvertFrom-Json
$package.version = $Version
$package | ConvertTo-Json -Depth 100 | Set-Content "package.json" -Encoding UTF8

# 2. Commit version
Write-Host "[2/7] Committing version bump..." -ForegroundColor Green
git add package.json
git commit -m "chore(release): bump version to v$Version" --allow-empty

# 3. Build
Write-Host "[3/7] Building production..." -ForegroundColor Green
npm run production

if (-not (Test-Path "dist-electron-build\Deplao-Setup-$Version.exe")) {
    Write-Error "Build failed! File not found."
    exit 1
}

# 4. Tag & Push
$tag = "v$Version"
Write-Host "[4/7] Creating and pushing tag $tag..." -ForegroundColor Green
git tag -f $tag
git push myfork $tag --force

# 5. Release Notes
Write-Host "[5/7] Generating release notes..." -ForegroundColor Green
$recentCommits = git log --oneline -8 --pretty=format:"- %s" | Out-String
$releaseNotes = @"
Release v$Version

## Recent Changes
$recentCommits

---
- Auto Update enabled
- Custom OpenAI Compatible AI support
"@

# 6. Create GitHub Release
Write-Host "[6/7] Creating GitHub Release..." -ForegroundColor Green
& $gh release create $tag `
    --repo hoangkimboi/deplao `
    --title "Deplao $tag" `
    --notes $releaseNotes `
    "dist-electron-build/Deplao-Setup-$Version.exe" `
    "dist-electron-build/Deplao-Setup-$Version.exe.blockmap" `
    "dist-electron-build/latest.yml"

# 7. Done
Write-Host "`n=== RELEASE v$Version COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host "Release URL: https://github.com/hoangkimboi/deplao/releases/tag/$tag" -ForegroundColor Cyan
Write-Host "`nEmployees must install this version at least once to receive future auto-updates." -ForegroundColor Yellow
