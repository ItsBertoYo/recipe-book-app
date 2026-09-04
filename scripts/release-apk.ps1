param(
    [string]$VersionName,
    [int]$VersionCode,
    [string]$Repo = "ItsBertoYo/recipe-book-app",
    [string]$UpdateRepo = "ItsBertoYo/recipe-book-app-updates",
    [string]$CommitMessage,
    [switch]$SkipCommit
)

$ErrorActionPreference = "Stop"

$project = Resolve-Path "$PSScriptRoot\.."
$statePath = Join-Path $project "release-state.json"
$apkPath = Join-Path $project "dist\Recipe.Book.apk"
$manifestPath = Join-Path $project "app\src\main\AndroidManifest.xml"

function Bump-PatchVersion([string]$CurrentVersion) {
    $parts = $CurrentVersion.Split(".")
    if ($parts.Count -lt 3) {
        throw "Expected versionName like 1.0.0 in $statePath"
    }

    $patch = [int]$parts[$parts.Count - 1]
    $parts[$parts.Count - 1] = ($patch + 1).ToString()
    return ($parts -join ".")
}

Set-Location $project

if (-not $VersionName -or -not $VersionCode) {
    if (Test-Path $statePath) {
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
        if (-not $VersionName) {
            $VersionName = Bump-PatchVersion $state.versionName
        }
        if (-not $VersionCode) {
            $VersionCode = [int]$state.versionCode + 1
        }
    } else {
        if (-not $VersionName) { $VersionName = "1.0.1" }
        if (-not $VersionCode) { $VersionCode = 2 }
    }
}

if (-not $CommitMessage) {
    $CommitMessage = "Release Recipe Book v$VersionName"
}

[xml]$manifest = Get-Content $manifestPath
$manifest.manifest.versionCode = $VersionCode.ToString()
$manifest.manifest.versionName = $VersionName
$manifest.Save($manifestPath)

& "$PSScriptRoot\build-apk.ps1"

if (-not (Test-Path $apkPath)) {
    throw "APK was not created at $apkPath"
}

$newState = [ordered]@{
    versionName = $VersionName
    versionCode = $VersionCode
}
$newState | ConvertTo-Json | Set-Content $statePath

if (-not $SkipCommit) {
    git add -A
    $dirty = git status --short
    if ($dirty) {
        git commit -m $CommitMessage
        git push
    } else {
        Write-Host "No code changes to commit."
    }
}

$tag = "v$VersionName"
$releaseExists = $false
try {
    gh release view $tag --repo $Repo *> $null
    $releaseExists = $true
} catch {
    $releaseExists = $false
}

if ($releaseExists) {
    gh release upload $tag $apkPath --repo $Repo --clobber
} else {
    gh release create $tag $apkPath --repo $Repo --title "Recipe Book $tag" --notes "Android APK release."
}

if ($UpdateRepo) {
    $updateReleaseExists = $false
    try {
        gh release view $tag --repo $UpdateRepo *> $null
        $updateReleaseExists = $true
    } catch {
        $updateReleaseExists = $false
    }

    if ($updateReleaseExists) {
        gh release upload $tag $apkPath --repo $UpdateRepo --clobber
    } else {
        gh release create $tag $apkPath --repo $UpdateRepo --title "Recipe Book $tag" --notes "Public APK update release for Obtainium. Source code remains in the private recipe-book-app repository."
    }
}

Write-Host ""
Write-Host "Done. Private source release:"
Write-Host "https://github.com/$Repo/releases/tag/$tag"
Write-Host ""
Write-Host "Public Obtainium update release:"
Write-Host "https://github.com/$UpdateRepo/releases/tag/$tag"
