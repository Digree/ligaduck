# Versionamento Automatico Liga Duck

## Overview
Questo sistema aggiorna automaticamente il build number basato sul numero totale di commit del repository. Ogni build avrà un numero incrementale unico.

## Setup

### 1. Dipendenze aggiunte
- **pubspec.yaml**: 
  - `package_info_plus: ^7.0.0` - Per leggere versione e build number
  - `git_version: ^2.0.0` (dev) - Per accedere alle informazioni Git

### 2. File creati
- `lib/app/utils/version_helper.dart` - Utility per gestire versione e build number
- `scripts/update_build_number.ps1` - Script PowerShell per aggiornare il build number
- `build.ps1` - Script di build con versionamento automatico

## Utilizzo

### Build automatico (consigliato)
```powershell
.\build.ps1                    # Build APK release (default)
.\build.ps1 --debug            # Build APK debug
.\build.ps1 --aab              # Build AAB release
.\build.ps1 --aab --debug      # Build AAB debug
```

### Aggiornamento manuale versione
```powershell
.\scripts\update_build_number.ps1
```

### Nel codice Flutter
```dart
import 'package:ligaduck/app/utils/version_helper.dart';

// Ottenere versione app
String version = await VersionHelper.getAppVersion(); // "0.1.0"

// Ottenere versione completa
String fullVersion = await VersionHelper.getFullVersion(); // "0.1.0+42"

// Ottenere build number
String buildNumber = await VersionHelper.getBuildNumber(); // "42"
```

### Visualizzare versione nell'app
Modifica `home_page.dart` per mostrare la versione:
```dart
// Nel settings menu
Text(
  'App Version: ${await VersionHelper.getFullVersion()}',
  style: TextStyle(fontSize: 12, color: Colors.white),
)
```

## Come funziona

1. **Automatico**: Ogni volta che esegui `.\build.ps1`, lo script:
   - Conta i commit totali del repository (`git rev-list --all --count`)
   - Aggiorna il `pubspec.yaml` con il nuovo build number
   - Esegue `flutter build` con il numero aggiornato

2. **Formato versione**: `0.1.0+42`
   - `0.1.0` = App version (configura manualmente)
   - `+42` = Build number (auto-incrementale dal commit count)

3. **Commit tracking**: Ogni nuovo commit aumenta il numero

## Configurare la versione base
Modifica `pubspec.yaml`:
```yaml
version: 0.1.0+1  # Cambia 0.1.0 con la versione desiderata
```

## Note
- I script PS1 richiedono PowerShell 7+
- Git deve essere installato e accessibile via command line
- Il build number si sincronizzerà automaticamente col repository
