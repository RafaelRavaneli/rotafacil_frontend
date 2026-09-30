param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$ApiKey,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$AuthDomain,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$ProjectId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$StorageBucket,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$MessagingSenderId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$AppId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$WebVapidKey,
    [string]$ApiBaseUrl = 'http://127.0.0.1:5000'
)
$ErrorActionPreference = 'Stop'
$template = Join-Path $PSScriptRoot 'web/firebase-messaging-sw.js.example'
$target = Join-Path $PSScriptRoot 'web/firebase-messaging-sw.js'
$configPath = Join-Path $PSScriptRoot 'firebase-web.local.json'
if (-not (Test-Path -LiteralPath $template)) { throw 'Modelo do service worker não encontrado.' }
$firebase = [ordered]@{
    apiKey=$ApiKey; authDomain=$AuthDomain; projectId=$ProjectId
    storageBucket=$StorageBucket; messagingSenderId=$MessagingSenderId; appId=$AppId
}
$content = Get-Content -LiteralPath $template -Raw -Encoding UTF8
$configJson = $firebase | ConvertTo-Json -Compress
$pattern = 'firebase\.initializeApp\(\{[\s\S]*?\}\);'
if (-not [regex]::IsMatch($content, $pattern)) { throw 'Modelo Firebase inválido.' }
$content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) 'firebase.initializeApp(' + $configJson + ');' })
$defines = [ordered]@{
    USE_BACKEND='true'; API_BASE_URL=$ApiBaseUrl
    FIREBASE_API_KEY=$ApiKey; FIREBASE_AUTH_DOMAIN=$AuthDomain
    FIREBASE_PROJECT_ID=$ProjectId; FIREBASE_STORAGE_BUCKET=$StorageBucket
    FIREBASE_MESSAGING_SENDER_ID=$MessagingSenderId; FIREBASE_APP_ID=$AppId
    FIREBASE_WEB_VAPID_KEY=$WebVapidKey
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($target, $content, $utf8)
[IO.File]::WriteAllText($configPath, ($defines | ConvertTo-Json), $utf8)
Write-Output 'Configuração Web e service worker gerados no mesmo projeto.'
Write-Output 'Execute: flutter run -d chrome --web-port=8080 --dart-define-from-file=firebase-web.local.json'
