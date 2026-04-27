# 🚀 Guida GitHub Releases

Guida completa per usare GitHub Releases per distribuire gli aggiornamenti di LigaDuck.

## 📋 Setup Iniziale (Una volta sola)

### 1. Installa GitHub CLI

```bash
brew install gh
```

### 2. Autentica con GitHub

```bash
gh auth login
```

Segui le istruzioni per autenticarti.

### 3. (Opzionale) Installa create-dmg per macOS

```bash
brew install create-dmg
```

## 🎯 Come Rilasciare un Aggiornamento

### Metodo Automatico (Consigliato)

```bash
./scripts/create_release.sh 43.01.00
```

Lo script farà automaticamente:
1. ✅ Aggiorna la versione in `pubspec.yaml`
2. ✅ Builda l'app (APK Android + DMG macOS)
3. ✅ Ti chiede le note di rilascio
4. ✅ Aggiorna `version.json`
5. ✅ Commit e push su GitHub
6. ✅ Crea il tag Git
7. ✅ Crea la release su GitHub con i file allegati

**Inserimento note di rilascio:**
Quando lo script te lo chiede, scrivi le note e poi premi **CTRL+D** per confermare.

### Metodo Manuale

Se preferisci fare tutto manualmente:

#### 1. Aggiorna la versione

Modifica `pubspec.yaml`:
```yaml
version: 43.01.00
```

#### 2. Build dell'app

```bash
# Android
flutter build apk --release

# macOS (da Mac)
flutter build macos --release
```

I file saranno in:
- Android: `build/app/outputs/flutter-apk/app-release.apk`
- macOS: `build/macos/Build/Products/Release/ligaduck.app`

#### 3. Rinomina i file

```bash
# Android
cp build/app/outputs/flutter-apk/app-release.apk build/ligaduck-v43.01.00.apk

# macOS - Crea DMG
create-dmg \
  --volname "LigaDuck" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  build/ligaduck-v43.01.00.dmg \
  build/macos/Build/Products/Release/ligaduck.app
```

#### 4. Aggiorna version.json

Modifica il file `version.json` nella root del progetto:

```json
{
  "lastUpdate": "2026-04-27",
  "android": {
    "version": "43.01.00",
    "downloadUrl": "https://github.com/Digree/ligaduck/releases/download/v43.01.00/ligaduck-v43.01.00.apk",
    "releaseNotes": "- Nuova funzionalità X\n- Correzione bug Y\n- Miglioramenti Z"
  },
  "macos": {
    "version": "43.01.00",
    "downloadUrl": "https://github.com/Digree/ligaduck/releases/download/v43.01.00/ligaduck-v43.01.00.dmg",
    "releaseNotes": "- Nuova funzionalità X\n- Correzione bug Y\n- Miglioramenti Z"
  }
}
```

#### 5. Commit e Tag

```bash
git add pubspec.yaml version.json
git commit -m "Release v43.01.00"
git tag -a v43.01.00 -m "Release v43.01.00"
git push origin main
git push origin v43.01.00
```

#### 6. Crea Release su GitHub

```bash
gh release create v43.01.00 \
  --title "LigaDuck v43.01.00" \
  --notes "- Nuova funzionalità X
- Correzione bug Y  
- Miglioramenti Z" \
  build/ligaduck-v43.01.00.apk \
  build/ligaduck-v43.01.00.dmg
```

Oppure vai su GitHub web:
1. Vai su: https://github.com/Digree/ligaduck/releases/new
2. Tag: `v43.01.00`
3. Titolo: `LigaDuck v43.01.00`
4. Descrizione: Le note di rilascio
5. Carica i file (APK, DMG)
6. Clicca "Publish release"

## 📱 Come gli utenti ricevono l'aggiornamento

1. L'utente apre l'app
2. Va su **Impostazioni** ⚙️
3. Clicca su **"Controlla aggiornamenti"**
4. Se disponibile, appare un dialog con:
   - Numero nuova versione
   - Note di rilascio
   - Pulsante "Scarica ora"
5. Cliccando "Scarica ora":
   - **Android**: Si apre il browser al link del APK (l'utente deve installare manualmente)
   - **iOS**: Si apre l'App Store
   - **macOS**: Si apre il browser al link del DMG

## 🔧 Troubleshooting

### "gh: command not found"
```bash
brew install gh
gh auth login
```

### "create-dmg: command not found"
```bash
brew install create-dmg
```

### Permission denied su script
```bash
chmod +x scripts/create_release.sh
```

### Gli utenti non vedono l'aggiornamento
1. Verifica che `version.json` sia stato pushato su GitHub
2. Controlla l'URL: https://raw.githubusercontent.com/Digree/ligaduck/main/version.json
3. Verifica che sia accessibile pubblicamente (apri in browser)
4. Controlla che la versione nel JSON sia maggiore di quella corrente

### Il download non funziona
1. Verifica che la release sia **pubblica** (non draft)
2. Controlla che gli URL in `version.json` siano corretti
3. Test dell'URL direttamente: https://github.com/Digree/ligaduck/releases

## 📝 Convenzioni di Versioning

Formato: `MAJOR.MINOR.PATCH` (es. 43.01.00)

- **MAJOR (43)**: Numero campionato/anno
- **MINOR (01)**: Nuove funzionalità, cambiamenti significativi
- **PATCH (00)**: Bug fix, piccole modifiche

Esempi:
- `43.00.00` → Versione iniziale campionato 43
- `43.01.00` → Prima release con nuove funzionalità
- `43.01.01` → Bug fix della 43.01.00
- `43.02.00` → Seconda release con nuove funzionalità
- `44.00.00` → Nuovo campionato

## 🎯 Checklist Release

- [ ] Testato su device reali
- [ ] Versione aggiornata in `pubspec.yaml`
- [ ] Build completato senza errori
- [ ] `version.json` aggiornato
- [ ] Commit e tag pushati
- [ ] Release creata su GitHub
- [ ] File (APK/DMG) caricati
- [ ] Testato il download dalla release
- [ ] Verificato che gli utenti ricevano la notifica

## 📚 Link Utili

- [Repository](https://github.com/Digree/ligaduck)
- [Releases](https://github.com/Digree/ligaduck/releases)
- [version.json](https://raw.githubusercontent.com/Digree/ligaduck/main/version.json)
- [GitHub CLI Docs](https://cli.github.com/manual/)
