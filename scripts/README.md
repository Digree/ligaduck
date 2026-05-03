# 📦 Script di Build e Release

Script modulari per creare release di Liga Duck Manager.

## 🎯 Script Disponibili

### 1. **Aggiorna Versione**
```bash
./scripts/update_version.sh 43.01.00
```
Aggiorna solo la versione in `pubspec.yaml`.

### 2. **Build Android** 
```bash
./scripts/build_android.sh 43.01.00
```
- Builda APK Android
- Output: `build/ligaduck-v43.01.00.apk`

### 3. **Build iOS**
```bash
./scripts/build_ios.sh 43.01.00
```
- Builda IPA iOS
- Output: `build/ligaduck-v43.01.00.ipa`

**Nota**: Richiede certificati Apple Developer configurati

### 4. **Build macOS**
```bash
./scripts/build_macos.sh 43.01.00
```
- Builda app macOS
- Crea DMG (se `create-dmg` installato)
- Output: `build/ligaduck-v43.01.00.dmg`

**Nota**: Installa create-dmg con `brew install create-dmg`

### 5. **Build Windows**
```bash
./scripts/build_windows.sh 43.01.00
```
- Builda app Windows
- Crea ZIP
- Output: `build/ligaduck-v43.01.00-windows.zip`

**Nota**: Funziona solo su Windows

### 6. **Crea Release GitHub**
```bash
./scripts/create_github_release.sh 43.01.00
```
- Aggiorna `version.json`
- Crea commit e tag Git
- Crea release su GitHub
- Carica tutti gli artefatti trovati in `build/`

**Prerequisito**: GitHub CLI installato (`brew install gh`)

---

## 🚀 Workflow Completo

### Opzione A: Build separati (consigliato per debug)

```bash
# 1. Aggiorna versione
./scripts/update_version.sh 43.01.00

# 2. Build Android (sempre funziona)
./scripts/build_android.sh 43.01.00

# 3. Build iOS (solo su Mac con certificati Apple)
./scripts/build_ios.sh 43.01.00

# 4. Build macOS (solo su Mac)
./scripts/build_macos.sh 43.01.00

# 5. Build Windows (solo su Windows - opzionale)
# ./scripts/build_windows.sh 43.01.00

# 6. Crea release GitHub con artefatti disponibili
./scripts/create_github_release.sh 43.01.00
```

### Opzione B: Script automatico (tutto insieme)

```bash
./scripts/create_release.sh 43.01.00
```
Esegue tutti i passaggi automaticamente.

---

## ⚠️ Troubleshooting

### Android build fallisce
```bash
# Pulisci cache Gradle
rm -rf ~/.gradle/caches/8.12
rm -rf android/.gradle
flutter clean

# Riprova
./scripts/build_android.sh 43.01.00
```

### macOS build fallisce
```bash
# Pulisci build macOS
flutter clean
rm -rf build/macos

# Riprova
./scripts/build_macos.sh 43.01.00
```

### "No space left on device"
```bash
# Libera spazio disco
rm -rf ~/.gradle/caches  # Cache Gradle
flutter clean             # Cache Flutter
rm -rf build/             # Build artifacts
```

### GitHub CLI non autenticato
```bash
gh auth login
```

### Windows: L'eseguibile non si avvia
Se l'eseguibile Windows non fa nulla quando viene cliccato:

**Per gli utenti**:
1. Estrarre **TUTTO** il contenuto dello ZIP
2. NON spostare solo il file `.exe`
3. La cartella `data` deve essere accanto all'eseguibile
4. Leggere il file `README.txt` incluso nello ZIP

**Per sviluppatori**:
- Lo script `build_windows.bat/sh` ora:
  - ✅ Verifica che tutti i file necessari siano presenti
  - ✅ Crea automaticamente un `README.txt` con istruzioni
  - ✅ Mantiene la struttura corretta delle cartelle nello ZIP
  
- Il file `windows/runner/main.cpp` ora:
  - ✅ Controlla che la cartella `data` esista all'avvio
  - ✅ Mostra un dialog di errore chiaro se manca

```bash
# Test della build Windows (su Windows)
./scripts/build_windows.bat 43.01.00

# Verifica contenuto ZIP
powershell -Command "Expand-Archive -Path build\ligaduck-v43.01.00-windows.zip -DestinationPath test_extract"
dir test_extract
```

---

## iOS**: Richiede macOS + Xcode + certificati Apple Developer
- **📝 Note

- **Android**: Sempre disponibile su ogni piattaforma
- **macOS**: Richiede macOS + Xcode + create-dmg (opzionale)
- **Windows**: Richiede Windows (cross-compile non supportato su Mac)
- **GitHub Release**: Carica solo gli artefatti che trova

---

## 🔧 Installazione Dipendenze

```bash
# macOS
brew install create-dmg    # Per DMG macOS
brew install gh            # GitHub CLI

# Configura GitHub CLI
gh auth login
```
