import 'package:flutter/foundation.dart';
import 'package:ligaduck/services/update_service.dart';

/// Provider per gestire lo stato degli aggiornamenti dell'app
class UpdateNotifier extends ChangeNotifier {
  bool _isUpdateAvailable = false;
  UpdateInfo? _updateInfo;
  bool _isChecking = false;
  String? _error;

  bool get isUpdateAvailable => _isUpdateAvailable;
  UpdateInfo? get updateInfo => _updateInfo;
  bool get isChecking => _isChecking;
  String? get error => _error;

  /// Controlla se ci sono aggiornamenti disponibili
  Future<void> checkForUpdates({bool silent = false}) async {
    if (_isChecking) return;

    _isChecking = true;
    _error = null;
    if (!silent) notifyListeners();

    try {
      final updateInfo = await UpdateService.checkForUpdates();
      
      if (updateInfo == null) {
        // Servizio ha ritornato null - errore di rete o piattaforma non supportata
        _error = 'Impossibile controllare gli aggiornamenti';
        _isUpdateAvailable = false;
        _updateInfo = null;
      } else {
        _updateInfo = updateInfo;
        _isUpdateAvailable = updateInfo.isUpdateAvailable;
        _error = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isUpdateAvailable = false;
      _updateInfo = null;
      
      if (!silent) notifyListeners();
    } finally {
      _isChecking = false;
      if (!silent) notifyListeners();
    }
  }

  /// Segna l'aggiornamento come visto (nasconde il badge)
  void markUpdateAsSeen() {
    _isUpdateAvailable = false;
    notifyListeners();
  }

  /// Reset dello stato
  void reset() {
    _isUpdateAvailable = false;
    _updateInfo = null;
    _isChecking = false;
    _error = null;
    notifyListeners();
  }
}
