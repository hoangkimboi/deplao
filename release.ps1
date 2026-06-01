param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

Write-Host "=== Deplao Release Script ===" -ForegroundColor Cyan
Write-Host "Version to release: $Version" -ForegroundColor Yellow

# 1. Update version in package.json
Write-Host "`n[1/6] Updating version in package.json..." -ForegroundColor Green
$packagePath = "package.json"
$package = Get-Content $packagePath -Raw | ConvertFrom-Json
$package.version = $Version
$package | ConvertTo-Json -Depth 100 | Set-Content $packagePath -Encoding UTF8

# 2. Commit version change
Write-Host "[2/6] Committing version bump..." -ForegroundColor Green
git add package.json
git commit -m "chore(release): bump version to v$Version" --allow-empty

# 3. Build
Write-Host "[3/6] Building production..." -ForegroundColor Green
npm run production

# 4. Create and push tag
$tag = "v$Version"
Write-Host "[4/6] Creating and pushing tag $tag..." -ForegroundColor Green
git tag $tag
git push myfork $tag

# 5. Create GitHub Release
Write-Host "[5/6] Creating GitHub Release $tag..." -ForegroundColor Green
$releaseNotes = "Release v$Version`n`n- Auto Update improvements`n- Latest changes from custom fork"

gh release create $tag `
    --repo hoangkimboi/deplao `
    --title "Deplao $tag" `
    --notes $releaseNotes `
    "dist-electron-build/Deplao-Setup-$Version.exe" `
    "dist-electron-build/Deplao-Setup-$Version.exe.blockmap" `
    "dist-electron-build/latest.yml"

Write-Host "`n=== RELEASE COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host "Release URL: https://github.com/hoangkimboi/deplao/releases/tag/$tag" -ForegroundColor Cyan
