import '../constants/app_constants.dart';

/// Game performance statistics for a single game
class GamePerformance {
  final int totalMoves;
  final int correctMoves;
  final int errorCount;
  final int hintsUsed;
  final int timeElapsed;
  final double accuracy;
  final int score;
  final Difficulty difficulty;
  final double completionPercentage;
  const GamePerformance({
    required this.totalMoves,
    required this.correctMoves,
    required this.errorCount,
    required this.hintsUsed,
    required this.timeElapsed,
    required this.accuracy,
    required this.score,
    required this.difficulty,
    required this.completionPercentage,
  });
}
