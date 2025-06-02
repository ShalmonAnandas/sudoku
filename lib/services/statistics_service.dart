import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';

/// Service for managing game statistics
class StatisticsService {
  static const String _statisticsKey = 'game_statistics';

  /// Save statistics to local storage
  static Future<bool> saveStatistics(GameStatistics statistics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = jsonEncode(statistics.toJson());
      return await prefs.setString(_statisticsKey, statisticsJson);
    } catch (e) {
      print('Error saving statistics: $e');
      return false;
    }
  }

  /// Load statistics from local storage
  static Future<GameStatistics> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = prefs.getString(_statisticsKey);

      if (statisticsJson == null) {
        // Return empty statistics if not found
        return GameStatistics();
      }

      final statisticsMap = jsonDecode(statisticsJson) as Map<String, dynamic>;
      return GameStatistics.fromJson(statisticsMap);
    } catch (e) {
      print('Error loading statistics: $e');
      return GameStatistics(); // Return empty statistics on error
    }
  }

  /// Add a completed game to statistics
  static Future<bool> addCompletedGame(GameState gameState) async {
    try {
      final currentStats = await loadStatistics();
      
      // Convert game state to game record
      final record = GameRecord(
        difficulty: gameState.board.difficulty,
        timeInSeconds: gameState.elapsedSeconds,
        score: gameState.score,
        errorCount: gameState.errorsCount,
        hintsUsed: gameState.hintsUsed,
        completed: gameState.isCompleted,
        playedAt: DateTime.now(),
      );
      
      // Add record to statistics
      final updatedStats = currentStats.addGameRecord(record);
      
      // Save updated statistics
      return await saveStatistics(updatedStats);
    } catch (e) {
      print('Error adding completed game: $e');
      return false;
    }
  }

  /// Clear all statistics (mainly for testing)
  static Future<bool> clearStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_statisticsKey);
    } catch (e) {
      print('Error clearing statistics: $e');
      return false;
    }
  }
}
