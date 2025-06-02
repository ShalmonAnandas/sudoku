import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../constants/app_constants.dart';

/// Provider for accessing game statistics throughout the app
class StatisticsProvider with ChangeNotifier {
  GameStatistics _statistics = const GameStatistics();
  bool _isLoading = true;
  String? _error;

  /// Get the current statistics
  GameStatistics get statistics => _statistics;
  
  /// Whether statistics are currently loading
  bool get isLoading => _isLoading;
  
  /// Any error that occurred during loading
  String? get error => _error;
  
  /// Initialize provider by loading statistics
  StatisticsProvider() {
    loadStatistics();
  }
  
  /// Load statistics from storage
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _statistics = await StatisticsService.loadStatistics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Refresh statistics from storage (useful after a game is completed)
  Future<void> refreshStatistics() async {
    await loadStatistics();
  }
  
  /// Get statistics for a specific difficulty level
  DifficultyStatistics getDifficultyStats(Difficulty difficulty) {
    final records = _statistics.getRecordsForDifficulty(difficulty);
    final completed = records.where((r) => r.completed).toList();
    
    return DifficultyStatistics(
      difficulty: difficulty,
      gamesPlayed: records.length,
      gamesWon: completed.length,
      bestTime: completed.isEmpty ? 0 : 
        completed.map((r) => r.timeInSeconds).reduce((a, b) => a < b ? a : b),
    );
  }
  
  /// Get the achievement status for display
  List<AchievementStatus> getAchievements() {
    return AchievementDefinition.allAchievements.map((definition) {
      final isUnlocked = _statistics.isAchievementUnlocked(definition.id);
      final progress = _statistics.getAchievementProgress(definition.id);
      
      return AchievementStatus(
        definition: definition,
        isUnlocked: isUnlocked,
        progress: progress,
      );
    }).toList();
  }
}

/// Helper class for displaying difficulty-specific statistics
class DifficultyStatistics {
  final Difficulty difficulty;
  final int gamesPlayed;
  final int gamesWon;
  final int bestTime;
  
  const DifficultyStatistics({
    required this.difficulty,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.bestTime,
  });
  
  /// Calculate win rate as percentage
  double get winRate => 
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;
  
  /// Format best time as MM:SS
  String get bestTimeFormatted => 
      GameStatistics.formatTime(bestTime);
}

/// Helper class for displaying achievement status
class AchievementStatus {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final double progress;
  
  const AchievementStatus({
    required this.definition,
    required this.isUnlocked,
    required this.progress,
  });
}
