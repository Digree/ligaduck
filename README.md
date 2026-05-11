# ligaduck

A new Flutter project.

## 📦 Build & Release

LigaDuck Manager supporta build per multiple piattaforme:

### Android
- **APK**: `./scripts/build_android.sh <version>`

### iOS  
- **IPA**: `./scripts/build_ios.sh <version>` (richiede certificati Apple)

### macOS
- **DMG**: `./scripts/build_macos.sh <version>`

### Windows
- **ZIP Portable**: `./scripts/build_windows.sh <version>`
- **MSIX Installer**: `./scripts/build_windows_msix.sh <version>` 🆕
  - Formato moderno per Windows 10/11
  - Singolo file installer
  - Installazione pulita senza cartelle sparse
  - **Nota**: Con certificato auto-generato richiede step extra (vedi sotto)
  - **Consigliato**: Certificato commerciale per installazione automatica (vedi [guida](WINDOWS_MSIX_COMMERCIAL_CERT.md))
  - Vedi [WINDOWS_MSIX.md](WINDOWS_MSIX.md) per dettagli

#### 🔒 Installazione MSIX

**Con certificato auto-generato (default - gratuito):**
- Utenti devono eseguire `install_msix_windows.ps1` per installare certificato
- Vedi [WINDOWS_MSIX.md](WINDOWS_MSIX.md) per istruzioni

**Con certificato commerciale (€200-400/anno - installazione automatica):**
- Doppio click per installare, zero warning
- Configurazione: vedi [guida completa](WINDOWS_MSIX_COMMERCIAL_CERT.md)
- Consigliato per distribuzione pubblica professionale

Consulta [scripts/README.md](scripts/README.md) per la guida completa.
