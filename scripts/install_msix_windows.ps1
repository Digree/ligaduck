# Script per installare MSIX con certificato auto-firmato
# Uso: .\install_msix_windows.ps1 LigaDuckManager-Windows-v43.1.2.msix

param(
    [Parameter(Mandatory=$true)]
    [string]$MsixPath
)

Write-Host "🔐 LigaDuck Manager - MSIX Installer" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Verifica che il file esista
if (-not (Test-Path $MsixPath)) {
    Write-Host "❌ Errore: File non trovato: $MsixPath" -ForegroundColor Red
    exit 1
}

$fullPath = Resolve-Path $MsixPath
Write-Host "📦 File MSIX: $fullPath" -ForegroundColor Green
Write-Host ""

# Verifica privilegi amministratore
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  ATTENZIONE: Sono richiesti privilegi di amministratore" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Rilancio lo script come amministratore..." -ForegroundColor Yellow
    
    # Rilancia come amministratore
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -MsixPath `"$fullPath`"" -Verb RunAs
    exit
}

Write-Host "✓ Privilegi amministratore confermati" -ForegroundColor Green
Write-Host ""

# Estrai il certificato dall'MSIX
Write-Host "📝 Estrazione certificato dall'MSIX..." -ForegroundColor Cyan

try {
    # Crea cartella temporanea
    $tempDir = Join-Path $env:TEMP "msix_cert_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Estrai MSIX (è uno ZIP)
    Add-Type -Assembly System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($fullPath, $tempDir)
    
    # Trova il file AppxSignature.p7x
    $signatureFile = Join-Path $tempDir "AppxSignature.p7x"
    
    if (-not (Test-Path $signatureFile)) {
        throw "File AppxSignature.p7x non trovato nell'MSIX"
    }
    
    # Estrai il certificato dal file di firma
    $signature = Get-AuthenticodeSignature -FilePath $signatureFile
    $cert = $signature.SignerCertificate
    
    if ($null -eq $cert) {
        throw "Impossibile estrarre il certificato"
    }
    
    Write-Host "✓ Certificato estratto: $($cert.Subject)" -ForegroundColor Green
    Write-Host "  Emesso da: $($cert.Issuer)" -ForegroundColor Gray
    Write-Host "  Valido fino al: $($cert.NotAfter)" -ForegroundColor Gray
    Write-Host ""
    
    # Installa il certificato come Trusted Root
    Write-Host "🔐 Installazione certificato come Trusted Root..." -ForegroundColor Cyan
    
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")
    
    # Verifica se il certificato è già installato
    $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    
    if ($existing) {
        Write-Host "✓ Certificato già installato" -ForegroundColor Green
    } else {
        $store.Add($cert)
        Write-Host "✓ Certificato installato con successo" -ForegroundColor Green
    }
    
    $store.Close()
    
    # Pulisci
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "❌ Errore durante l'estrazione del certificato: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  Provo comunque l'installazione dell'MSIX..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📦 Installazione MSIX..." -ForegroundColor Cyan

try {
    Add-AppxPackage -Path $fullPath -ErrorAction Stop
    
    Write-Host ""
    Write-Host "✅ LigaDuck Manager installato con successo!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Puoi trovare l'app nel menu Start di Windows" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ Errore durante l'installazione: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 Possibili soluzioni:" -ForegroundColor Yellow
    Write-Host "  1. Assicurati di eseguire PowerShell come Amministratore" -ForegroundColor Gray
    Write-Host "  2. Abilita Developer Mode o Sideloading:" -ForegroundColor Gray
    Write-Host "     Impostazioni → Aggiornamento e sicurezza → Per sviluppatori" -ForegroundColor Gray
    Write-Host "  3. Disinstalla eventuali versioni precedenti" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "Premi un tasto per chiudere..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
