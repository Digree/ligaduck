# Sistema di Caching - Ottimizzazione Chiamate Backend

## Panoramica
È stato implementato un sistema di caching centralizzato per ridurre le chiamate ripetute al backend e migliorare le performance dell'app.

## File Implementati

### 1. `cache_service.dart`
Service singleton per la gestione centralizzata della cache in memoria.

**Funzionalità:**
- ✅ Cache in memoria con timestamp
- ✅ Durata personalizzabile per ogni entry
- ✅ Invalidazione singola chiave
- ✅ Invalidazione per prefisso (es. tutte le partite di un campionato)
- ✅ Pulizia automatica della cache vecchia
- ✅ Clear completo della cache

**Metodi principali:**
```dart
get<T>(String key, {Duration? maxAge})  // Recupera dalla cache
set<T>(String key, T data)              // Salva in cache
invalidate(String key)                  // Invalida una chiave
invalidatePrefix(String prefix)         // Invalida per prefisso
cleanOldCache({Duration maxAge})        // Pulisce cache vecchia
clear()                                 // Svuota tutta la cache
```

## Provider Modificati

### 1. **CompetizioniProvider**

#### `getCompetizione(campionato, idGiornata)`
- **Cache key:** `competizione_{campionato}_{idGiornata}`
- **Durata cache:** 10 minuti
- **Ottimizzazione:** `/competizioni/{idGiornata}` viene cachata quando ci sono partite recenti

#### `fetchVincitori(campionato)`
- **Cache key:** `vincitori_{campionato}`
- **Durata cache:** 30 minuti
- **Ottimizzazione:** `/competizioni/vincitori` - i vincitori cambiano raramente

### 2. **ConfigProvider**

#### `fetchConfig()`
- **Cache key:** `config`
- **Durata cache:** 1 ora
- **Ottimizzazione:** `/config` - la configurazione è molto stabile

### 3. **PartiteProvider**

#### `fetchPartite(campionato, idGiornata)`
- **Cache key:** `partite_{campionato}_{idGiornata}`
- **Durata cache:** 3 minuti
- **Ottimizzazione:** `/{idGiornata}/partite` - cache breve per partite in corso

#### Invalidazione automatica
La cache viene invalidata quando:
- ✅ `putEvento()` - Aggiunta evento
- ✅ `deleteEvento()` - Rimozione evento
- ✅ `putFormazione()` - Salvataggio formazione
- ✅ `modificaDatiSquadra()` - Modifica dati squadra
- ✅ `salvaPartita()` - Salvataggio partita (invalida anche competizioni)

### 4. **GiocatoriProvider**

#### `getGiocatoreById(campionato, idGiocatore)`
- **Cache key:** `giocatore_{campionato}_{idGiocatore}`
- **Durata cache:** 10 minuti
- **Ottimizzazione:** `/giocatore/{idGiocatore}` - dati giocatore relativamente stabili

## Parametro forceRefresh

Tutti i metodi cachati supportano il parametro `forceRefresh`:

```dart
// Usa cache se disponibile
await provider.fetchPartite(campionato, idGiornata);

// Forza refresh dal backend
await provider.fetchPartite(campionato, idGiornata, forceRefresh: true);
```

## Pulizia Automatica

Nel `main.dart` è stato implementato un timer che pulisce automaticamente la cache vecchia:
- ⏱️ **Frequenza:** Ogni 30 minuti
- 🗑️ **Criterio:** Rimuove entry più vecchie di 1 ora

## Benefici

1. **Riduzione chiamate backend**: Le stesse richieste non vengono ripetute entro il periodo di cache
2. **Performance migliorate**: Risposta istantanea per dati già in cache
3. **Esperienza utente**: Navigazione più fluida e veloce
4. **Consumo dati ridotto**: Meno traffico di rete

## Esempi di Utilizzo

### Competizioni
```dart
// Prima chiamata: backend
final comp1 = await provider.getCompetizione('43', 'g1_1');

// Entro 10 minuti: cache
final comp2 = await provider.getCompetizione('43', 'g1_1');

// Forza refresh
final comp3 = await provider.getCompetizione('43', 'g1_1', forceRefresh: true);
```

### Config
```dart
// Cache lunga (1 ora) - config cambia raramente
final config = await configProvider.fetchConfig();
```

### Partite
```dart
// Cache breve (3 minuti) - partite in corso
final partite = await partiteProvider.fetchPartite('43', 'g1_1');

// Dopo modifica, la cache viene automaticamente invalidata
await partiteProvider.putEvento(campionato, idPartita, evento);
// Prossima chiamata fetchPartite andrà al backend
```

## Note Tecniche

- La cache è **in memoria** e viene persa quando l'app viene chiusa
- Ogni entry ha un **timestamp** per determinare se è ancora valida
- Le durate sono calibrate in base alla frequenza di aggiornamento dei dati
- L'invalidazione è **automatica** dopo operazioni di modifica
- Il sistema è **type-safe** grazie ai generics

## Monitoraggio

Per verificare l'efficacia del caching, cercare nei log:
- Le chiamate effettive al backend mostrano il response status
- Le operazioni di invalidazione mostrano quando la cache viene pulita
