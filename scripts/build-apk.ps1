$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $project 'build'
$build = Join-Path $buildRoot ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$main = Join-Path $project 'app\src\main'
$sourceHtml = Join-Path $project 'cookbook\Recipe Book.html'
$assetHtml = Join-Path $main 'assets\Recipe Book.html'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { 'C:\Users\Berto\AppData\Local\Android\Sdk' }
$javaHome = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin' } else { 'C:\Program Files\Android\Android Studio\jbr\bin' }
$buildToolsDir = Get-ChildItem -LiteralPath (Join-Path $sdk 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
$platformDir = Join-Path $sdk 'platforms\android-35'
$androidJar = Join-Path $platformDir 'android.jar'
$javac = Join-Path $javaHome 'javac.exe'
$jar = Join-Path $javaHome 'jar.exe'
$keytool = Join-Path $javaHome 'keytool.exe'

if (-not $buildToolsDir) { throw 'Android build-tools were not found.' }
if (-not (Test-Path -LiteralPath $androidJar)) { throw "Android platform jar was not found: $androidJar" }
if (-not (Test-Path -LiteralPath $sourceHtml)) { throw "Cookbook HTML was not found: $sourceHtml" }

New-Item -ItemType Directory -Force -Path $buildRoot, "$build\gen", "$build\classes", "$build\dex", (Split-Path -Parent $assetHtml), (Join-Path $project 'dist') | Out-Null
Copy-Item -LiteralPath $sourceHtml -Destination $assetHtml -Force

& "$($buildToolsDir.FullName)\aapt2.exe" compile --dir "$main\res" -o "$build\compiled.zip"
if ($LASTEXITCODE -ne 0) { throw 'Resource compile failed.' }
& "$($buildToolsDir.FullName)\aapt2.exe" link -o "$build\linked.apk" -I $androidJar --manifest "$main\AndroidManifest.xml" "$build\compiled.zip" --java "$build\gen" --auto-add-overlay
if ($LASTEXITCODE -ne 0) { throw 'Resource link failed.' }

$javaFiles = @(Get-ChildItem -LiteralPath "$main\java" -Filter '*.java' -Recurse | ForEach-Object { $_.FullName })
$javaFiles += @(Get-ChildItem -LiteralPath "$build\gen" -Filter '*.java' -Recurse | ForEach-Object { $_.FullName })
& $javac -encoding UTF-8 -source 8 -target 8 -bootclasspath $androidJar -d "$build\classes" $javaFiles
if ($LASTEXITCODE -ne 0) { throw 'Java compile failed.' }

Push-Location "$build\classes"
& $jar cf "$build\classes.jar" .
Pop-Location
if ($LASTEXITCODE -ne 0) { throw 'Class packaging failed.' }
& "$($buildToolsDir.FullName)\d8.bat" --lib $androidJar --output "$build\dex" "$build\classes.jar"
if ($LASTEXITCODE -ne 0) { throw 'Dex build failed.' }

Copy-Item -LiteralPath "$build\linked.apk" -Destination "$build\unaligned.apk" -Force
Push-Location "$build\dex"
& $jar uf "$build\unaligned.apk" classes.dex
Pop-Location
if ($LASTEXITCODE -ne 0) { throw 'Adding classes.dex failed.' }
Push-Location $main
& $jar uf "$build\unaligned.apk" assets
Pop-Location
if ($LASTEXITCODE -ne 0) { throw 'Adding assets failed.' }

& "$($buildToolsDir.FullName)\zipalign.exe" -f -p 4 "$build\unaligned.apk" "$build\RecipeBook-unsigned-aligned.apk"
if ($LASTEXITCODE -ne 0) { throw 'Zipalign failed.' }

$keystore = Join-Path $project 'recipebook-debug.keystore'
if (-not (Test-Path -LiteralPath $keystore)) {
    & $keytool -genkeypair -v -keystore $keystore -storepass android -alias recipebook -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Berto Recipe Book, OU=Personal, O=Berto, L=Local, S=IL, C=US'
}

$outputApk = Join-Path $project 'dist\Recipe Book.apk'
& "$($buildToolsDir.FullName)\apksigner.bat" sign --ks $keystore --ks-pass pass:android --key-pass pass:android --out $outputApk "$build\RecipeBook-unsigned-aligned.apk"
if ($LASTEXITCODE -ne 0) { throw 'APK signing failed.' }
& "$($buildToolsDir.FullName)\apksigner.bat" verify --verbose --print-certs $outputApk
if ($LASTEXITCODE -ne 0) { throw 'APK verification failed.' }

Get-Item -LiteralPath $outputApk | Select-Object FullName,Length,LastWriteTime
