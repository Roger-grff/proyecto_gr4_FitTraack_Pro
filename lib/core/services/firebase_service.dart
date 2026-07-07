import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;
  static String? _errorMessage;

  /// Check if Firebase is successfully initialized
  static bool get isInitialized => _initialized;

  /// Get error message if initialization failed
  static String? get errorMessage => _errorMessage;

  /// Initialize Firebase app safely
  static Future<bool> initialize() async {
    if (_initialized) return true;
    
    try {
      // Define options directly using credentials from google-services.json
      // This ensures Web, Android, and iOS all initialize successfully.
      const firebaseOptions = FirebaseOptions(
        apiKey: 'AIzaSyCmDlmYl4urJ_EpQkm_z2Q6oxopsZk7HT8',
        appId: '1:666204526223:android:38ea721c12af899cddc2fa',
        messagingSenderId: '666204526223',
        projectId: 'proyectofit-cbf08',
        storageBucket: 'proyectofit-cbf08.firebasestorage.app',
      );

      await Firebase.initializeApp(options: firebaseOptions);
      _initialized = true;
      _errorMessage = null;
      debugPrint("Firebase successfully initialized.");
      return true;
    } catch (e) {
      _initialized = false;
      _errorMessage = e.toString();
      debugPrint("Firebase initialization failed (Offline mode activated): $e");
      return false;
    }
  }
}
