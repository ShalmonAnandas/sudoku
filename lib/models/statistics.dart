import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Class that stores a single game record for statistics
class GameRecord {
  final Difficulty difficulty;
  final int timeInSeconds;
  final int score;
  final int errorCount;
  final int hintsUsed;
  final bool completed;
  final DateTime playedAt;

  const GameRecord({
    required this.difficulty,
    required this.timeInSeconds,
    required this.score,
    required this.errorCount,
    required this.hintsUsed,
    required this.completed,
    required this.playedAt,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      timeInSeconds: json['timeInSeconds'] as int,
      score: json['score'] as int,
      errorCount: json['errorCount'] as int,
      hintsUsed: json['hintsUsed'] as int,
      completed: json['completed'] as bool,
      playedAt: DateTime.parse(json['playedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty.name,
      'timeInSeconds': timeInSeconds,
      'score': score,
      'errorCount': errorCount,
      'hintsUsed': hintsUsed,
      'completed': completed,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}

/// Class that stores daily play records for streak tracking
class DailyPlayRecord {
  final DateTime date;
  final int gamesPlayed;
  final int gamesCompleted;
  final int totalPlayTimeInSeconds;

  const DailyPlayRecord({
    required this.date,
    required this.gamesPlayed,
    required this.gamesCompleted,
    required this.totalPlayTimeInSeconds,
  });

  factory DailyPlayRecord.fromJson(Map<String, dynamic> json) {
    return DailyPlayRecord(
      date: DateTime.parse(json['date']),
      gamesPlayed: json['gamesPlayed'] as int,
      gamesCompleted: json['gamesCompleted'] as int,
      totalPlayTimeInSeconds: json['totalPlayTimeInSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'gamesPlayed': gamesPlayed,
      'gamesCompleted': gamesCompleted,
      'totalPlayTimeInSeconds': totalPlayTimeInSeconds,
    };
  }
}

/// Main statistics model that tracks all player statistics
class GameStatistics {
  final List<GameRecord> gameRecords;
  final List<DailyPlayRecord> dailyRecords;
  final Map<String, bool> achievements;
  final Map<String, int> achievementProgress;

  const GameStatistics({
    this.gameRecords = const [],
    this.dailyRecords = const [],
    this.achievements = const {},
    this.achievementProgress = const {},
  });

  /// Get total games played
  int get gamesPlayed => gameRecords.length;

  /// Get total games won
  int get gamesWon => gameRecords.where((game) => game.completed).length;

  /// Get win rate as percentage
  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;

  /// Get average time in seconds
  int get averageTime {
    final completedGames = gameRecords.where((game) => game.completed).toList();
    if (completedGames.isEmpty) return 0;
    final totalTime = completedGames.fold(
        0, (sum, game) => sum + game.timeInSeconds);
    return totalTime ~/ completedGames.length;
  }

  /// Get best score
  int get bestScore {
    if (gameRecords.isEmpty) return 0;
    return gameRecords
        .where((game) => game.completed)
        .fold(0, (max, game) => game.score > max ? game.score : max);
  }

  /// Get total hints used
  int get hintsUsed => 
      gameRecords.fold(0, (sum, game) => sum + game.hintsUsed);

  /// Get total play time in seconds
  int get totalPlayTime => 
      gameRecords.fold(0, (sum, game) => sum + game.timeInSeconds);

  /// Get game records for a specific difficulty
  List<GameRecord> getRecordsForDifficulty(Difficulty difficulty) {
    return gameRecords.where((game) => game.difficulty == difficulty).toList();
  }

  /// Get games played for a specific difficulty
  int gamesPlayedForDifficulty(Difficulty difficulty) {
    return getRecordsForDifficulty(difficulty).length;
  }

  /// Get games won for a specific difficulty
  int gamesWonForDifficulty(Difficulty difficulty) {
    return getRecordsForDifficulty(difficulty)
        .where((game) => game.completed)
        .length;
  }

  /// Get best time for a specific difficulty in seconds
  int bestTimeForDifficulty(Difficulty difficulty) {
    final completedGames = getRecordsForDifficulty(difficulty)
        .where((game) => game.completed)
        .toList();
    if (completedGames.isEmpty) return 0;
    return completedGames.fold(
        completedGames.first.timeInSeconds,
        (min, game) => game.timeInSeconds < min ? game.timeInSeconds : min);
  }

  /// Format time in seconds to MM:SS format
  static String formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get current streak (consecutive days played)
  int get currentStreak {
    if (dailyRecords.isEmpty) return 0;
    
    // Sort records by date (newest first)
    final sortedRecords = [...dailyRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Check if played today
    final today = DateTime.now();
    final todayPlayed = sortedRecords.any((record) => 
        record.date.year == today.year && 
        record.date.month == today.month && 
        record.date.day == today.day);
    
    if (!todayPlayed) return 0;
      int streak = 1; // Today counts as 1
    
    for (int i = 1; i < sortedRecords.length; i++) {
      final currentDate = DateTime(
        sortedRecords[i-1].date.year,
        sortedRecords[i-1].date.month,
        sortedRecords[i-1].date.day,
      );
      
      final previousDate = DateTime(
        sortedRecords[i].date.year,
        sortedRecords[i].date.month,
        sortedRecords[i].date.day,
      );
      
      final difference = currentDate.difference(previousDate).inDays;
      
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Get longest streak
  int get longestStreak {
    if (dailyRecords.isEmpty) return 0;
    
    // Sort records by date
    final sortedRecords = [...dailyRecords]
      ..sort((a, b) => a.date.compareTo(b.date));
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedRecords.length; i++) {
      final currentDate = DateTime(
        sortedRecords[i].date.year,
        sortedRecords[i].date.month,
        sortedRecords[i].date.day,
      );
      
      final previousDate = DateTime(
        sortedRecords[i-1].date.year,
        sortedRecords[i-1].date.month,
        sortedRecords[i-1].date.day,
      );
      
      final difference = currentDate.difference(previousDate).inDays;
      
      if (difference == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  /// Get achievement completion status
  bool isAchievementUnlocked(String achievementId) {
    return achievements[achievementId] == true;
  }

  /// Get achievement progress (0.0 to 1.0)
  double getAchievementProgress(String achievementId) {
    final target = AchievementDefinition.getById(achievementId)?.target ?? 1;
    final current = achievementProgress[achievementId] ?? 0;
    return current / target;
  }

  /// Create a new GameStatistics from JSON
  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      gameRecords: (json['gameRecords'] as List)
          .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyRecords: (json['dailyRecords'] as List)
          .map((e) => DailyPlayRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: Map<String, bool>.from(json['achievements'] ?? {}),
      achievementProgress: Map<String, int>.from(json['achievementProgress'] ?? {}),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'gameRecords': gameRecords.map((e) => e.toJson()).toList(),
      'dailyRecords': dailyRecords.map((e) => e.toJson()).toList(),
      'achievements': achievements,
      'achievementProgress': achievementProgress,
    };
  }

  /// Add a new game record and update statistics
  GameStatistics addGameRecord(GameRecord record) {
    final newRecords = [...gameRecords, record];
    
    // Update daily record
    final today = DateTime(
        record.playedAt.year, record.playedAt.month, record.playedAt.day);
    
    final existingDailyRecord = dailyRecords.firstWhere(
      (dailyRecord) => 
          dailyRecord.date.year == today.year && 
          dailyRecord.date.month == today.month && 
          dailyRecord.date.day == today.day,
      orElse: () => DailyPlayRecord(
        date: today,
        gamesPlayed: 0,
        gamesCompleted: 0,
        totalPlayTimeInSeconds: 0,
      ),
    );

    final updatedDailyRecord = DailyPlayRecord(
      date: today,
      gamesPlayed: existingDailyRecord.gamesPlayed + 1,
      gamesCompleted: existingDailyRecord.gamesCompleted + (record.completed ? 1 : 0),
      totalPlayTimeInSeconds: existingDailyRecord.totalPlayTimeInSeconds + record.timeInSeconds,
    );
    
    final newDailyRecords = [...dailyRecords];
    final existingIndex = dailyRecords.indexOf(existingDailyRecord);
    if (existingIndex >= 0) {
      newDailyRecords[existingIndex] = updatedDailyRecord;
    } else {
      newDailyRecords.add(updatedDailyRecord);
    }
    
    // Update achievements
    final newAchievements = {...achievements};
    final newProgress = {...achievementProgress};
    
    // Process achievements
    _processAchievements(
      record,
      newRecords,
      newAchievements,
      newProgress,
    );
    
    return GameStatistics(
      gameRecords: newRecords,
      dailyRecords: newDailyRecords,
      achievements: newAchievements,
      achievementProgress: newProgress,
    );
  }

  /// Process and update achievements based on game state
  void _processAchievements(
    GameRecord record,
    List<GameRecord> allRecords,
    Map<String, bool> newAchievements,
    Map<String, int> newProgress,
  ) {
    // First victory achievement
    if (record.completed) {
      newAchievements['first_victory'] = true;
    }
    
    // Perfect score achievement
    if (record.completed && record.errorCount == 0 && record.hintsUsed == 0) {
      newAchievements['perfect_score'] = true;
    }
    
    // Speed demon achievement
    if (record.completed && 
        record.difficulty == Difficulty.easy && 
        record.timeInSeconds < 300) { // under 5 minutes
      newAchievements['speed_demon'] = true;
    }
    
    // Count completed puzzles
    final completedCount = allRecords.where((r) => r.completed).length;
    newProgress['puzzle_solver'] = completedCount;
    if (completedCount >= 100) {
      newAchievements['puzzle_solver'] = true;
    }
    
    newProgress['master_player'] = completedCount;
    if (completedCount >= 50) {
      newAchievements['master_player'] = true;
    }
    
    // Count extreme puzzles
    final extremeCount = allRecords
        .where((r) => r.completed && r.difficulty == Difficulty.extreme)
        .length;
    newProgress['extreme_champion'] = extremeCount;
    if (extremeCount >= 10) {
      newAchievements['extreme_champion'] = true;
    }
    
    // Track total play time
    final totalHours = totalPlayTime / 3600; // Convert to hours
    newProgress['time_master'] = (totalHours * 100).toInt(); // Store as integer (percent of 24 hours)
    if (totalHours >= 24) { // 24 hours of play
      newAchievements['time_master'] = true;
    }
    
    // Streak achievements are handled in the daily record update
    if (currentStreak >= 7) {
      newAchievements['dedication'] = true;
    }
  }
}

/// Definition for achievements
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.target = 1,
  });
  
  static AchievementDefinition? getById(String id) {
    return allAchievements.firstWhere(
      (achievement) => achievement.id == id,
      orElse: () => allAchievements.first,
    );
  }
  
  static List<AchievementDefinition> get allAchievements => [
    AchievementDefinition(
      id: 'first_victory',
      title: 'First Victory',
      description: 'Complete your first puzzle',
      icon: Icons.emoji_events,
    ),
    AchievementDefinition(
      id: 'perfect_score',
      title: 'Perfect Score',
      description: 'Complete a puzzle without errors or hints',
      icon: Icons.star,
    ),
    AchievementDefinition(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete an easy puzzle in under 5 minutes',
      icon: Icons.flash_on,
    ),
    AchievementDefinition(
      id: 'dedication',
      title: 'Dedication',
      description: 'Play for 7 consecutive days',
      icon: Icons.calendar_today,
      target: 7,
    ),
    AchievementDefinition(
      id: 'master_player',
      title: 'Master Player',
      description: 'Complete 50 puzzles',
      icon: Icons.school,
      target: 50,
    ),
    AchievementDefinition(
      id: 'extreme_champion',
      title: 'Extreme Champion',
      description: 'Complete 10 extreme puzzles',
      icon: Icons.military_tech,
      target: 10,
    ),
    AchievementDefinition(
      id: 'time_master',
      title: 'Time Master',
      description: 'Total play time reaches 24 hours',
      icon: Icons.access_time,
      target: 2400, // 24 hours * 100 (stored as integer percentage)
    ),
    AchievementDefinition(
      id: 'puzzle_solver',
      title: 'Puzzle Solver',
      description: 'Complete 100 puzzles',
      icon: Icons.extension,
      target: 100,
    ),
  ];
}
