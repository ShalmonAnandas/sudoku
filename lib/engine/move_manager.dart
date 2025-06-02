import '../models/models.dart';
import 'sudoku_utils.dart';

/// Manages move history and undo/redo functionality
class MoveManager {
  static const int maxHistorySize = 100;
  
  /// Add a move to the history
  static GameState addMove(GameState gameState, SudokuMove move) {
    final newHistory = List<SudokuMove>.from(gameState.moveHistory);
    
    // Add the move to history
    newHistory.add(move);
    
    // Limit history size
    if (newHistory.length > maxHistorySize) {
      newHistory.removeAt(0);
    }
    
    // Clear redo history when a new move is made
    return gameState.copyWith(
      moveHistory: newHistory,
      redoHistory: [],
      moveCount: gameState.moveCount + 1,
    );
  }
  
  /// Undo the last move
  static GameState undoMove(GameState gameState) {
    if (!gameState.canUndo) return gameState;
    
    final lastMove = gameState.moveHistory.last;
    final newHistory = List<SudokuMove>.from(gameState.moveHistory)..removeLast();
    final newRedoHistory = List<SudokuMove>.from(gameState.redoHistory)..add(lastMove);
    
    // Revert the move on the board
    final currentCell = gameState.board.getCellAt(lastMove.position);
    final revertedCell = currentCell.copyWith(
      value: lastMove.previousValue,
      notes: lastMove.previousNotes,
    );
    
    final newBoard = gameState.board.setCellAt(lastMove.position, revertedCell);
    final validatedBoard = SudokuUtils.updateValidationStatus(newBoard);
    
    return gameState.copyWith(
      board: validatedBoard,
      moveHistory: newHistory,
      redoHistory: newRedoHistory,
    );
  }
  
  /// Redo the last undone move
  static GameState redoMove(GameState gameState) {
    if (!gameState.canRedo) return gameState;
    
    final moveToRedo = gameState.redoHistory.last;
    final newRedoHistory = List<SudokuMove>.from(gameState.redoHistory)..removeLast();
    final newHistory = List<SudokuMove>.from(gameState.moveHistory)..add(moveToRedo);
    
    // Apply the move to the board
    final currentCell = gameState.board.getCellAt(moveToRedo.position);
    final redoneCell = currentCell.copyWith(
      value: moveToRedo.newValue,
      notes: moveToRedo.newNotes,
    );
    
    final newBoard = gameState.board.setCellAt(moveToRedo.position, redoneCell);
    final validatedBoard = SudokuUtils.updateValidationStatus(newBoard);
    
    return gameState.copyWith(
      board: validatedBoard,
      moveHistory: newHistory,
      redoHistory: newRedoHistory,
      moveCount: gameState.moveCount + 1,
    );
  }
  
  /// Clear all move history
  static GameState clearHistory(GameState gameState) {
    return gameState.copyWith(
      moveHistory: [],
      redoHistory: [],
    );
  }
  
  /// Get the last move made
  static SudokuMove? getLastMove(GameState gameState) {
    return gameState.moveHistory.isNotEmpty ? gameState.moveHistory.last : null;
  }
  
  /// Get move count for a specific position
  static int getMoveCountAt(GameState gameState, Position position) {
    return gameState.moveHistory
        .where((move) => move.position == position)
        .length;
  }
}
