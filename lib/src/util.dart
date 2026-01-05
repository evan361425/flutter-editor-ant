import 'dart:developer' show log;

/// Global configuration for EditorAnt.
class EditorAntConfig {
  /// Enable to log debug messages when styles changed.
  static bool enableLogging = false;
}

void logging(String message, String name) {
  log('${name.padRight(8)} - $message', name: 'EditorAnt');
}
