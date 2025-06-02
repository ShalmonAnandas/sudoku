import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import 'sudoku_board.dart';

/// Represents a move made in the game
class SudokuMove extends Equatable {
  /// Position where the move was made
  final Position position;
  
  /// Previous value at this position
  final int previousValue;
  
  /// New value at this position
  final int newValue;
  
  /// Previous notes at this position
  final Set<int> previousNotes;
  
  /// New notes at this position
  final Set<int> newNotes;
  
  /// Timestamp when the move was made
  final DateTime timestamp;
  
  /// Whether this was a note modification
  final bool isNoteMove;
  
  const SudokuMove({
    required this.position,
    required this.previousValue,
    required this.newValue,
    required this.previousNotes,
    required this.newNotes,
    required this.timestamp,
    this.isNoteMove = false,
  });
  
  /// Create a value move
  factory SudokuMove.value({
    required Position position,
    required int previousValue,
    required int newValue,
    Set<int> previousNotes = const {},
    Set<int> newNotes = const {},
  }) {
    return SudokuMove(
      position: position,
      previousValue: previousValue,
      newValue: newValue,
      previousNotes: previousNotes,
      newNotes: newNotes,
      timestamp: DateTime.now(),
      isNoteMove: false,
    );
  }
  
  /// Create a note move
  factory SudokuMove.notes({
    required Position position,
    required Set<int> previousNotes,
    required Set<int> newNotes,
    int value = 0,
  }) {
    return SudokuMove(
      position: position,
      previousValue: value,
      newValue: value,
      previousNotes: previousNotes,
      newNotes: newNotes,
      timestamp: DateTime.now(),
      isNoteMove: true,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'position': position.toJson(),
    'previousValue': previousValue,
    'newValue': newValue,
    'previousNotes': previousNotes.toList(),
    'newNotes': newNotes.toList(),
    'timestamp': timestamp.toIso8601String(),
    'isNoteMove': isNoteMove,
  };
  
  /// Create from JSON
  factory SudokuMove.fromJson(Map<String, dynamic> json) => SudokuMove(
    position: Position.fromJson(json['position'] as Map<String, dynamic>),
    previousValue: json['previousValue'] as int,
    newValue: json['newValue'] as int,
    previousNotes: Set<int>.from(json['previousNotes'] as List),
    newNotes: Set<int>.from(json['newNotes'] as List),
    timestamp: DateTime.parse(json['timestamp'] as String),
    isNoteMove: json['isNoteMove'] as bool,
  );
  
  @override
  List<Object?> get props => [
        position,
        previousValue,
        newValue,
        previousNotes,
        newNotes,
        timestamp,
        isNoteMove,
      ];
}

/// Represents the complete game state
class GameState extends Equatable {
  /// The current Sudoku board
  final SudokuBoard board;
  
  /// Game timer in seconds
  final int elapsedSeconds;
  
  /// Whether the timer is running
  final bool isTimerRunning;
  
  /// Whether the game is paused
  final bool isPaused;
  
  /// Current score (0 for extreme difficulty)
  final int score;
  
  /// Number of moves made
  final int moveCount;
  
  /// Number of hints used
  final int hintsUsed;
  
  /// Number of errors made
  final int errorsCount;
  
  /// Stack of moves for undo functionality
  final List<SudokuMove> moveHistory;
  
  /// Stack of undone moves for redo functionality
  final List<SudokuMove> redoHistory;
  
  /// Currently selected position
  final Position? selectedPosition;
  
  /// Whether notes mode is active
  final bool isNotesMode;
  
  /// Whether the game is completed
  final bool isCompleted;
  
  /// When the game was started
  final DateTime startTime;
  
  /// When the game was completed (if applicable)
  final DateTime? completedTime;
  
  const GameState({
    required this.board,
    this.elapsedSeconds = 0,
    this.isTimerRunning = false,
    this.isPaused = false,
    this.score = 0,
    this.moveCount = 0,
    this.hintsUsed = 0,
    this.errorsCount = 0,
    this.moveHistory = const [],
    this.redoHistory = const [],
    this.selectedPosition,
    this.isNotesMode = false,
    this.isCompleted = false,
    required this.startTime,
    this.completedTime,
  });
  
  /// Create a new game state
  factory GameState.newGame(SudokuBoard board) {
    return GameState(
      board: board,
      startTime: DateTime.now(),
      isTimerRunning: true,
    );
  }
  
  /// Whether undo is available
  bool get canUndo => moveHistory.isNotEmpty;
  
  /// Whether redo is available
  bool get canRedo => redoHistory.isNotEmpty;
  
  /// Whether hints are available
  bool get canUseHint => hintsUsed < AppConstants.maxHints && 
                         board.difficulty.hasFeedback;
  
  /// Whether the game is in progress
  bool get isInProgress => !isCompleted && !isPaused;
  
  /// Game duration as a formatted string
  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Calculate completion percentage
  double get completionPercentage {
    final totalCells = AppConstants.totalCells;
    final filledCells = board.filledCells;
    return filledCells / totalCells;
  }
  
  /// Copy this state with updated properties
  GameState copyWith({
    SudokuBoard? board,
    int? elapsedSeconds,
    bool? isTimerRunning,
    bool? isPaused,
    int? score,
    int? moveCount,
    int? hintsUsed,
    int? errorsCount,
    List<SudokuMove>? moveHistory,
    List<SudokuMove>? redoHistory,
    Position? selectedPosition,
    bool? clearSelectedPosition,
    bool? isNotesMode,
    bool? isCompleted,
    DateTime? startTime,
    DateTime? completedTime,
    bool? clearCompletedTime,
  }) {
    return GameState(
      board: board ?? this.board,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPaused: isPaused ?? this.isPaused,
      score: score ?? this.score,
      moveCount: moveCount ?? this.moveCount,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      errorsCount: errorsCount ?? this.errorsCount,
      moveHistory: moveHistory ?? this.moveHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      selectedPosition: clearSelectedPosition == true 
          ? null 
          : (selectedPosition ?? this.selectedPosition),
      isNotesMode: isNotesMode ?? this.isNotesMode,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      completedTime: clearCompletedTime == true 
          ? null 
          : (completedTime ?? this.completedTime),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'board': board.toJson(),
    'elapsedSeconds': elapsedSeconds,
    'isTimerRunning': isTimerRunning,
    'isPaused': isPaused,
    'score': score,
    'moveCount': moveCount,
    'hintsUsed': hintsUsed,
    'errorsCount': errorsCount,
    'moveHistory': moveHistory.map((move) => move.toJson()).toList(),
    'redoHistory': redoHistory.map((move) => move.toJson()).toList(),
    'selectedPosition': selectedPosition?.toJson(),
    'isNotesMode': isNotesMode,
    'isCompleted': isCompleted,
    'startTime': startTime.toIso8601String(),
    'completedTime': completedTime?.toIso8601String(),
  };
  
  /// Create from JSON
  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    board: SudokuBoard.fromJson(json['board'] as Map<String, dynamic>),
    elapsedSeconds: json['elapsedSeconds'] as int,
    isTimerRunning: json['isTimerRunning'] as bool,
    isPaused: json['isPaused'] as bool,
    score: json['score'] as int,
    moveCount: json['moveCount'] as int,
    hintsUsed: json['hintsUsed'] as int,
    errorsCount: json['errorsCount'] as int,
    moveHistory: (json['moveHistory'] as List<dynamic>)
        .map((moveJson) => SudokuMove.fromJson(moveJson as Map<String, dynamic>))
        .toList(),
    redoHistory: (json['redoHistory'] as List<dynamic>)
        .map((moveJson) => SudokuMove.fromJson(moveJson as Map<String, dynamic>))
        .toList(),
    selectedPosition: json['selectedPosition'] != null 
        ? Position.fromJson(json['selectedPosition'] as Map<String, dynamic>)
        : null,
    isNotesMode: json['isNotesMode'] as bool,
    isCompleted: json['isCompleted'] as bool,
    startTime: DateTime.parse(json['startTime'] as String),
    completedTime: json['completedTime'] != null 
        ? DateTime.parse(json['completedTime'] as String)
        : null,
  );
  
  @override
  List<Object?> get props => [
        board,
        elapsedSeconds,
        isTimerRunning,
        isPaused,
        score,
        moveCount,
        hintsUsed,
        errorsCount,
        moveHistory,
        redoHistory,
        selectedPosition,
        isNotesMode,
        isCompleted,
        startTime,
        completedTime,
      ];
}
