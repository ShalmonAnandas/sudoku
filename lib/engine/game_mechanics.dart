import 'dart:async';
import '../constants/app_constants.dart';
import '../models/models.dart';
import 'sudoku_solver.dart';
import 'sudoku_generator.dart';
import 'performance_metrics.dart';

/// Enhanced game mechanics with advanced scoring and validation
class GameMechanics {
  static Timer? _gameTimer;
  
  /// Start a new game with the specified difficulty
  static GameState startNewGame(Difficulty difficulty) {
    // Generate a new puzzle
    final puzzle = SudokuGenerator.generatePuzzle(difficulty);
    
    // Create initial game state
    final gameState = GameState.newGame(puzzle);
    
    // Start the timer
    startTimer(gameState);
    
    return gameState;
  }
  
  /// Start the game timer
  static void startTimer(GameState gameState) {
    _gameTimer?.cancel();
    
    if (!gameState.isTimerRunning) return;
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.isTimerRunning && !gameState.isPaused) {
        // Timer update should be handled by the provider/state management
        // This is just a reference for how timing works
      }
    });
  }
  
  /// Stop the game timer
  static void stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }
  
  /// Calculate score based on multiple factors
  static int calculateScore(GameState gameState, bool isCorrectMove) {
    if (!gameState.board.difficulty.hasScoring) return 0;
    
    final basePoints = AppConstants.basePointsPerCell[gameState.board.difficulty] ?? 0;
    var points = basePoints;
    
    if (isCorrectMove) {
      // Time bonus: faster moves get more points
      final timeMultiplier = _getTimeMultiplier(gameState.elapsedSeconds);
      points = (points * timeMultiplier).round();
      
      // Consecutive correct moves bonus
      points += _getConsecutiveBonus(gameState);
      
      // Difficulty multiplier
      points = (points * _getDifficultyMultiplier(gameState.board.difficulty)).round();
      
      // Hints penalty
      final hintPenalty = gameState.hintsUsed * 50;
      points = (points - hintPenalty).clamp(0, double.infinity).round();
      
    } else {
      // Penalty for wrong moves
      points = -basePoints;
    }
    
    return points;
  }
  
  /// Calculate final score with time bonus
  static int calculateFinalScore(GameState gameState) {
    var finalScore = gameState.score;
    
    if (!gameState.board.difficulty.hasScoring) return 0;
    
    // Time bonus for completing under target time
    final threshold = AppConstants.timeBonusThresholds[gameState.board.difficulty] ?? 0;
    if (threshold > 0 && gameState.elapsedSeconds < threshold) {
      final timeBonus = (threshold - gameState.elapsedSeconds) * 10;
      finalScore += timeBonus;
    }
    
    // Completion bonus
    final completionBonus = _getCompletionBonus(gameState.board.difficulty);
    finalScore += completionBonus;
    
    // Perfect game bonus (no errors, no hints)
    if (gameState.errorsCount == 0 && gameState.hintsUsed == 0) {
      finalScore += _getPerfectGameBonus(gameState.board.difficulty);
    }
    
    return finalScore;
  }
    /// Validate a move and provide feedback
  static MoveValidation validateMove(
    SudokuBoard board, 
    int row, 
    int col, 
    int value,
  ) {
    final cell = board.getCell(row, col);
    
    // Can't modify fixed clues
    if (cell.isFixed) {
      return MoveValidation(
        isValid: false,
        isCorrect: false,
        conflictType: ConflictType.fixedCell,
        conflictPositions: [],
        message: 'Cannot modify a given clue',
      );
    }
    
    // Empty value is always valid for clearing
    if (value == 0) {
      return MoveValidation(
        isValid: true,
        isCorrect: true,
        conflictType: ConflictType.none,
        conflictPositions: [],
        message: 'Cell cleared',
      );
    }
    
    // Check for conflicts
    final conflicts = _findConflicts(board, row, col, value);
    
    if (conflicts.isNotEmpty) {
      final conflictType = _determineConflictType(board, row, col, value);
      return MoveValidation(
        isValid: true, // Allow the move even if it has conflicts
        isCorrect: false, // But mark it as incorrect
        conflictType: conflictType,
        conflictPositions: conflicts,
        message: _getConflictMessage(conflictType, value),
      );
    }
    
    return MoveValidation(
      isValid: true,
      isCorrect: true,
      conflictType: ConflictType.none,
      conflictPositions: [],
      message: 'Good move!',
    );
  }
  
  /// Get an intelligent hint based on current board state
  static GameHint? getIntelligentHint(GameState gameState) {
    if (!gameState.canUseHint) return null;
    
    final hint = SudokuSolver.getHint(gameState.board);
    if (hint == null) return null;
    
    return GameHint(
      position: hint.position,
      value: hint.value,
      technique: hint.technique,
      description: hint.description,
      difficulty: _getHintDifficulty(hint.technique),
      affectedCells: hint.affectedCells,
    );
  }
  
  /// Check if the game is completed and valid
  static bool isGameCompleted(SudokuBoard board) {
    return board.isComplete && board.isValid;
  }
    /// Get game statistics
  static GamePerformance getGameStatistics(GameState gameState) {
    final accuracy = gameState.moveCount > 0 
        ? ((gameState.moveCount - gameState.errorsCount) / gameState.moveCount * 100)
        : 0.0;
    
    return GamePerformance(
      totalMoves: gameState.moveCount,
      correctMoves: gameState.moveCount - gameState.errorsCount,
      errorCount: gameState.errorsCount,
      hintsUsed: gameState.hintsUsed,
      timeElapsed: gameState.elapsedSeconds,
      accuracy: accuracy,
      score: gameState.score,
      difficulty: gameState.board.difficulty,
      completionPercentage: gameState.completionPercentage,
    );
  }
  
  /// Get performance rating
  static PerformanceRating getPerformanceRating(GameState gameState) {
    if (!gameState.isCompleted) return PerformanceRating.incomplete;
    
    final statistics = getGameStatistics(gameState);
    
    // Perfect game
    if (statistics.errorCount == 0 && statistics.hintsUsed == 0) {
      return PerformanceRating.perfect;
    }
    
    // Excellent (high accuracy, few errors)
    if (statistics.accuracy >= 90 && statistics.errorCount <= 2) {
      return PerformanceRating.excellent;
    }
    
    // Good (decent accuracy)
    if (statistics.accuracy >= 75 && statistics.errorCount <= 5) {
      return PerformanceRating.good;
    }
    
    // Average
    if (statistics.accuracy >= 60) {
      return PerformanceRating.average;
    }
    
    // Needs improvement
    return PerformanceRating.needsImprovement;
  }
  
  // Private helper methods
  static double _getTimeMultiplier(int elapsedSeconds) {
    // Faster moves get higher multiplier (up to 2x for very fast moves)
    if (elapsedSeconds < 300) return 2.0; // Under 5 minutes
    if (elapsedSeconds < 600) return 1.5; // Under 10 minutes
    if (elapsedSeconds < 1200) return 1.2; // Under 20 minutes
    return 1.0;
  }
    static int _getConsecutiveBonus(GameState gameState) {
    // Bonus for consecutive correct moves (simplified)
    final moveHistory = gameState.moveHistory;
    final recentMoves = moveHistory.length > 5 
        ? moveHistory.sublist(moveHistory.length - 5) 
        : moveHistory;
    if (recentMoves.length >= 3) {
      return 25; // Bonus for being on a streak
    }
    return 0;
  }
  
  static double _getDifficultyMultiplier(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
      case Difficulty.extreme:
        return 0.0; // No scoring for extreme
    }
  }
  
  static int _getCompletionBonus(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 500;
      case Difficulty.medium:
        return 750;
      case Difficulty.hard:
        return 1000;
      case Difficulty.extreme:
        return 0;
    }
  }
  
  static int _getPerfectGameBonus(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 1000;
      case Difficulty.medium:
        return 2000;
      case Difficulty.hard:
        return 3000;
      case Difficulty.extreme:
        return 0;
    }
  }
  
  static List<Position> _findConflicts(SudokuBoard board, int row, int col, int value) {
    final conflicts = <Position>[];
    
    // Check row conflicts
    for (int c = 0; c < AppConstants.boardSize; c++) {
      if (c != col && board.getCell(row, c).value == value) {
        conflicts.add(Position(row, c));
      }
    }
    
    // Check column conflicts
    for (int r = 0; r < AppConstants.boardSize; r++) {
      if (r != row && board.getCell(r, col).value == value) {
        conflicts.add(Position(r, col));
      }
    }
    
    // Check box conflicts
    final boxStartRow = (row ~/ 3) * 3;
    final boxStartCol = (col ~/ 3) * 3;
    
    for (int r = boxStartRow; r < boxStartRow + 3; r++) {
      for (int c = boxStartCol; c < boxStartCol + 3; c++) {
        if ((r != row || c != col) && board.getCell(r, c).value == value) {
          conflicts.add(Position(r, c));
        }
      }
    }
    
    return conflicts;
  }
  
  static ConflictType _determineConflictType(SudokuBoard board, int row, int col, int value) {
    // Check row conflicts
    for (int c = 0; c < AppConstants.boardSize; c++) {
      if (c != col && board.getCell(row, c).value == value) {
        return ConflictType.row;
      }
    }
    
    // Check column conflicts
    for (int r = 0; r < AppConstants.boardSize; r++) {
      if (r != row && board.getCell(r, col).value == value) {
        return ConflictType.column;
      }
    }
    
    // Must be box conflict
    return ConflictType.box;
  }
  
  static String _getConflictMessage(ConflictType type, int value) {
    switch (type) {
      case ConflictType.row:
        return '$value already exists in this row';
      case ConflictType.column:
        return '$value already exists in this column';
      case ConflictType.box:
        return '$value already exists in this box';
      case ConflictType.fixedCell:
        return 'Cannot modify a given clue';
      case ConflictType.none:
        return '';
    }
  }
  
  static HintDifficulty _getHintDifficulty(SolvingTechnique technique) {
    switch (technique) {
      case SolvingTechnique.nakedSingle:
        return HintDifficulty.easy;
      case SolvingTechnique.hiddenSingle:
        return HintDifficulty.medium;
      case SolvingTechnique.pointingPair:
      case SolvingTechnique.nakedPair:
        return HintDifficulty.hard;
      case SolvingTechnique.hiddenPair:
        return HintDifficulty.expert;
      case SolvingTechnique.guessing:
        return HintDifficulty.guess;
    }
  }
}

/// Validation result for a move
class MoveValidation {
  final bool isValid;
  final bool isCorrect;
  final ConflictType conflictType;
  final List<Position> conflictPositions;
  final String message;
  
  const MoveValidation({
    required this.isValid,
    required this.isCorrect,
    required this.conflictType,
    required this.conflictPositions,
    required this.message,
  });
}

/// Enhanced hint with technique information
class GameHint {
  final Position position;
  final int value;
  final SolvingTechnique technique;
  final String description;
  final HintDifficulty difficulty;
  final List<Position> affectedCells;
  
  const GameHint({
    required this.position,
    required this.value,
    required this.technique,
    required this.description,
    required this.difficulty,
    required this.affectedCells,
  });
}

/// Game statistics for tracking performance
class GameStatistics {
  final int totalMoves;
  final int correctMoves;
  final int errorCount;
  final int hintsUsed;
  final int timeElapsed;
  final double accuracy;
  final int score;
  final Difficulty difficulty;
  final double completionPercentage;
  
  const GameStatistics({
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

/// Types of conflicts
enum ConflictType {
  none,
  row,
  column,
  box,
  fixedCell,
}

/// Hint difficulty levels
enum HintDifficulty {
  easy,
  medium,
  hard,
  expert,
  guess,
}

/// Performance rating
enum PerformanceRating {
  incomplete,
  needsImprovement,
  average,
  good,
  excellent,
  perfect,
}
