import 'dart:async';
import '../constants/app_constants.dart';
import '../models/models.dart';
import 'sudoku_engine.dart';
import 'move_manager.dart';
import 'game_mechanics.dart';
import 'performance_metrics.dart' as metrics;

/// Main game controller that integrates all game mechanics
/// This is the primary interface between the UI and the game engine
class GameController {
  GameState _gameState;
  Timer? _timer;
  
  // Game callbacks
  void Function(GameState)? onGameStateChanged;
  void Function(MoveValidation)? onMoveValidated;
  void Function(GameHint)? onHintProvided;
  void Function()? onGameCompleted;
  void Function(String)? onError;
  
  GameController(this._gameState);
  
  /// Current game state
  GameState get gameState => _gameState;
  
  /// Whether the game is active (not paused, not completed)
  bool get isGameActive => _gameState.isTimerRunning && 
                          !_gameState.isPaused && 
                          !_gameState.isCompleted;
  
  /// Start a new game
  void startNewGame(Difficulty difficulty) {
    try {
      // Stop current timer
      _stopTimer();
      
      // Create new game state
      _gameState = GameMechanics.startNewGame(difficulty);
      
      // Start timer
      _startTimer();
      
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Failed to start new game: $e');
    }
  }
  
  /// Resume an existing game
  void resumeGame(GameState gameState) {
    try {
      _gameState = gameState;
      
      if (_gameState.isTimerRunning && !_gameState.isPaused) {
        _startTimer();
      }
      
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Failed to resume game: $e');
    }
  }
    /// Make a move (place a value)
  void makeMove(int row, int col, int value) {
    if (!isGameActive) return;
    
    try {
      // Validate the move
      final validation = GameMechanics.validateMove(_gameState.board, row, col, value);
      onMoveValidated?.call(validation);
      
      if (validation.isValid) {
        // Make the move using the engine
        _gameState = SudokuEngine.placeValue(_gameState, row, col, value);
        
        // Update error count if move is incorrect
        if (!validation.isCorrect && value != 0) {
          _gameState = _gameState.copyWith(
            errorsCount: _gameState.errorsCount + 1,
          );
        }
        
        // Check for game completion only if all cells are valid
        if (GameMechanics.isGameCompleted(_gameState.board)) {
          _completeGame();
        } else {
          _notifyStateChanged();
        }
      }
    } catch (e) {
      onError?.call('Error making move: $e');
    }
  }
  
  /// Add or remove a note
  void toggleNote(int row, int col, int note) {
    if (!isGameActive) return;
    
    try {
      final cell = _gameState.board.getCell(row, col);
      if (cell.isFixed || cell.value != 0) return;
      
      _gameState = SudokuEngine.toggleNote(_gameState, row, col, note);
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Error toggling note: $e');
    }
  }
    /// Clear all notes from a cell
  void clearNotes(int row, int col) {
    if (!isGameActive) return;
    
    try {
      final cell = _gameState.board.getCell(row, col);
      if (cell.isFixed || cell.value != 0) return;
      
      // Clear notes by toggling each existing note
      var newGameState = _gameState;
      for (final note in cell.notes) {
        newGameState = SudokuEngine.toggleNote(newGameState, row, col, note);
      }
      _gameState = newGameState;
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Error clearing notes: $e');
    }
  }
  
  /// Get a hint
  void getHint() {
    if (!_gameState.canUseHint) {
      onError?.call('No hints available');
      return;
    }
    
    try {
      final hint = GameMechanics.getIntelligentHint(_gameState);
      if (hint != null) {
        // Update game state to reflect hint usage
        _gameState = _gameState.copyWith(
          hintsUsed: _gameState.hintsUsed + 1,
        );
        
        onHintProvided?.call(hint);
        _notifyStateChanged();
      } else {
        onError?.call('No hints available for current board state');
      }
    } catch (e) {
      onError?.call('Error getting hint: $e');
    }
  }
  
  /// Undo last move
  void undoMove() {
    if (!_gameState.canUndo) {
      onError?.call('No moves to undo');
      return;
    }
    
    try {
      _gameState = MoveManager.undoMove(_gameState);
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Error undoing move: $e');
    }
  }
  
  /// Redo last undone move
  void redoMove() {
    if (!_gameState.canRedo) {
      onError?.call('No moves to redo');
      return;
    }
    
    try {
      _gameState = MoveManager.redoMove(_gameState);
      _notifyStateChanged();
    } catch (e) {
      onError?.call('Error redoing move: $e');
    }
  }
  
  /// Pause the game
  void pauseGame() {
    if (_gameState.isCompleted) return;
    
    _gameState = _gameState.copyWith(
      isPaused: true,
      isTimerRunning: false,
    );
    _stopTimer();
    _notifyStateChanged();
  }
  
  /// Resume the game
  void resumeGamePlay() {
    if (_gameState.isCompleted) return;
    
    _gameState = _gameState.copyWith(
      isPaused: false,
      isTimerRunning: true,
    );
    _startTimer();
    _notifyStateChanged();
  }  /// Get current game statistics
  metrics.GamePerformance getStatistics() {
    return GameMechanics.getGameStatistics(_gameState);
  }
  
  /// Get performance rating
  PerformanceRating getPerformanceRating() {
    return GameMechanics.getPerformanceRating(_gameState);
  }
  
  /// Dispose resources
  void dispose() {
    _stopTimer();
    onGameStateChanged = null;
    onMoveValidated = null;
    onHintProvided = null;
    onGameCompleted = null;
    onError = null;
  }
  
  // Private methods
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState.isTimerRunning && !_gameState.isPaused) {
        _gameState = _gameState.copyWith(
          elapsedSeconds: _gameState.elapsedSeconds + 1,
        );
        _notifyStateChanged();
      }
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _completeGame() {
    _stopTimer();
    
    final finalScore = GameMechanics.calculateFinalScore(_gameState);
    
    _gameState = _gameState.copyWith(
      isCompleted: true,
      isTimerRunning: false,
      score: finalScore,
    );
    
    onGameCompleted?.call();
    _notifyStateChanged();
  }
  
  void _notifyStateChanged() {
    onGameStateChanged?.call(_gameState);
  }
}
