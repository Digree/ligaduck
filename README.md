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
  - Vedi [WINDOWS_MSIX.md](WINDOWS_MSIX.md) per dettagli

Consulta [scripts/README.md](scripts/README.md) per la guida completa.
