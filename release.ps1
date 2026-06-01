param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$gh = "C:\Program Files\GitHub CLI\gh.exe"

Write-Host "=== Deplao Release Script v2 ===" -ForegroundColor Cyan
Write-Host "Target Version: $Version" -ForegroundColor Yellow

# Check gh authentication
Write-Host "`n[Check] Verifying GitHub CLI authentication..." -ForegroundColor Green
$authStatus = & $gh auth status 2>&1
if ($authStatus -notmatch "Logged in to github.com") {
    Write-Error "You are not logged in to GitHub CLI. Please run: gh auth login"
    exit 1
}

# Check remote 'myfork'
$remotes = git remote
if ($remotes -notcontains "myfork") {
    Write-Error "Remote 'myfork' not found. Please add it: git remote add myfork https://github.com/hoangkimboi/deplao.git"
    exit 1
}

# 1. Update version in package.json
Write-Host "`n[1/7] Updating version in package.json..." -ForegroundColor Green
$packagePath = "package.json"
$package = Get-Content $packagePath -Raw | ConvertFrom-Json
$package.version = $Version
$package | ConvertTo-Json -Depth 100 | Set-Content $packagePath -Encoding UTF8

# 2. Commit version change
Write-Host "[2/7] Committing version bump..." -ForegroundColor Green
git add package.json
git commit -m "chore(release): bump version to v$Version" --allow-empty

# 3. Build
Write-Host "[3/7] Building production (this may take a few minutes)..." -ForegroundColor Green
npm run production

if (-not (Test-Path "dist-electron-build\Deplao-Setup-$Version.exe")) {
    Write-Error "Build failed! Installer not found."
    exit 1
}

# 4. Create and push tag
$tag = "v$Version"
Write-Host "[4/7] Creating and pushing tag $tag..." -ForegroundColor Green
git tag -f $tag
git push myfork $tag --force

# 5. Generate release notes from recent commits
Write-Host "[5/7] Generating release notes..." -ForegroundColor Green
$recentCommits = git log --oneline -10 --pretty=format:"- %s" | Out-String
$releaseNotes = @"
Release v$Version

## Changes
$recentCommits

---
Auto Update: Enabled
Custom OpenAI Compatible support included
"@

# 6. Create GitHub Release + upload files
Write-Host "[6/7] Creating GitHub Release and uploading files..." -ForegroundColor Green
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
Write-Host "`nNext steps for employees: They need to install this version at least once to enable auto-update." -ForegroundColor Yellow
