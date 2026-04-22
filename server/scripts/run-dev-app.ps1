$ErrorActionPreference = "Stop"

$SERVER_DIR = (Resolve-Path "$PSScriptRoot\..").Path
$PROFILE = if ($env:SPRING_PROFILES_ACTIVE) { $env:SPRING_PROFILES_ACTIVE } else { "local" }

Set-Location $SERVER_DIR

& ".\mvnw.cmd" -pl skillhub-app -am clean package -DskipTests | Out-Null

$APP_JAR = Get-ChildItem -Path "skillhub-app\target" -Filter "skillhub-app-*.jar" |
    Where-Object { $_.Name -notlike "*.original" -and $_.DirectoryName -eq (Resolve-Path "skillhub-app\target").Path } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $APP_JAR) {
    Write-Error "Could not locate packaged skillhub-app jar under skillhub-app\target"
    exit 1
}

$JAVA_BIN = if ($env:JAVA_BIN) { $env:JAVA_BIN } else { "java" }

& $JAVA_BIN -jar $APP_JAR --spring.profiles.active="$PROFILE" @args