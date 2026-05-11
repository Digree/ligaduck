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

### Certificato auto-generato (default)

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
