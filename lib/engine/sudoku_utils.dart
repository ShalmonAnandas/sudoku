import '../constants/app_constants.dart';
import '../models/models.dart';

/// Utility functions for Sudoku board operations
class SudokuUtils {
  /// Check if a value placement at the given position is valid
  static bool isValidPlacement(SudokuBoard board, int row, int col, int value) {
    if (value < 1 || value > 9) return false;
    
    // Check row
    for (int c = 0; c < AppConstants.boardSize; c++) {
      if (c != col && board.getCell(row, c).value == value) {
        return false;
      }
    }
    
    // Check column
    for (int r = 0; r < AppConstants.boardSize; r++) {
      if (r != row && board.getCell(r, col).value == value) {
        return false;
      }
    }
    
    // Check 3x3 box
    final boxStartRow = (row ~/ AppConstants.boxSize) * AppConstants.boxSize;
    final boxStartCol = (col ~/ AppConstants.boxSize) * AppConstants.boxSize;
    
    for (int r = boxStartRow; r < boxStartRow + AppConstants.boxSize; r++) {
      for (int c = boxStartCol; c < boxStartCol + AppConstants.boxSize; c++) {
        if ((r != row || c != col) && board.getCell(r, c).value == value) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Get all possible values for a given position
  static Set<int> getPossibleValues(SudokuBoard board, int row, int col) {
    final possible = <int>{1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    // Remove values in the same row
    for (int c = 0; c < AppConstants.boardSize; c++) {
      final value = board.getCell(row, c).value;
      if (value != 0) possible.remove(value);
    }
    
    // Remove values in the same column
    for (int r = 0; r < AppConstants.boardSize; r++) {
      final value = board.getCell(r, col).value;
      if (value != 0) possible.remove(value);
    }
    
    // Remove values in the same 3x3 box
    final boxStartRow = (row ~/ AppConstants.boxSize) * AppConstants.boxSize;
    final boxStartCol = (col ~/ AppConstants.boxSize) * AppConstants.boxSize;
    
    for (int r = boxStartRow; r < boxStartRow + AppConstants.boxSize; r++) {
      for (int c = boxStartCol; c < boxStartCol + AppConstants.boxSize; c++) {
        final value = board.getCell(r, c).value;
        if (value != 0) possible.remove(value);
      }
    }
    
    return possible;
  }
  
  /// Check if the board has any conflicts
  static bool hasConflicts(SudokuBoard board) {
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.hasValue && !isValidPlacement(board, row, col, cell.value)) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Get all positions with conflicts
  static Set<Position> getConflictPositions(SudokuBoard board) {
    final conflicts = <Position>{};
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.hasValue && !isValidPlacement(board, row, col, cell.value)) {
          conflicts.add(Position(row, col));
        }
      }
    }
    
    return conflicts;
  }
  
  /// Update board with validation status for all cells
  static SudokuBoard updateValidationStatus(SudokuBoard board) {
    final conflicts = getConflictPositions(board);
    final newGrid = <List<SudokuCell>>[];
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      final newRow = <SudokuCell>[];
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        final isValid = !conflicts.contains(Position(row, col));
        newRow.add(cell.copyWith(isValid: isValid));
      }
      newGrid.add(newRow);
    }
    
    return board.copyWith(grid: newGrid);
  }
  
  /// Clear all selections and highlights from the board
  static SudokuBoard clearSelections(SudokuBoard board) {
    final newGrid = <List<SudokuCell>>[];
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      final newRow = <SudokuCell>[];
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        newRow.add(cell.copyWith(
          isSelected: false,
          isHighlighted: false,
        ));
      }
      newGrid.add(newRow);
    }
    
    return board.copyWith(grid: newGrid);
  }
  
  /// Select a cell and highlight related cells
  static SudokuBoard selectCell(SudokuBoard board, int row, int col) {
    final selectedCell = board.getCell(row, col);
    final highlightValue = selectedCell.hasValue ? selectedCell.value : 0;
    final newGrid = <List<SudokuCell>>[];
    
    for (int r = 0; r < AppConstants.boardSize; r++) {
      final newRow = <SudokuCell>[];
      for (int c = 0; c < AppConstants.boardSize; c++) {
        final cell = board.getCell(r, c);
        final isSelected = r == row && c == col;
        final isHighlighted = !isSelected && 
            highlightValue > 0 && 
            cell.value == highlightValue;
        
        newRow.add(cell.copyWith(
          isSelected: isSelected,
          isHighlighted: isHighlighted,
        ));
      }
      newGrid.add(newRow);
    }
    
    return board.copyWith(grid: newGrid);
  }
  
  /// Get a hint for the current board state
  static Position? getHint(SudokuBoard board) {
    // Find a cell with only one possible value (naked single)
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty) {
          final possible = getPossibleValues(board, row, col);
          if (possible.length == 1) {
            return Position(row, col);
          }
        }
      }
    }
    
    // Find the cell with the fewest possibilities
    Position? bestPosition;
    int minPossibilities = 10;
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty) {
          final possible = getPossibleValues(board, row, col);
          if (possible.length < minPossibilities) {
            minPossibilities = possible.length;
            bestPosition = Position(row, col);
          }
        }
      }
    }
    
    return bestPosition;
  }
  
  /// Get the correct value for a position (for hints)
  static int? getCorrectValue(SudokuBoard board, int row, int col) {
    final possible = getPossibleValues(board, row, col);
    if (possible.length == 1) {
      return possible.first;
    }
    return null;
  }
  
  /// Check if the board is solvable
  static bool isSolvable(SudokuBoard board) {
    // Create a copy for solving
    final testBoard = board.copyWith();
    return _solveBoardBacktrack(testBoard) != null;
  }
  
  /// Solve the board using backtracking (for validation)
  static SudokuBoard? _solveBoardBacktrack(SudokuBoard board) {
    // Find first empty cell
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (board.getCell(row, col).isEmpty) {
          // Try each possible value
          final possible = getPossibleValues(board, row, col);
          for (final value in possible) {
            final cell = board.getCell(row, col).setValue(value);
            final newBoard = board.setCell(row, col, cell);
            
            // Recursively solve
            final solved = _solveBoardBacktrack(newBoard);
            if (solved != null) {
              return solved;
            }
          }
          
          // No valid value found, backtrack
          return null;
        }
      }
    }
    
    // All cells filled, check if valid
    return board.isValid ? board : null;
  }
  
  /// Convert board to a simple 2D array representation
  static List<List<int>> boardToArray(SudokuBoard board) {
    return List.generate(
      AppConstants.boardSize,
      (row) => List.generate(
        AppConstants.boardSize,
        (col) => board.getCell(row, col).value,
      ),
    );
  }
  
  /// Create board from a 2D array representation
  static SudokuBoard arrayToBoard(
    List<List<int>> array, 
    Difficulty difficulty, {
    String? puzzleId,
  }) {
    final grid = <List<SudokuCell>>[];
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      final rowCells = <SudokuCell>[];
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final value = array[row][col];
        final cell = value == 0 
            ? const SudokuCell.empty()
            : SudokuCell.clue(value);
        rowCells.add(cell);
      }
      grid.add(rowCells);
    }
    
    return SudokuBoard(
      grid: grid,
      difficulty: difficulty,
      puzzleId: puzzleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
  }
}
