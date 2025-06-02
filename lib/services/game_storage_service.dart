import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for saving and loading game state to/from local storage
class GameStorageService {
  static const String _gameStateKey = 'current_game_state';
  static const String _autoSaveEnabledKey = 'auto_save_enabled';
  
  /// Save the current game state
  static Future<bool> saveGame(GameState gameState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = jsonEncode(gameState.toJson());
      return await prefs.setString(_gameStateKey, gameStateJson);
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }
  
  /// Load the saved game state
  static Future<GameState?> loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString(_gameStateKey);
      
      if (gameStateJson == null) return null;
      
      final gameStateMap = jsonDecode(gameStateJson) as Map<String, dynamic>;
      return GameState.fromJson(gameStateMap);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }
  
  /// Check if there's a saved game
  static Future<bool> hasSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_gameStateKey);
    } catch (e) {
      print('Error checking for saved game: $e');
      return false;
    }
  }
  
  /// Clear the saved game
  static Future<bool> clearSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_gameStateKey);
    } catch (e) {
      print('Error clearing saved game: $e');
      return false;
    }
  }
  
  /// Get auto-save preference
  static Future<bool> isAutoSaveEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoSaveEnabledKey) ?? true; // Default to enabled
    } catch (e) {
      print('Error getting auto-save preference: $e');
      return true;
    }
  }
  
  /// Set auto-save preference
  static Future<bool> setAutoSaveEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_autoSaveEnabledKey, enabled);
    } catch (e) {
      print('Error setting auto-save preference: $e');
      return false;
    }
  }
  
  /// Get saved game metadata (without loading full state)
  static Future<Map<String, dynamic>?> getSavedGameMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString(_gameStateKey);
      
      if (gameStateJson == null) return null;
      
      final gameStateMap = jsonDecode(gameStateJson) as Map<String, dynamic>;
      
      // Extract only metadata
      return {
        'difficulty': gameStateMap['board']?['difficulty'],
        'elapsedSeconds': gameStateMap['elapsedSeconds'],
        'startTime': gameStateMap['startTime'],
        'score': gameStateMap['score'],
        'moveCount': gameStateMap['moveCount'],
        'hintsUsed': gameStateMap['hintsUsed'],
        'errorsCount': gameStateMap['errorsCount'],
        'isCompleted': gameStateMap['isCompleted'],
      };
    } catch (e) {
      print('Error getting saved game metadata: $e');
      return null;
    }
  }
}
