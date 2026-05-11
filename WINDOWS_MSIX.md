# 📦 Build Windows MSIX

Guida completa per creare pacchetti MSIX di LigaDuck Manager per Windows 10/11.

## 🎯 Cos'è MSIX?

MSIX è il formato moderno di packaging per applicazioni Windows che offre:
- ✅ **Singolo file installer** - Niente più cartelle con DLL sparse
- ✅ **Installazione pulita** - App installata nel menu Start di Windows
- ✅ **Disinstallazione completa** - Nessun residuo nel sistema
- ✅ **Aggiornamenti automatici** - Supporto nativo per update
- ✅ **Microsoft Store ready** - Pronto per pubblicazione sullo Store
- ✅ **Firma digitale integrata** - Gli utenti vedono il publisher verificato

## ⚠️ IMPORTANTE - Certificato e Installazione Automatica

### 🔒 Problema con certificati auto-generati

**NON È POSSIBILE** avere un'installazione completamente automatica (doppio click senza warning) con certificati auto-generati. Windows blocca per sicurezza app non firmate da autorità riconosciute.

### ✅ Soluzioni per installazione automatica:

#### Opzione 1: Certificato Code-Signing Commerciale (CONSIGLIATO)
- Costo: €200-400/anno
- Installazione con doppio click, zero warning
- Publisher verificato visibile agli utenti
- Fornitori: DigiCert, Sectigo, GlobalSign

#### Opzione 2: Microsoft Store
- Distribuzione tramite Store ufficiale
- Microsoft firma automaticamente
- Costo: €14/anno (account developer)

#### Opzione 3: Certificato auto-generato + Script helper (ATTUALE)
- Gratuito ma richiede step extra dall'utente
- Utenti devono eseguire script PowerShell per installare certificato
- Mostra warning "Publisher sconosciuto"

**Per distribuzione pubblica professionale, si consiglia Opzione 1 o 2.**

## 🚀 Quick Start

### 1. Prima configurazione (una tantum)

```bash
# Installa la dipendenza msix
flutter pub get
```

### 2. Crea il pacchetto MSIX

```bash
# Su Windows (bash/PowerShell/WSL)
./scripts/build_windows_msix.sh 43.01.00

# Oppure con batch
.\scripts\build_windows_msix.bat 43.01.00
```

### 3. Output

Il file MSIX sarà creato in:
```
artifacts/LigaDuckManager-Windows-v43.01.00.msix
```

### 4. Installazione per test

Doppio click sul file `.msix` oppure:
```powershell
Add-AppxPackage -Path "artifacts\LigaDuckManager-Windows-v43.01.00.msix"
```

## ⚠️ Installazione con Certificato Auto-generato

Il pacchetto MSIX viene creato con un certificato di test auto-generato. Per installarlo:

### METODO 1: Script automatico (CONSIGLIATO) ✅

L'artifact scaricato da GitHub Actions include uno script PowerShell che installa automaticamente il certificato e l'app:

1. Scarica e estrai l'artifact MSIX da GitHub Actions
2. Clicca destro su **`install_msix_windows.ps1`**
3. Seleziona **"Esegui con PowerShell"**
4. Conferma i privilegi di amministratore quando richiesto

Lo script:
- ✅ Estrae automaticamente il certificato dall'MSIX
- ✅ Lo installa come Trusted Root Certificate
- ✅ Installa l'applicazione
- ✅ Gestisce errori comuni

### METODO 2: Installazione manuale certificato

**Passo 1 - Installa il certificato:**

1. Clicca destro sul file `.msix`
2. Seleziona **"Proprietà"**
3. Vai alla scheda **"Firme digitali"**
4. Seleziona il certificato → **Dettagli** → **Visualizza certificato**
5. Clicca **"Installa certificato"**
6. Seleziona **"Computer locale"** (richiede privilegi amministratore)
7. Scegli **"Posiziona tutti i certificati nel seguente archivio"**
8. Clicca **"Sfoglia"** → Seleziona **"Autorità di certificazione radice attendibili"**
9. Completa la procedura guidata

**Passo 2 - Installa l'app:**

Ora puoi fare doppio click sul file `.msix` per installarlo.

### METODO 3: PowerShell (per utenti avanzati)

```powershell
# Esegui PowerShell come Amministratore

# Estrai e installa il certificato
$msixPath = "artifacts\LigaDuckManager-Windows-v43.1.2.msix"
$cert = (Get-AuthenticodeSignature $msixPath).SignerCertificate
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()

# Installa l'app
Add-AppxPackage -Path $msixPath
```

### Errore 0x800B010A

Se ricevi l'errore **"publisher certificate could not be verified (0x800B010A)"**, significa che il certificato non è ancora installato come attendibile. Segui uno dei metodi sopra per installare il certificato.

### Abilitare Developer Mode (se necessario)

Se continui ad avere problemi, abilita "Developer Mode" o "Sideloading" su Windows:

1. **Impostazioni Windows**
2. **Aggiornamento e sicurezza** → **Per sviluppatori**
3. Seleziona **"Modalità sviluppatore"** oppure **"App sideload"**

Questo è necessario solo se Windows blocca l'installazione di app da fonti esterne al Microsoft Store.

## ⚙️ Configurazione

La configurazione MSIX si trova in `pubspec.yaml`:

```yaml
msix_config:
  display_name: LigaDuck Manager              # Nome mostrato nel menu Start
  publisher_display_name: LigaDuck            # Nome publisher
  identity_name: com.ligaduck.manager         # ID unico app
  msix_version: 43.1.2.0                      # Versione in formato x.y.z.0 (NO zeri iniziali!)
  logo_path: assets/icon/icon.png             # Icona applicazione
  capabilities: internetClient                # Permessi (accesso internet)
  languages: it-IT, en-US                     # Lingue supportate
  install_certificate: false                  # Non installare certificato automaticamente (per CI/CD)
```

**⚠️ IMPORTANTE - Formato versione MSIX:**
- Ogni numero deve essere tra 0-65535
- **NON usare zeri iniziali** (es: `43.01.02.0` è INVALIDO, usa `43.1.2.0`)
- Gli script convertono automaticamente `43.01.00` → `43.1.0.0`

**📝 NOTA - Certificato di test:**
- Per default, `install_certificate: false` previene prompt interattivi durante il build
- Il pacchetto MSIX sarà creato con un certificato di test auto-generato
- **Per installarlo localmente**: clicca destro sul file .msix → Proprietà → Firme digitali → Installa certificato
- **Per distribuzione pubblica**: vedi sezione "Firma Digitale" sotto

### Parametri opzionali aggiuntivi

```yaml
msix_config:
  # ... parametri base ...
  
  # Firma digitale (per distribuzione pubblica)
  certificate_path: cert.pfx
  certificate_password: your_password
  
  # Personalizzazione UI installer
  install_certificate: true
  architecture: x64
  
  # Microsoft Store (se pubblichi sullo Store)
  store: true
  publisher: CN=YourPublisherID
```

## 🔐 Firma Digitale (Opzionale ma Consigliata)

Per distribuzione pubblica, dovresti firmare digitalmente il pacchetto MSIX.

### ✅ OPZIONE CONSIGLIATA: Certificato Commerciale

Questa è l'**unica soluzione** per installazione automatica senza warning.

**Passo 1 - Acquista certificato code-signing:**

Scegli un fornitore:
- **DigiCert**: https://www.digicert.com/code-signing (~€300-400/anno)
  - Più affidabile, riconosciuto istantaneamente da Windows
  - Processo di verifica aziendale rigoroso
  
- **Sectigo (ex Comodo)**: https://sectigo.com/ssl-certificates-tls/code-signing (~€200-300/anno)
  - Alternativa economica ma ugualmente valida
  
- **GlobalSign**: https://www.globalsign.com/en/code-signing-certificate (~€250-400/anno)

**Cosa ti serve per acquistare:**
- Partita IVA o Codice Fiscale
- Documento identità
- Verifica email e telefono
- Verifica DUNS (per certificati EV - Extended Validation)

**Passo 2 - Ricevi certificato (.pfx file):**

Il fornitore ti darà:
- File `.pfx` o `.p12` (certificato + chiave privata)
- Password per il certificato
- Informazioni del publisher (CN, O, L, S, C)

**Passo 3 - Configura in pubspec.yaml:**

```yaml
msix_config:
  display_name: LigaDuck Manager
  publisher_display_name: LigaDuck
  identity_name: com.ligaduck.manager
  msix_version: 43.1.2.0
  logo_path: assets/icon/icon.png
  capabilities: internetClient
  languages: it-IT, en-US
  
  # AGGIUNGI QUESTE RIGHE:
  certificate_path: path/to/your-cert.pfx
  certificate_password: your-password-here
  publisher: CN=Your Company Name, O=Your Organization, L=Rome, S=Lazio, C=IT
  install_certificate: false
```

**Passo 4 - Configura GitHub Actions Secrets:**

Per usare il certificato in CI/CD senza esporlo pubblicamente:

1. **Converti certificato in Base64:**
   ```bash
   # Su Mac/Linux:
   base64 your-cert.pfx > cert-base64.txt
   
   # Su Windows PowerShell:
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("your-cert.pfx")) > cert-base64.txt
   ```

2. **Aggiungi secrets su GitHub:**
   - Vai su: Repository → Settings → Secrets and variables → Actions
   - Clicca "New repository secret"
   - Aggiungi:
     - Nome: `WINDOWS_CERT_BASE64`
     - Valore: (contenuto di cert-base64.txt)
   - Aggiungi:
     - Nome: `WINDOWS_CERT_PASSWORD`
     - Valore: (password del certificato)
   - Aggiungi:
     - Nome: `WINDOWS_PUBLISHER`
     - Valore: `CN=Your Company, O=Your Org, L=City, S=State, C=IT`

3. **Aggiorna workflow GitHub Actions:**

Modifica `.github/workflows/build_windows_msix.yml` e `.github/workflows/build_and_release.yml`:

```yaml
- name: Setup certificate
  if: ${{ env.WINDOWS_CERT_BASE64 != '' }}
  env:
    WINDOWS_CERT_BASE64: ${{ secrets.WINDOWS_CERT_BASE64 }}
  run: |
    $certBytes = [Convert]::FromBase64String($env:WINDOWS_CERT_BASE64)
    $certPath = Join-Path $env:TEMP "cert.pfx"
    [IO.File]::WriteAllBytes($certPath, $certBytes)
    echo "CERT_PATH=$certPath" >> $env:GITHUB_ENV

- name: Update MSIX configuration with certificate
  if: ${{ env.CERT_PATH != '' }}
  env:
    CERT_PASSWORD: ${{ secrets.WINDOWS_CERT_PASSWORD }}
    PUBLISHER: ${{ secrets.WINDOWS_PUBLISHER }}
  run: |
    $content = Get-Content pubspec.yaml -Raw
    $content = $content -replace 'install_certificate:.*', "install_certificate: false`n  certificate_path: $env:CERT_PATH`n  certificate_password: $env:CERT_PASSWORD`n  publisher: $env:PUBLISHER"
    $content | Set-Content pubspec.yaml -NoNewline

# Poi il normale build MSIX...
```

**Risultato finale:**
- ✅ Doppio click sul .msix per installare (ZERO warning!)
- ✅ "Verified publisher: Your Company Name"
- ✅ Certificato già trusted da Windows
- ✅ Esperienza utente professionale

**Costo totale:** €200-400/anno

**ROI:** Se distribuisci a 100+ utenti, il costo è ampiamente giustificato dal risparmio di supporto e dall'immagine professionale.

---

### ⚠️ OPZIONE FALLBACK: Certificato Auto-generato (ATTUALE)

Di default, il pacchetto MSIX viene creato con un certificato di test auto-generato da `msix`.

**Per installare il pacchetto con certificato auto-generato:**

1. **Metodo 1 - Installazione certificato manuale:**
   - Clicca destro sul file `.msix`
   - Proprietà → Firme digitali
   - Seleziona il certificato → Dettagli → Visualizza certificato
   - Installa certificato → Computer locale
   - Posiziona tutti i certificati nel seguente archivio → Sfoglia → Autorità di certificazione radice attendibili
   - Completa la procedura
   - Ora puoi installare l'MSIX con doppio click

2. **Metodo 2 - PowerShell (più veloce):**
   ```powershell
   # Estrai e installa il certificato automaticamente
   $msixPath = "artifacts\LigaDuckManager-Windows-v43.1.2.msix"
   Add-AppxPackage -Path $msixPath -DeferRegistrationWhenPackagesAreInUse
   ```

**⚠️ Nota:** Il certificato auto-generato è OK per test interni, ma per distribuzione pubblica gli utenti vedranno un warning "Publisher sconosciuto".

### Opzione 1: Certificato self-signed permanente (per test team)

```powershell
# Crea certificato di test
New-SelfSignedCertificate -Type Custom -Subject "CN=LigaDuck" -KeyUsage DigitalSignature -FriendlyName "LigaDuck Test Certificate" -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

# Esporta certificato
$pwd = ConvertTo-SecureString -String "password123" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\<THUMBPRINT>" -FilePath cert.pfx -Password $pwd
```

Poi aggiungi in `pubspec.yaml`:
```yaml
msix_config:
  # ... altri parametri ...
  certificate_path: cert.pfx
  certificate_password: password123
  install_certificate: false  # Ancora false per CI/CD
```

### Opzione 2: Certificato commerciale (per distribuzione pubblica)

Acquista un certificato code-signing da:
- DigiCert
- Sectigo (ex Comodo)
- GlobalSign

Costo: ~$200-500/anno

### Opzione 3: Microsoft Store (firma automatica)

Se pubblichi su Microsoft Store, Microsoft firma automaticamente l'app.

## 📋 Checklist pre-distribuzione

Prima di distribuire pubblicamente:

- [ ] Testa l'installer su Windows 10 e 11 puliti
- [ ] Verifica che l'app si avvii correttamente dopo installazione
- [ ] Controlla che l'icona appaia correttamente nel menu Start
- [ ] Testa la disinstallazione completa
- [ ] Verifica le capabilities (permessi) necessarie
- [ ] Firma digitalmente per evitare warning "Publisher sconosciuto"
- [ ] Documenta i requisiti di sistema minimi

## 🐛 Troubleshooting

### Errore: "Package could not be registered"

**Soluzione**: Disinstalla la versione precedente
```powershell
Get-AppxPackage *ligaduck* | Remove-AppxPackage
```

### Errore: "Publisher name does not match certificate"

**Soluzione**: Assicurati che il campo `publisher` in `msix_config` corrisponda al CN del certificato.

### Icona non appare correttamente

**Soluzione**: L'icona deve essere PNG o ICO. Verifica che `logo_path` punti a un file valido.

### L'app non si avvia

**Soluzione**: Verifica i log in:
```
%LOCALAPPDATA%\Packages\com.ligaduck.manager_*\LocalState\
```

## 🔄 Workflow Build Completo

Per un rilascio completo con ZIP tradizionale + MSIX:

```bash
# 1. Crea versione ZIP portable (per utenti avanzati)
.\scripts\build_windows.bat 43.01.00

# 2. Crea pacchetto MSIX (per utenti normali)
.\scripts\build_windows_msix.bat 43.01.00

# Output:
# - build/ligaduck-v43.01.00-windows.zip (portable)
# - artifacts/LigaDuckManager-Windows-v43.01.00.msix (installer)
```

## 📚 Risorse

- [Documentazione MSIX ufficiale Microsoft](https://docs.microsoft.com/en-us/windows/msix/)
- [flutter_msix package](https://pub.dev/packages/msix)
- [Code Signing su Windows](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Microsoft Store Partner Center](https://partner.microsoft.com/dashboard)

## 🎯 Prossimi Passi

1. **Test locale**: Installa e testa il pacchetto MSIX su varie macchine Windows
2. **Firma digitale**: Acquista un certificato code-signing per distribuzione pubblica
3. **Microsoft Store**: (Opzionale) Pubblica su Microsoft Store per massima distribuzione
4. **Auto-update**: Implementa aggiornamenti automatici con servizio update

---

**Nota**: Il formato MSIX è supportato solo su Windows 10 (versione 1809+) e Windows 11. Per Windows 7/8, usa il formato ZIP tradizionale.
