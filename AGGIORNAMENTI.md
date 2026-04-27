# Sistema di Aggiornamenti In-App

## 📋 Panoramica

Il sistema di aggiornamenti in-app permette di notificare gli utenti quando è disponibile una nuova versione dell'app e di scaricarla direttamente.

## 🔧 Configurazione

### 1. Hosting del file version.json

Devi hostare un file JSON accessibile pubblicamente che contiene le informazioni sulle versioni disponibili. Hai diverse opzioni:

#### Opzione A: GitHub (Consigliato)
1. Crea un file `version.json` nella root del tuo repository
2. Usa il link raw di GitHub: `https://raw.githubusercontent.com/USERNAME/REPO/main/version.json`

#### Opzione B: Firebase Hosting
1. Carica `version.json` su Firebase Hosting
2. Usa l'URL pubblico di Firebase

#### Opzione C: Tuo server/API
1. Crea un endpoint che ritorna il JSON
2. Usa l'URL dell'endpoint

### 2. Formato del file version.json

Copia il file `version.json.example` e rinominalo in `version.json`, poi personalizza:

```json
{
  "android": {
    "version": "43.01.00",
    "downloadUrl": "https://github.com/USER/REPO/releases/download/v43.01.00/app.apk",
    "releaseNotes": "- Novità 1\n- Bug fix\n- Miglioramenti"
  },
  "ios": {
    "version": "43.01.00",
    "downloadUrl": "https://apps.apple.com/app/YOUR_APP_ID",
    "releaseNotes": "- Novità 1\n- Bug fix\n- Miglioramenti"
  },
  "macos": {
    "version": "43.01.00",
    "downloadUrl": "https://github.com/USER/REPO/releases/download/v43.01.00/app.dmg",
    "releaseNotes": "- Novità 1\n- Bug fix\n- Miglioramenti"
  }
}
```

### 3. Configurazione URL nel codice

Modifica il file `lib/services/update_service.dart` alla riga 28:

```dart
static const String updateInfoUrl = 
    'https://TUO_URL/version.json';
```

## 📦 Rilascio di un aggiornamento

### 1. Aggiorna la versione

Modifica manualmente `pubspec.yaml`:

```yaml
version: 43.01.00  # Incrementa la versione
```

### 2. Build dell'app

```bash
# Android
./build.sh --android --release

# iOS (da macOS)
./build.sh --ios --release

# macOS
flutter build macos --release
```

### 3. Pubblica i file

**Per Android (APK):**
1. Il file APK sarà in `build/app/outputs/flutter-apk/`
2. Caricalo su GitHub Releases o altro hosting
3. Copia l'URL del download

**Per iOS:**
1. Pubblica su App Store tramite Xcode
2. Usa il link dell'App Store nel version.json

**Per macOS:**
1. Crea un DMG dell'app
2. Caricalo su GitHub Releases o altro hosting

### 4. Aggiorna version.json

Aggiorna il file `version.json` sul tuo hosting con:
- Nuovo numero di versione
- URL del download
- Note di rilascio

```json
{
  "android": {
    "version": "43.01.00",  // ← Aggiorna questo
    "downloadUrl": "https://...",  // ← E questo
    "releaseNotes": "..."  // ← E questo
  }
}
```

## 📱 Utilizzo per gli utenti

1. Apri le **Impostazioni** dall'icona ⚙️
2. Vedrai la versione corrente in basso
3. Clicca su **"Controlla aggiornamenti"**
4. Se disponibile, apparirà un dialog con:
   - Numero nuova versione
   - Note di rilascio
   - Pulsante "Scarica ora"

## 🔄 Check automatico all'avvio (Opzionale)

Se vuoi controllare gli aggiornamenti automaticamente all'avvio dell'app, aggiungi questo nel `main.dart` o nella tua home page:

```dart
@override
void initState() {
  super.initState();
  _checkUpdatesSilently();
}

Future<void> _checkUpdatesSilently() async {
  await Future.delayed(Duration(seconds: 2)); // Attendi che l'app si carichi
  
  final updateInfo = await UpdateService.checkForUpdates();
  
  if (updateInfo != null && updateInfo.isUpdateAvailable) {
    // Mostra notifica o dialog
  }
}
```

## 🎨 Personalizzazione

### Cambiare il formato della versione

Il formato attuale è `XX.YY.ZZ` (es. 43.00.00):
- **XX**: Versione major (cambia raramente)
- **YY**: Versione minor (nuove funzionalità)
- **ZZ**: Patch (bug fix)

Puoi usare qualsiasi formato numerico separato da punti.

### Personalizzare i colori del dialog

Modifica i colori nel file `lib/app/widgets/settings_icon.dart`:
- Dialog background: `Colors.blueAccent`
- Pulsanti: `ElevatedButton.styleFrom`
- Testo: `TextStyle(color: ...)`

## 🐛 Troubleshooting

### Gli aggiornamenti non vengono rilevati
1. Verifica che l'URL in `update_service.dart` sia corretto
2. Controlla che il file version.json sia accessibile pubblicamente
3. Verifica il formato JSON (usa jsonlint.com)
4. Controlla i log nella console: cerca "DEBUG: " o "Errore"

### Il download non funziona
- **Android**: L'APK deve essere firmato e l'utente deve abilitare "Installa da fonti sconosciute"
- **iOS**: Deve puntare all'App Store, non si possono installare IPA direttamente
- **macOS**: L'app deve essere notarizzata da Apple per essere eseguita

### Permission denied su macOS
L'app potrebbe essere bloccata da Gatekeeper. L'utente deve:
1. Andare in Preferenze → Sicurezza
2. Cliccare "Apri comunque"

## 📝 Note

- Il sistema confronta le versioni numericamente (43.01.00 > 43.00.00)
- Ogni piattaforma può avere una versione diversa
- Il check degli aggiornamenti ha un timeout di 10 secondi
- Su iOS, il download apre sempre l'App Store (policy di Apple)
