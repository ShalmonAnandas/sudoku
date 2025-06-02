import 'dart:math';
import '../models/models.dart';
import '../constants/app_constants.dart';
import '../services/services.dart';

/// Helper class for generating test statistics data
class TestDataGenerator {
  static final Random _random = Random();
  
  /// Generate a random game record
  static GameRecord _generateGameRecord({
    required Difficulty difficulty,
    required bool completed,
    required DateTime date,
  }) {
    // Create reasonable time ranges based on difficulty level
    final minTime = difficulty == Difficulty.easy ? 180 : 
                    difficulty == Difficulty.medium ? 300 :
                    difficulty == Difficulty.hard ? 600 : 900;
    
    final maxTime = difficulty == Difficulty.easy ? 600 : 
                    difficulty == Difficulty.medium ? 900 :
                    difficulty == Difficulty.hard ? 1500 : 2400;
    
    final timeInSeconds = minTime + _random.nextInt(maxTime - minTime);
    
    final baseScore = AppConstants.basePointsPerCell[difficulty] ?? 0;
    final score = completed ? (baseScore * 50 * (0.8 + (_random.nextDouble() * 0.4))).toInt() : 0;
    
    final errorCount = _random.nextInt(4); // 0-3 errors
    final hintsUsed = _random.nextInt(3); // 0-2 hints
    
    return GameRecord(
      difficulty: difficulty,
      timeInSeconds: timeInSeconds,
      score: score,
      errorCount: errorCount,
      hintsUsed: hintsUsed,
      completed: completed,
      playedAt: date,
    );
  }

  /// Generate a set of test statistics with realistic-looking data
  static GameStatistics generateTestStatistics() {
    final now = DateTime.now();
    final gameRecords = <GameRecord>[];
    final dailyRecords = <DailyPlayRecord>[];
    
    // Generate daily records for the last 30 days
    for (int daysAgo = 0; daysAgo < 30; daysAgo++) {
      // Skip some days to create streaks
      if (daysAgo > 3 && daysAgo < 6) continue;
      if (daysAgo > 10 && daysAgo < 15) continue;
      
      final date = DateTime(now.year, now.month, now.day - daysAgo);
      final gamesPlayedToday = 1 + _random.nextInt(3); // 1-3 games per day
      
      int completedToday = 0;
      int totalPlayTimeToday = 0;
      
      // Generate games for this day
      for (int i = 0; i < gamesPlayedToday; i++) {
        // Randomize difficulty weighted towards easier difficulties
        final difficultyRandom = _random.nextDouble();
        final difficulty = difficultyRandom < 0.4 ? Difficulty.easy :
                          difficultyRandom < 0.7 ? Difficulty.medium :
                          difficultyRandom < 0.9 ? Difficulty.hard :
                          Difficulty.extreme;
        
        // Most games should be completed (75-90% depending on difficulty)
        final completionChance = difficulty == Difficulty.easy ? 0.9 :
                                difficulty == Difficulty.medium ? 0.85 :
                                difficulty == Difficulty.hard ? 0.8 : 0.75;
                                
        final completed = _random.nextDouble() < completionChance;
        if (completed) completedToday++;
        
        final gameRecord = _generateGameRecord(
          difficulty: difficulty,
          completed: completed,
          date: date,
        );
        
        totalPlayTimeToday += gameRecord.timeInSeconds;
        gameRecords.add(gameRecord);
      }
      
      dailyRecords.add(DailyPlayRecord(
        date: date,
        gamesPlayed: gamesPlayedToday,
        gamesCompleted: completedToday,
        totalPlayTimeInSeconds: totalPlayTimeToday,
      ));
    }
    
    // Pre-calculate achievement values
    final achievements = <String, bool>{};
    final progress = <String, int>{};
    
    // First victory
    achievements['first_victory'] = true;
    
    // Perfect Score (at least one game without hints/errors)
    final hasPerfectGame = gameRecords.any((game) => 
        game.completed && game.errorCount == 0 && game.hintsUsed == 0);
    achievements['perfect_score'] = hasPerfectGame;
    
    // Speed Demon
    final hasSpeedDemon = gameRecords.any((game) =>
        game.completed && game.difficulty == Difficulty.easy && game.timeInSeconds < 300);
    achievements['speed_demon'] = hasSpeedDemon;
    
    // Dedication (7 consecutive days)
    achievements['dedication'] = false; // Will be calculated in addGameRecord
    
    // Total completed puzzles for Master Player and Puzzle Solver
    final completedCount = gameRecords.where((game) => game.completed).length;
    progress['master_player'] = completedCount;
    achievements['master_player'] = completedCount >= 50;
    
    progress['puzzle_solver'] = completedCount;
    achievements['puzzle_solver'] = completedCount >= 100;
    
    // Extreme Champion
    final extremeCount = gameRecords
        .where((game) => game.completed && game.difficulty == Difficulty.extreme)
        .length;
    progress['extreme_champion'] = extremeCount;
    achievements['extreme_champion'] = extremeCount >= 10;
    
    // Time Master
    final totalPlayTime = gameRecords.fold(0, (sum, game) => sum + game.timeInSeconds);
    final totalHours = totalPlayTime / 3600;
    progress['time_master'] = (totalHours * 100).toInt();
    achievements['time_master'] = totalHours >= 24;
    
    return GameStatistics(
      gameRecords: gameRecords,
      dailyRecords: dailyRecords,
      achievements: achievements,
      achievementProgress: progress,
    );
  }
  
  /// Save test data to local storage
  static Future<bool> saveTestData() async {
    final testData = generateTestStatistics();
    return await StatisticsService.saveStatistics(testData);
  }
}
