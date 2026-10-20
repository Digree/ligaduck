# ligaduck

A new Flutter project.

## Effetti glass

Su iOS 26 e versioni successive la barra di navigazione principale e i pulsanti glass dedicati usano i controlli Liquid Glass nativi di Apple (`native_liquid_glass`). Su versioni precedenti di iOS e sulle altre piattaforme restano attivi i widget Flutter esistenti.

Windows usa intenzionalmente superfici opache per gli sfondi glass: il blur GPU (`BackdropFilter`) è disabilitato nel fallback di piattaforma, per evitare artefatti di compositing. Non è quindi un effetto che dipende da un driver GPU errato; il rendering Windows è già instradato sul fallback opaco.

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
