/// Application-wide constants for the Sudoku game
class AppConstants {
  // Game constants
  static const int boardSize = 9;
  static const int boxSize = 3;
  static const int totalCells = boardSize * boardSize;
  
  // Difficulty settings
  static const Map<Difficulty, int> difficultyClues = {
    Difficulty.easy: 45,
    Difficulty.medium: 35,
    Difficulty.hard: 28,
    Difficulty.extreme: 25,
  };
  
  // Scoring system
  static const Map<Difficulty, int> basePointsPerCell = {
    Difficulty.easy: 10,
    Difficulty.medium: 20,
    Difficulty.hard: 30,
    Difficulty.extreme: 0, // No scoring for extreme
  };
  
  // Time bonuses (in seconds)
  static const Map<Difficulty, int> timeBonusThresholds = {
    Difficulty.easy: 600,    // 10 minutes
    Difficulty.medium: 900,  // 15 minutes
    Difficulty.hard: 1200,   // 20 minutes
    Difficulty.extreme: 0,   // No bonus for extreme
  };
  
  // Game settings
  static const int maxHints = 3;
  static const int maxUndos = 10;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Storage keys
  static const String currentGameKey = 'current_game';
  static const String settingsKey = 'game_settings';
  static const String statisticsKey = 'game_statistics';
}

enum Difficulty {
  easy,
  medium,
  hard,
  extreme,
}

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.extreme:
        return 'Extreme';
    }
  }
  
  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Perfect for beginners';
      case Difficulty.medium:
        return 'A moderate challenge';
      case Difficulty.hard:
        return 'For experienced players';
      case Difficulty.extreme:
        return 'No feedback, ultimate challenge';
    }
  }
  
  bool get hasScoring => this != Difficulty.extreme;
  bool get hasFeedback => this != Difficulty.extreme;
}
