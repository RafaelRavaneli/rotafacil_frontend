param(
    [Parameter(Mandatory=$true)][string]$ApiKey,
    [Parameter(Mandatory=$true)][string]$AuthDomain,
    [Parameter(Mandatory=$true)][string]$ProjectId,
    [Parameter(Mandatory=$true)][string]$StorageBucket,
    [Parameter(Mandatory=$true)][string]$MessagingSenderId,
    [Parameter(Mandatory=$true)][string]$AppId
)

$ErrorActionPreference = "Stop"

$template = ".\web\firebase-messaging-sw.js.example"
$target = ".\web\firebase-messaging-sw.js"

if (-not (Test-Path $template)) {
    throw "Arquivo $template nao encontrado. Execute primeiro flutter create ."
}

$content = Get-Content $template -Raw
$content = $content.Replace("SUA_API_KEY", $ApiKey)
$content = $content.Replace("SEU_AUTH_DOMAIN", $AuthDomain)
$content = $content.Replace("SEU_PROJECT_ID", $ProjectId)
$content = $content.Replace("SEU_STORAGE_BUCKET", $StorageBucket)
$content = $content.Replace("SEU_MESSAGING_SENDER_ID", $MessagingSenderId)
$content = $content.Replace("SEU_APP_ID", $AppId)

Set-Content -Path $target -Value $content -Encoding UTF8

Write-Host "firebase-messaging-sw.js criado com sucesso." -ForegroundColor Green
Write-Host "Agora rode o Flutter passando tambem os dart-defines do Firebase e a VAPID key."
