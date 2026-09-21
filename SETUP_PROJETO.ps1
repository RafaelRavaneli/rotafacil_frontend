$ErrorActionPreference = "Stop"

Write-Host "=== RotaFacil V3 - Setup ===" -ForegroundColor Green

if (-not (Test-Path ".\pubspec.yaml")) {
    throw "Execute este script na pasta que contem o pubspec.yaml."
}

Write-Host "1/4 Criando/atualizando plataformas Flutter..."
flutter create .

$manifest = ".\android\app\src\main\AndroidManifest.xml"

if (Test-Path $manifest) {
    $content = Get-Content $manifest -Raw

    $permissions = @(
        '<uses-permission android:name="android.permission.INTERNET" />',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
        '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
        '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'
    )

    foreach ($permission in $permissions) {
        if (-not $content.Contains($permission)) {
            $content = $content.Replace(
                "<application",
                "$permission`r`n    <application"
            )
        }
    }

    Set-Content -Path $manifest -Value $content -Encoding UTF8
    Write-Host "2/4 Permissoes Android aplicadas." -ForegroundColor Green
}
else {
    Write-Host "2/4 AndroidManifest nao encontrado; etapa ignorada." -ForegroundColor Yellow
}

Write-Host "3/4 Baixando dependencias..."
flutter pub get

Write-Host "4/4 Executando flutter analyze..."
flutter analyze

Write-Host ""
Write-Host "Setup concluido." -ForegroundColor Green
Write-Host "Para abrir no Chrome:"
Write-Host "flutter run -d chrome"
