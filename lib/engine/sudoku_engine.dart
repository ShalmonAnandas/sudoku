import '../constants/app_constants.dart';
import '../models/models.dart';
import 'sudoku_utils.dart';
import 'move_manager.dart';

/// Core game engine that handles Sudoku game logic
class SudokuEngine {
  /// Place a value in a cell
  static GameState placeValue(
    GameState gameState, 
    int row, 
    int col, 
    int value,
  ) {
    final cell = gameState.board.getCell(row, col);
    
    // Can't modify fixed clues
    if (cell.isFixed) return gameState;
    
    // Create the move for history
    final move = SudokuMove.value(
      position: Position(row, col),
      previousValue: cell.value,
      newValue: value,
      previousNotes: cell.notes,
      newNotes: const {}, // Clear notes when placing value
    );
    
    // Update the cell
    final newCell = cell.setValue(value);
    final newBoard = gameState.board.setCell(row, col, newCell);
    final validatedBoard = SudokuUtils.updateValidationStatus(newBoard);
    
    // Add move to history
    var newGameState = MoveManager.addMove(gameState, move);
    newGameState = newGameState.copyWith(board: validatedBoard);
    
    // Calculate score if applicable
    if (gameState.board.difficulty.hasScoring && value != 0) {
      final isCorrect = SudokuUtils.isValidPlacement(newBoard, row, col, value);
      if (isCorrect) {
        final points = AppConstants.basePointsPerCell[gameState.board.difficulty] ?? 0;
        newGameState = newGameState.copyWith(score: newGameState.score + points);
      } else {
        newGameState = newGameState.copyWith(errorsCount: newGameState.errorsCount + 1);
      }
    }
    
    // Check if puzzle is completed
    if (validatedBoard.isSolved) {
      newGameState = _completeGame(newGameState);
    }
    
    return newGameState;
  }
  
  /// Clear a cell value
  static GameState clearValue(GameState gameState, int row, int col) {
    return placeValue(gameState, row, col, 0);
  }
  
  /// Toggle a note in a cell
  static GameState toggleNote(
    GameState gameState, 
    int row, 
    int col, 
    int note,
  ) {
    final cell = gameState.board.getCell(row, col);
    
    // Can't add notes to fixed clues or cells with values
    if (cell.isFixed || cell.hasValue) return gameState;
    
    // Create the move for history
    final newNotes = cell.notes.contains(note) 
        ? (Set<int>.from(cell.notes)..remove(note))
        : (Set<int>.from(cell.notes)..add(note));
    
    final move = SudokuMove.notes(
      position: Position(row, col),
      previousNotes: cell.notes,
      newNotes: newNotes,
      value: cell.value,
    );
    
    // Update the cell
    final newCell = cell.updateNotes(newNotes);
    final newBoard = gameState.board.setCell(row, col, newCell);
    
    // Add move to history
    var newGameState = MoveManager.addMove(gameState, move);
    newGameState = newGameState.copyWith(board: newBoard);
    
    return newGameState;
  }
  
  /// Select a cell
  static GameState selectCell(GameState gameState, int row, int col) {
    final newBoard = SudokuUtils.selectCell(gameState.board, row, col);
    return gameState.copyWith(
      board: newBoard,
      selectedPosition: Position(row, col),
    );
  }
  
  /// Clear selection
  static GameState clearSelection(GameState gameState) {
    final newBoard = SudokuUtils.clearSelections(gameState.board);
    return gameState.copyWith(
      board: newBoard,
      clearSelectedPosition: true,
    );
  }
  
  /// Toggle notes mode
  static GameState toggleNotesMode(GameState gameState) {
    return gameState.copyWith(isNotesMode: !gameState.isNotesMode);
  }
  
  /// Use a hint
  static GameState useHint(GameState gameState) {
    if (!gameState.canUseHint) return gameState;
    
    final hintPosition = SudokuUtils.getHint(gameState.board);
    if (hintPosition == null) return gameState;
    
    final correctValue = SudokuUtils.getCorrectValue(
      gameState.board, 
      hintPosition.row, 
      hintPosition.col,
    );
    
    if (correctValue == null) return gameState;
    
    // Place the hint value
    var newGameState = placeValue(
      gameState, 
      hintPosition.row, 
      hintPosition.col, 
      correctValue,
    );
    
    // Update hints used count
    newGameState = newGameState.copyWith(
      hintsUsed: newGameState.hintsUsed + 1,
    );
    
    return newGameState;
  }
  
  /// Pause the game
  static GameState pauseGame(GameState gameState) {
    return gameState.copyWith(
      isPaused: true,
      isTimerRunning: false,
    );
  }
  
  /// Resume the game
  static GameState resumeGame(GameState gameState) {
    return gameState.copyWith(
      isPaused: false,
      isTimerRunning: true,
    );
  }
  
  /// Update the timer
  static GameState updateTimer(GameState gameState, int elapsedSeconds) {
    return gameState.copyWith(elapsedSeconds: elapsedSeconds);
  }
  
  /// Undo last move
  static GameState undoMove(GameState gameState) {
    return MoveManager.undoMove(gameState);
  }
  
  /// Redo last undone move
  static GameState redoMove(GameState gameState) {
    return MoveManager.redoMove(gameState);
  }
  
  /// Complete the game
  static GameState _completeGame(GameState gameState) {
    var finalScore = gameState.score;
    
    // Add time bonus for difficulties that have scoring
    if (gameState.board.difficulty.hasScoring) {
      final threshold = AppConstants.timeBonusThresholds[gameState.board.difficulty] ?? 0;
      if (threshold > 0 && gameState.elapsedSeconds < threshold) {
        final timeBonus = (threshold - gameState.elapsedSeconds) * 10;
        finalScore += timeBonus;
      }
    }
    
    return gameState.copyWith(
      isCompleted: true,
      isTimerRunning: false,
      score: finalScore,
      completedTime: DateTime.now(),
    );
  }
  
  /// Check if a move is valid
  static bool isValidMove(SudokuBoard board, int row, int col, int value) {
    final cell = board.getCell(row, col);
    
    // Can't modify fixed clues
    if (cell.isFixed) return false;
    
    // Empty value is always valid for clearing
    if (value == 0) return true;
    
    // Check if placement is valid
    return SudokuUtils.isValidPlacement(board, row, col, value);
  }
  
  /// Get possible values for a position
  static Set<int> getPossibleValues(SudokuBoard board, int row, int col) {
    return SudokuUtils.getPossibleValues(board, row, col);
  }
  
  /// Validate the current board state
  static GameState validateBoard(GameState gameState) {
    final validatedBoard = SudokuUtils.updateValidationStatus(gameState.board);
    return gameState.copyWith(board: validatedBoard);
  }
  
  /// Reset game to initial state
  static GameState resetGame(GameState gameState) {
    // Create a new board with only the original clues
    final originalBoard = gameState.board.originalGrid ?? gameState.board.grid;
    final resetBoard = gameState.board.copyWith(grid: originalBoard);
    final validatedBoard = SudokuUtils.updateValidationStatus(resetBoard);
    
    return GameState.newGame(validatedBoard);
  }
}
