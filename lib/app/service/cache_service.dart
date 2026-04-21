class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};

  /// Cache con durata personalizzata (default 5 minuti)
  T? get<T>(String key, {Duration? maxAge}) {
    final entry = _cache[key];
    if (entry == null) return null;

    final age = maxAge ?? Duration(minutes: 5);
    if (DateTime.now().difference(entry.timestamp) > age) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Salva nella cache
  void set<T>(String key, T data) {
    _cache[key] = CacheEntry(data: data, timestamp: DateTime.now());
  }

  /// Invalida una specifica chiave
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalida tutte le chiavi che iniziano con un prefisso
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, value) => key.startsWith(prefix));
  }

  /// Pulisce tutta la cache
  void clear() {
    _cache.clear();
  }

  /// Invalida la cache vecchia (oltre maxAge)
  void cleanOldCache({Duration maxAge = const Duration(hours: 1)}) {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > maxAge;
    });
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});
}
