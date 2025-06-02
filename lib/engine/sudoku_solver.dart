import '../constants/app_constants.dart';
import '../models/models.dart';
import 'sudoku_utils.dart';

/// Advanced Sudoku solving techniques and hint system
class SudokuSolver {
  /// Solve a puzzle using multiple techniques
  static SudokuBoard? solvePuzzle(SudokuBoard board) {
    var currentBoard = board.copyWith();
    bool progress = true;
    
    while (progress && !currentBoard.isSolved) {
      progress = false;
      final startingCells = currentBoard.filledCells;
      
      // Try different solving techniques in order of difficulty
      currentBoard = _applyNakedSingles(currentBoard);
      currentBoard = _applyHiddenSingles(currentBoard);
      currentBoard = _applyPointingPairs(currentBoard);
      currentBoard = _applyNakedPairs(currentBoard);
      currentBoard = _applyHiddenPairs(currentBoard);
      
      // If simpler techniques don't work, use backtracking
      if (currentBoard.filledCells == startingCells) {
        final solved = _solveBacktrack(currentBoard);
        return solved;
      }
      
      progress = currentBoard.filledCells > startingCells;
    }
    
    return currentBoard.isSolved ? currentBoard : null;
  }
  
  /// Get the next logical hint using various techniques
  static SudokuHint? getHint(SudokuBoard board) {
    // Try naked singles first (easiest)
    var hint = _findNakedSingle(board);
    if (hint != null) return hint;
    
    // Try hidden singles
    hint = _findHiddenSingle(board);
    if (hint != null) return hint;
    
    // Try pointing pairs
    hint = _findPointingPair(board);
    if (hint != null) return hint;
    
    // Try naked pairs
    hint = _findNakedPair(board);
    if (hint != null) return hint;
    
    // Try hidden pairs
    hint = _findHiddenPair(board);
    if (hint != null) return hint;
    
    // If no logical technique works, suggest guessing
    hint = _findGuessHint(board);
    return hint;
  }
  
  /// Check if a puzzle is solvable
  static bool isSolvable(SudokuBoard board) {
    return solvePuzzle(board) != null;
  }
  
  /// Get difficulty rating based on solving techniques required
  static SolvingDifficulty getDifficultyRating(SudokuBoard board) {
    var testBoard = board.copyWith();
    var requiredTechniques = <SolvingTechnique>[];
    
    while (!testBoard.isSolved) {
      final startingCells = testBoard.filledCells;
      
      // Try techniques in order of difficulty
      if (_hasNakedSingles(testBoard)) {
        requiredTechniques.add(SolvingTechnique.nakedSingle);
        testBoard = _applyNakedSingles(testBoard);
      } else if (_hasHiddenSingles(testBoard)) {
        requiredTechniques.add(SolvingTechnique.hiddenSingle);
        testBoard = _applyHiddenSingles(testBoard);
      } else if (_hasPointingPairs(testBoard)) {
        requiredTechniques.add(SolvingTechnique.pointingPair);
        testBoard = _applyPointingPairs(testBoard);
      } else if (_hasNakedPairs(testBoard)) {
        requiredTechniques.add(SolvingTechnique.nakedPair);
        testBoard = _applyNakedPairs(testBoard);
      } else if (_hasHiddenPairs(testBoard)) {
        requiredTechniques.add(SolvingTechnique.hiddenPair);
        testBoard = _applyHiddenPairs(testBoard);
      } else {
        requiredTechniques.add(SolvingTechnique.guessing);
        break;
      }
      
      // Prevent infinite loop
      if (testBoard.filledCells == startingCells) {
        requiredTechniques.add(SolvingTechnique.guessing);
        break;
      }
    }
    
    // Determine difficulty based on most advanced technique required
    if (requiredTechniques.contains(SolvingTechnique.guessing)) {
      return SolvingDifficulty.extreme;
    } else if (requiredTechniques.contains(SolvingTechnique.hiddenPair) ||
               requiredTechniques.contains(SolvingTechnique.nakedPair)) {
      return SolvingDifficulty.hard;
    } else if (requiredTechniques.contains(SolvingTechnique.pointingPair)) {
      return SolvingDifficulty.medium;
    } else {
      return SolvingDifficulty.easy;
    }
  }
  
  // NAKED SINGLES: Cells with only one possible value
  static SudokuBoard _applyNakedSingles(SudokuBoard board) {
    var currentBoard = board;
    bool changed = true;
    
    while (changed) {
      changed = false;
      
      for (int row = 0; row < AppConstants.boardSize; row++) {
        for (int col = 0; col < AppConstants.boardSize; col++) {
          final cell = currentBoard.getCell(row, col);
          if (cell.isEmpty) {
            final possible = SudokuUtils.getPossibleValues(currentBoard, row, col);
            if (possible.length == 1) {
              final value = possible.first;
              final newCell = SudokuCell.clue(value);
              currentBoard = currentBoard.setCell(row, col, newCell);
              changed = true;
            }
          }
        }
      }
    }
    
    return currentBoard;
  }
  
  static bool _hasNakedSingles(SudokuBoard board) {
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty) {
          final possible = SudokuUtils.getPossibleValues(board, row, col);
          if (possible.length == 1) {
            return true;
          }
        }
      }
    }
    return false;
  }
  
  static SudokuHint? _findNakedSingle(SudokuBoard board) {
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty) {
          final possible = SudokuUtils.getPossibleValues(board, row, col);
          if (possible.length == 1) {
            return SudokuHint(
              position: Position(row, col),
              value: possible.first,
              technique: SolvingTechnique.nakedSingle,
              description: 'This cell can only contain ${possible.first}',
              affectedCells: [Position(row, col)],
            );
          }
        }
      }
    }
    return null;
  }
  
  // HIDDEN SINGLES: Numbers that can only go in one cell in a unit
  static SudokuBoard _applyHiddenSingles(SudokuBoard board) {
    var currentBoard = board;
    bool changed = true;
    
    while (changed) {
      changed = false;
      
      // Check rows
      for (int row = 0; row < AppConstants.boardSize; row++) {
        final result = _findHiddenSingleInRow(currentBoard, row);
        if (result != null) {
          final newCell = SudokuCell.clue(result.value);
          currentBoard = currentBoard.setCell(row, result.col, newCell);
          changed = true;
        }
      }
      
      // Check columns
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final result = _findHiddenSingleInColumn(currentBoard, col);
        if (result != null) {
          final newCell = SudokuCell.clue(result.value);
          currentBoard = currentBoard.setCell(result.row, col, newCell);
          changed = true;
        }
      }
      
      // Check boxes
      for (int box = 0; box < AppConstants.boardSize; box++) {
        final result = _findHiddenSingleInBox(currentBoard, box);
        if (result != null) {
          final newCell = SudokuCell.clue(result.value);
          currentBoard = currentBoard.setCell(result.row, result.col, newCell);
          changed = true;
        }
      }
    }
    
    return currentBoard;
  }
  
  static bool _hasHiddenSingles(SudokuBoard board) {
    // Check rows, columns, and boxes for hidden singles
    for (int i = 0; i < AppConstants.boardSize; i++) {
      if (_findHiddenSingleInRow(board, i) != null) return true;
      if (_findHiddenSingleInColumn(board, i) != null) return true;
      if (_findHiddenSingleInBox(board, i) != null) return true;
    }
    return false;
  }
  
  static SudokuHint? _findHiddenSingle(SudokuBoard board) {
    // Check rows
    for (int row = 0; row < AppConstants.boardSize; row++) {
      final result = _findHiddenSingleInRow(board, row);
      if (result != null) {
        return SudokuHint(
          position: Position(row, result.col),
          value: result.value,
          technique: SolvingTechnique.hiddenSingle,
          description: 'In row ${row + 1}, ${result.value} can only go here',
          affectedCells: _getRowPositions(row),
        );
      }
    }
    
    // Check columns
    for (int col = 0; col < AppConstants.boardSize; col++) {
      final result = _findHiddenSingleInColumn(board, col);
      if (result != null) {
        return SudokuHint(
          position: Position(result.row, col),
          value: result.value,
          technique: SolvingTechnique.hiddenSingle,
          description: 'In column ${col + 1}, ${result.value} can only go here',
          affectedCells: _getColumnPositions(col),
        );
      }
    }
    
    // Check boxes
    for (int box = 0; box < AppConstants.boardSize; box++) {
      final result = _findHiddenSingleInBox(board, box);
      if (result != null) {
        return SudokuHint(
          position: Position(result.row, result.col),
          value: result.value,
          technique: SolvingTechnique.hiddenSingle,
          description: 'In box ${box + 1}, ${result.value} can only go here',
          affectedCells: _getBoxPositions(box),
        );
      }
    }
    
    return null;
  }
  
  // Helper methods for hidden singles
  static ({int value, int col})? _findHiddenSingleInRow(SudokuBoard board, int row) {
    for (int value = 1; value <= 9; value++) {
      final possibleCols = <int>[];
      
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty && SudokuUtils.isValidPlacement(board, row, col, value)) {
          possibleCols.add(col);
        }
      }
      
      if (possibleCols.length == 1) {
        return (value: value, col: possibleCols.first);
      }
    }
    return null;
  }
  
  static ({int value, int row})? _findHiddenSingleInColumn(SudokuBoard board, int col) {
    for (int value = 1; value <= 9; value++) {
      final possibleRows = <int>[];
      
      for (int row = 0; row < AppConstants.boardSize; row++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty && SudokuUtils.isValidPlacement(board, row, col, value)) {
          possibleRows.add(row);
        }
      }
      
      if (possibleRows.length == 1) {
        return (value: value, row: possibleRows.first);
      }
    }
    return null;
  }
  
  static ({int value, int row, int col})? _findHiddenSingleInBox(SudokuBoard board, int boxIndex) {
    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;
    
    for (int value = 1; value <= 9; value++) {
      final possiblePositions = <Position>[];
      
      for (int r = boxRow; r < boxRow + 3; r++) {
        for (int c = boxCol; c < boxCol + 3; c++) {
          final cell = board.getCell(r, c);
          if (cell.isEmpty && SudokuUtils.isValidPlacement(board, r, c, value)) {
            possiblePositions.add(Position(r, c));
          }
        }
      }
      
      if (possiblePositions.length == 1) {
        final pos = possiblePositions.first;
        return (value: value, row: pos.row, col: pos.col);
      }
    }
    return null;
  }
  
  // Placeholder implementations for advanced techniques
  static SudokuBoard _applyPointingPairs(SudokuBoard board) {
    // TODO: Implement pointing pairs technique
    return board;
  }
  
  static bool _hasPointingPairs(SudokuBoard board) {
    // TODO: Implement pointing pairs detection
    return false;
  }
  
  static SudokuHint? _findPointingPair(SudokuBoard board) {
    // TODO: Implement pointing pairs hint
    return null;
  }
  
  static SudokuBoard _applyNakedPairs(SudokuBoard board) {
    // TODO: Implement naked pairs technique
    return board;
  }
  
  static bool _hasNakedPairs(SudokuBoard board) {
    // TODO: Implement naked pairs detection
    return false;
  }
  
  static SudokuHint? _findNakedPair(SudokuBoard board) {
    // TODO: Implement naked pairs hint
    return null;
  }
  
  static SudokuBoard _applyHiddenPairs(SudokuBoard board) {
    // TODO: Implement hidden pairs technique
    return board;
  }
  
  static bool _hasHiddenPairs(SudokuBoard board) {
    // TODO: Implement hidden pairs detection
    return false;
  }
  
  static SudokuHint? _findHiddenPair(SudokuBoard board) {
    // TODO: Implement hidden pairs hint
    return null;
  }
  
  // Fallback: suggest a guess for the cell with fewest possibilities
  static SudokuHint? _findGuessHint(SudokuBoard board) {
    Position? bestPosition;
    int minPossibilities = 10;
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = board.getCell(row, col);
        if (cell.isEmpty) {
          final possible = SudokuUtils.getPossibleValues(board, row, col);
          if (possible.length < minPossibilities && possible.isNotEmpty) {
            minPossibilities = possible.length;
            bestPosition = Position(row, col);
          }
        }
      }
    }
    
    if (bestPosition != null) {
      final possible = SudokuUtils.getPossibleValues(
        board, 
        bestPosition.row, 
        bestPosition.col,
      );
      
      if (possible.isNotEmpty) {
        return SudokuHint(
          position: bestPosition,
          value: possible.first,
          technique: SolvingTechnique.guessing,
          description: 'Try ${possible.first} (one of ${possible.length} possibilities)',
          affectedCells: [bestPosition],
        );
      }
    }
    
    return null;
  }
  
  // Backtracking solver for when logical techniques fail
  static SudokuBoard? _solveBacktrack(SudokuBoard board) {
    // Find first empty cell
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (board.getCell(row, col).isEmpty) {
          final possible = SudokuUtils.getPossibleValues(board, row, col);
          
          for (final value in possible) {
            final cell = SudokuCell.clue(value);
            final newBoard = board.setCell(row, col, cell);
            
            final result = _solveBacktrack(newBoard);
            if (result != null) {
              return result;
            }
          }
          
          return null; // No valid value found
        }
      }
    }
    
    return board; // All cells filled
  }
  
  // Helper methods for getting unit positions
  static List<Position> _getRowPositions(int row) {
    return List.generate(9, (col) => Position(row, col));
  }
  
  static List<Position> _getColumnPositions(int col) {
    return List.generate(9, (row) => Position(row, col));
  }
  
  static List<Position> _getBoxPositions(int boxIndex) {
    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;
    final positions = <Position>[];
    
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        positions.add(Position(r, c));
      }
    }
    
    return positions;
  }
}

/// Represents a hint with solving technique information
class SudokuHint {
  final Position position;
  final int value;
  final SolvingTechnique technique;
  final String description;
  final List<Position> affectedCells;
  
  const SudokuHint({
    required this.position,
    required this.value,
    required this.technique,
    required this.description,
    required this.affectedCells,
  });
}

/// Different solving techniques
enum SolvingTechnique {
  nakedSingle,
  hiddenSingle,
  pointingPair,
  nakedPair,
  hiddenPair,
  guessing,
}

/// Difficulty rating based on solving techniques required
enum SolvingDifficulty {
  easy,
  medium,
  hard,
  extreme,
}
