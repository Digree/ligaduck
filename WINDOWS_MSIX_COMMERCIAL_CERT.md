# Configurazione Certificato Commerciale per MSIX

Questa guida ti aiuta a configurare un certificato code-signing commerciale per firmare i pacchetti MSIX.

## 🎯 Perché serve un certificato commerciale?

**Senza certificato commerciale:**
- ❌ Utenti vedono warning "Publisher sconosciuto"
- ❌ Devono eseguire script extra per installare
- ❌ Possibili blocchi da antivirus
- ❌ Aspetto non professionale

**Con certificato commerciale:**
- ✅ Installazione con doppio click, zero warning
- ✅ "Verified publisher: TUO NOME AZIENDA"
- ✅ Massima fiducia utenti
- ✅ Aspetto professionale

## 💰 Costo

€200-400 all'anno (una tantum, valido per 1-3 anni)

## 📋 Passo 1: Acquista certificato

### Fornitori consigliati:

1. **DigiCert** (più affidabile)
   - https://www.digicert.com/code-signing
   - ~€300-400/anno
   - Riconoscimento istantaneo da Windows
   - Processo verifica: 3-5 giorni

2. **Sectigo (ex Comodo)** (economico)
   - https://sectigo.com/ssl-certificates-tls/code-signing
   - ~€200-300/anno
   - Alternativa valida
   - Processo verifica: 2-4 giorni

3. **GlobalSign**
   - https://www.globalsign.com/en/code-signing-certificate
   - ~€250-400/anno

### Documenti necessari:

- Partita IVA o Codice Fiscale
- Documento identità valido
- Indirizzo email aziendale verificabile
- Numero telefono aziendale
- (Opzionale) Numero DUNS per certificati EV

### Tipo di certificato:

- **Standard Code Signing**: Sufficiente per la maggior parte dei casi
- **EV Code Signing**: Massima fiducia, richiede USB token fisico (più costoso)

**Consiglio:** Inizia con Standard Code Signing

## 🔧 Passo 2: Configura localmente

Una volta ricevuto il certificato (.pfx file):

### 2.1 Salva il certificato

```bash
# Crea cartella privata (NON committare su Git!)
mkdir -p ~/certificates
cp your-certificate.pfx ~/certificates/ligaduck-codesign.pfx
chmod 600 ~/certificates/ligaduck-codesign.pfx
```

### 2.2 Aggiorna pubspec.yaml

```yaml
msix_config:
  display_name: LigaDuck Manager
  publisher_display_name: LigaDuck
  identity_name: com.ligaduck.manager
  msix_version: 43.1.2.0
  logo_path: assets/icon/icon.png
  capabilities: internetClient
  languages: it-IT, en-US
  
  # CERTIFICATO COMMERCIALE:
  certificate_path: C:/path/to/ligaduck-codesign.pfx  # Windows
  # certificate_path: /home/user/certificates/ligaduck-codesign.pfx  # Linux
  certificate_password: YourSecurePassword123!
  publisher: CN=LigaDuck Srl, O=LigaDuck, L=Rome, S=Lazio, C=IT
  install_certificate: false
```

**⚠️ IMPORTANTE:** 
- Sostituisci il `publisher` con i dati esatti del tuo certificato
- NON committare la password nel repository!
- Usa variabili ambiente: `certificate_password: ${CERT_PASSWORD}`

### 2.3 Aggiungi al .gitignore

```bash
echo "# Certificati privati" >> .gitignore
echo "*.pfx" >> .gitignore
echo "*.p12" >> .gitignore
echo "cert*.txt" >> .gitignore
```

### 2.4 Build locale

```bash
# Imposta password come variabile ambiente
export CERT_PASSWORD="YourSecurePassword123!"

# Build MSIX firmato
./scripts/build_windows_msix.sh 43.01.00
```

## 🤖 Passo 3: Configura GitHub Actions

### 3.1 Converti certificato in Base64

```bash
# Su Mac/Linux:
base64 -i ligaduck-codesign.pfx > cert-base64.txt

# Su Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ligaduck-codesign.pfx")) | Out-File cert-base64.txt
```

### 3.2 Aggiungi GitHub Secrets

1. Vai su GitHub: **Repository → Settings → Secrets and variables → Actions**

2. Clicca **"New repository secret"** per ciascuno:

   **Secret 1:**
   - Name: `WINDOWS_CERT_BASE64`
   - Value: (copia tutto il contenuto di cert-base64.txt)

   **Secret 2:**
   - Name: `WINDOWS_CERT_PASSWORD`
   - Value: `YourSecurePassword123!`

   **Secret 3:**
   - Name: `WINDOWS_PUBLISHER`
   - Value: `CN=LigaDuck Srl, O=LigaDuck, L=Rome, S=Lazio, C=IT`
     (usa i dati esatti del tuo certificato)

3. ✅ I secrets sono ora configurati e sicuri

### 3.3 GitHub Actions li userà automaticamente

I workflow sono già configurati per usare i secrets se disponibili:
- `.github/workflows/build_windows_msix.yml`
- `.github/workflows/build_and_release.yml`

Se i secrets sono configurati, verranno usati automaticamente.
Altrimenti, userà il certificato auto-generato (fallback).

## ✅ Passo 4: Verifica

### 4.1 Build su GitHub Actions

1. Vai su **Actions**
2. Seleziona **"Build Windows MSIX"**
3. **Run workflow** con una versione
4. Attendi il completamento

### 4.2 Scarica e testa

1. Scarica l'artifact MSIX
2. **Doppio click** sul file .msix
3. Dovresti vedere:
   - ✅ Nessun warning di sicurezza
   - ✅ "Verified publisher: LigaDuck" (o il tuo nome)
   - ✅ Installazione pulita

### 4.3 Verifica firma

```powershell
# Su Windows PowerShell
Get-AuthenticodeSignature "LigaDuckManager-Windows-v43.1.2.msix"

# Output atteso:
# Status        : Valid
# SignerCertificate : CN=LigaDuck Srl, O=LigaDuck, ...
```

## 🔄 Aggiornamenti

Il certificato è valido per 1-3 anni. Prima della scadenza:

1. Rinnova il certificato dal fornitore
2. Aggiorna il Base64 nei GitHub Secrets
3. Aggiorna la password se cambiata

## 🆘 Troubleshooting

### Errore "Publisher name does not match"

Il campo `publisher` deve corrispondere ESATTAMENTE al Subject del certificato.

Verifica con:
```powershell
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("cert.pfx", "password")
$cert.Subject
# Copia l'output esatto in pubspec.yaml → publisher
```

### Errore "Certificate password incorrect"

- Verifica la password
- Alcuni certificati hanno password vuota: usa `certificate_password: ""`

### Build fallisce su GitHub Actions

- Verifica che i secrets siano configurati correttamente
- Controlla che il Base64 sia completo (nessun troncamento)
- Verifica i log di GitHub Actions per errori specifici

## 📚 Risorse

- [Documentazione MSIX ufficiale](https://docs.microsoft.com/en-us/windows/msix/)
- [Code Signing su Windows](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [DigiCert Code Signing Guide](https://www.digicert.com/kb/code-signing/code-signing-guide.htm)

## 💡 Alternative economiche

Se €200-400/anno sono troppi:

1. **Microsoft Store** (€14/anno)
   - Microsoft firma automaticamente
   - Distribuzione tramite Store
   - Pro: Molto economico, automatico
   - Contro: Processo review, meno controllo

2. **Distribuzione interna**
   - Usa certificato auto-generato
   - Distribuisci script helper incluso
   - Pro: Gratuito
   - Contro: Step extra per utenti

Per uso commerciale pubblico, il certificato commerciale è l'investimento migliore.
