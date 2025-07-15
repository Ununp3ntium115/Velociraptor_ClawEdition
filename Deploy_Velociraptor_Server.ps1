$ErrorActionPreference = 'Stop'
$installDir  = 'C:\tools'
$dataStore   = 'C:\VelociraptorServerData'
$frontendPort = 8000
$guiPort      = 8889

#─────────────── helpers ───────────────#
function Log ($m) {
    $d = Join-Path $Env:ProgramData VelociraptorDeploy
    if (-not (Test-Path $d)) { New-Item $d -Type Directory -Force | Out-Null }
    "{0}`t{1}" -f (Get-Date -f 'yyyy-MM-dd HH:mm:ss'), $m |
        Out-File (Join-Path $d server_deploy.log) -Append
    Write-Host $m
}
function Ask ($q,$def='n') { ($r = Read-Host "$q [$def]") ; if (!$r) { $def } else { $r } }
function AskSecret ($p)    { (Read-Host $p -AsSecureString) -as [System.Net.NetworkCredential] }

#─────── create folders ───────#
foreach ($p in $installDir,$dataStore) { if (-not (Test-Path $p)) { New-Item $p -Type Directory -Force | Out-Null } }

#─────── download (or reuse) EXE ───────#
$exe = Join-Path $installDir velociraptor.exe
if (-not (Test-Path $exe)) {
    Log 'Fetching latest Windows-AMD64 release …'
    $rel   = Invoke-RestMethod 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' -Headers @{ 'User-Agent'='DeployVelo' }
    $asset = $rel.assets | Where-Object name -like '*windows-amd64.exe' | Select-Object -First 1
    Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing
    Log "Downloaded $($asset.name)"
} else { Log "Using existing $exe" }

#─────── generate baseline server.yaml ──#
$config = Join-Path $installDir server.yaml
& $exe config generate | Set-Content $config
Log 'Base server.yaml generated.'

#─────── interactive DNS ───────#
$publicHost = $env:COMPUTERNAME
if (Ask 'Do you have a public DNS/FQDN for agents?' 'n' -match '^[Yy]') {
    $publicHost = Read-Host 'Enter FQDN (e.g. velo.example.com)'
}
Log "public_hostname  →  $publicHost"

#─────── interactive SSO (optional) ────#
$sso = ''
if (Ask 'Enable Single-Sign-On (OAuth2/OIDC)?' 'n' -match '^[Yy]') {
    switch ((Read-Host 'SSO provider  [google | azure | github | okta | oidc]').ToLower()) {
        'google' {
            $cid = Read-Host 'Google client-ID'
            $sec = AskSecret 'Google client-secret'
$sso = @"
authenticator:
  type: Google
  oauth_client_id: '$cid'
  oauth_client_secret: '$($sec.Password)'
"@ }
        'azure' {
            $cid = Read-Host 'Azure client-ID'
            $sec = AskSecret 'Azure client-secret'
            $ten = Read-Host 'Azure tenant-ID'
$sso = @"
authenticator:
  type: Azure
  oauth_client_id: '$cid'
  oauth_client_secret: '$($sec.Password)'
  tenant: '$ten'
"@ }
        'github' {
            $cid = Read-Host 'GitHub client-ID'
            $sec = AskSecret 'GitHub client-secret'
$sso = @"
authenticator:
  type: GitHub
  oauth_client_id: '$cid'
  oauth_client_secret: '$($sec.Password)'
"@ }
        'okta' {
            $cid = Read-Host 'Okta client-ID'
            $sec = AskSecret 'Okta client-secret'
            $iss = Read-Host 'Okta issuer URL'
$sso = @"
authenticator:
  type: OIDC
  oidc_issuer_url: '$iss'
  client_id: '$cid'
  client_secret: '$($sec.Password)'
  scopes: ['openid','profile','email']
"@ }
        'oidc' {
            $cid = Read-Host 'OIDC client-ID'
            $sec = AskSecret 'OIDC client-secret'
            $iss = Read-Host 'OIDC issuer URL'
$sso = @"
authenticator:
  type: OIDC
  oidc_issuer_url: '$iss'
  client_id: '$cid'
  client_secret: '$($sec.Password)'
"@ }
        default { Log 'Unknown provider – skipping SSO.' }
    }
}

#─────── patch server.yaml ────#
[String[]]$yaml = Get-Content $config
$yaml = $yaml -replace '^public_hostname:.*', "public_hostname: '$publicHost'"

if ($sso) {
    $idx = ($yaml | Select-String '^gui:' | Select-Object -First 1).LineNumber
    if ($idx) {
        $yaml = $yaml[0..$idx] + (($sso -split "`n") | ForEach-Object { '  ' + $_ }) + $yaml[$idx+1..($yaml.Count-1)]
    } else { $yaml += $sso }
}
$yaml | Set-Content $config
Log 'server.yaml patched.'

#─────── firewall rules (netsh fallback) ──#
foreach ($p in $frontendPort,$guiPort) {
    if (-not (Get-NetFirewallRule -DisplayName "Velociraptor $p" -EA 0)) {
        try {
            New-NetFirewallRule -DisplayName "Velociraptor $p" -Direction Inbound -Action Allow `
                                -Protocol TCP -LocalPort $p 2>$null
            Log "Firewall rule added via NetSecurity (TCP $p)."
        } catch {
            netsh advfirewall firewall add rule name="Velociraptor $p" dir=in action=allow protocol=TCP localport=$p | Out-Null
            Log "Firewall rule added via netsh (TCP $p)."
        }
    }
}

#─────── client MSI ─────────#
$msi = Join-Path $installDir "velociraptor_client_${publicHost}.msi"
& $exe package windows msi --msi_out $msi --config $config | Out-Null
Log "Client MSI built → $msi"

#─────── Windows service ───────#
& $exe service install --config $config | Out-Null
Set-Service Velociraptor -StartupType Automatic
Start-Service Velociraptor
Log 'Windows service installed & started.'

Log "==== Deployment complete – browse to https://${publicHost}:${guiPort}"
