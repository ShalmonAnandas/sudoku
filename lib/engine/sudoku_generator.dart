import 'dart:math';
import '../constants/app_constants.dart';
import '../models/models.dart';
import 'sudoku_utils.dart';

/// Generates complete and valid Sudoku puzzles using backtracking algorithm
class SudokuGenerator {
  static final Random _random = Random();
  
  /// Generate a complete, valid Sudoku board
  static SudokuBoard generateCompleteBoard() {
    final board = SudokuBoard.empty();
    final completeBoard = _fillBoardBacktrack(board);
    
    if (completeBoard == null) {
      // Fallback: generate again if failed
      return generateCompleteBoard();
    }
    
    return completeBoard;
  }
  
  /// Generate a puzzle with the specified difficulty
  static SudokuBoard generatePuzzle(Difficulty difficulty) {
    // Start with a complete board
    final completeBoard = generateCompleteBoard();
    
    // Create a copy to modify (this will be our puzzle)
    var puzzleBoard = completeBoard.copyWith();
    
    // Store the complete solution as original grid
    final originalGrid = _copyGrid(completeBoard.grid);
    
    // Remove cells based on difficulty
    final targetClues = AppConstants.difficultyClues[difficulty] ?? 35;
    puzzleBoard = _removeCells(puzzleBoard, targetClues);
    
    return puzzleBoard.copyWith(
      difficulty: difficulty,
      originalGrid: originalGrid,
      puzzleId: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Fill a board using backtracking algorithm
  static SudokuBoard? _fillBoardBacktrack(SudokuBoard board) {
    // Find first empty cell
    Position? emptyPos;
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (board.getCell(row, col).isEmpty) {
          emptyPos = Position(row, col);
          break;
        }
      }
      if (emptyPos != null) break;
    }
    
    // No empty cells found - board is complete
    if (emptyPos == null) {
      return board;
    }
    
    // Try numbers 1-9 in random order for variety
    final numbers = List.generate(9, (i) => i + 1);
    numbers.shuffle(_random);
    
    for (final num in numbers) {
      if (SudokuUtils.isValidPlacement(board, emptyPos.row, emptyPos.col, num)) {
        // Place the number
        final cell = SudokuCell.clue(num);
        final newBoard = board.setCell(emptyPos.row, emptyPos.col, cell);
        
        // Recursively fill the rest
        final result = _fillBoardBacktrack(newBoard);
        if (result != null) {
          return result;
        }
      }
    }
    
    // No valid number found, backtrack
    return null;
  }
  
  /// Remove cells from a complete board to create a puzzle
  static SudokuBoard _removeCells(SudokuBoard board, int targetClues) {
    final totalCells = AppConstants.totalCells;
    final cellsToRemove = totalCells - targetClues;
    
    // Create list of all positions
    final positions = <Position>[];
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        positions.add(Position(row, col));
      }
    }
    
    // Shuffle positions for random removal
    positions.shuffle(_random);
    
    var currentBoard = board;
    int removed = 0;
    
    for (final pos in positions) {
      if (removed >= cellsToRemove) break;
      
      final currentCell = currentBoard.getCell(pos.row, pos.col);
      if (!currentCell.hasValue) continue;
      
      // Try removing this cell
      final emptyCell = const SudokuCell.empty();
      final testBoard = currentBoard.setCell(pos.row, pos.col, emptyCell);
      
      // Check if puzzle still has unique solution
      if (_hasUniqueSolution(testBoard)) {
        currentBoard = testBoard;
        removed++;
      }
      
      // Add some randomness - sometimes skip cells even if they could be removed
      // This helps create more interesting puzzle patterns
      if (_random.nextDouble() < 0.1) {
        continue;
      }
    }
    
    return currentBoard;
  }
  
  /// Check if a puzzle has a unique solution
  static bool _hasUniqueSolution(SudokuBoard board) {
    int solutionCount = 0;
    _countSolutions(board, (count) => solutionCount = count);
    return solutionCount == 1;
  }
  
  /// Count the number of solutions for a puzzle (stops at 2 for efficiency)
  static void _countSolutions(SudokuBoard board, Function(int) callback) {
    int count = 0;
    _solveBoardCount(board, (found) {
      count++;
      if (count >= 2) {
        callback(count);
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    callback(count);
  }
  
  /// Solve board and count solutions (helper for uniqueness checking)
  static bool _solveBoardCount(SudokuBoard board, bool Function(bool) callback) {
    // Find first empty cell
    Position? emptyPos;
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (board.getCell(row, col).isEmpty) {
          emptyPos = Position(row, col);
          break;
        }
      }
      if (emptyPos != null) break;
    }
    
    // No empty cells - found a solution
    if (emptyPos == null) {
      return callback(true);
    }
    
    // Try each possible value
    final possibleValues = SudokuUtils.getPossibleValues(
      board, 
      emptyPos.row, 
      emptyPos.col,
    );
    
    for (final value in possibleValues) {
      final cell = SudokuCell.clue(value);
      final newBoard = board.setCell(emptyPos.row, emptyPos.col, cell);
      
      if (!_solveBoardCount(newBoard, callback)) {
        return false; // Stop if callback returned false
      }
    }
    
    return true;
  }
  
  /// Create a deep copy of a grid
  static List<List<SudokuCell>> _copyGrid(List<List<SudokuCell>> grid) {
    return List.generate(
      AppConstants.boardSize,
      (row) => List.generate(
        AppConstants.boardSize,
        (col) => grid[row][col],
      ),
    );
  }
  
  /// Generate a puzzle with specific pattern (for variety)
  static SudokuBoard generatePatternPuzzle(Difficulty difficulty, PuzzlePattern pattern) {
    switch (pattern) {
      case PuzzlePattern.symmetric:
        return _generateSymmetricPuzzle(difficulty);
      case PuzzlePattern.minimal:
        return _generateMinimalPuzzle(difficulty);
      case PuzzlePattern.diagonal:
        return _generateDiagonalPuzzle(difficulty);
      default:
        return generatePuzzle(difficulty);
    }
  }
  
  /// Generate a symmetric puzzle
  static SudokuBoard _generateSymmetricPuzzle(Difficulty difficulty) {
    final completeBoard = generateCompleteBoard();
    var puzzleBoard = completeBoard.copyWith();
    
    final targetClues = AppConstants.difficultyClues[difficulty] ?? 35;
    final cellsToRemove = AppConstants.totalCells - targetClues;
    
    // Create symmetric pairs
    final positions = <Position>[];
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        // Only add if we haven't added its symmetric pair
        final symRow = AppConstants.boardSize - 1 - row;
        final symCol = AppConstants.boardSize - 1 - col;
        
        if (row <= symRow && col <= symCol) {
          positions.add(Position(row, col));
        }
      }
    }
    
    positions.shuffle(_random);
    
    int removed = 0;
    for (final pos in positions) {
      if (removed >= cellsToRemove) break;
      
      final symRow = AppConstants.boardSize - 1 - pos.row;
      final symCol = AppConstants.boardSize - 1 - pos.col;
      
      // Remove both symmetric cells
      final emptyCell = const SudokuCell.empty();
      var testBoard = puzzleBoard.setCell(pos.row, pos.col, emptyCell);
      
      if (pos.row != symRow || pos.col != symCol) {
        testBoard = testBoard.setCell(symRow, symCol, emptyCell);
      }
      
      if (_hasUniqueSolution(testBoard)) {
        puzzleBoard = testBoard;
        removed += (pos.row == symRow && pos.col == symCol) ? 1 : 2;
      }
    }
    
    return puzzleBoard.copyWith(
      difficulty: difficulty,
      originalGrid: _copyGrid(completeBoard.grid),
    );
  }
  
  /// Generate a minimal puzzle (fewest clues possible)
  static SudokuBoard _generateMinimalPuzzle(Difficulty difficulty) {
    // For minimal puzzles, try to remove as many cells as possible
    // while maintaining uniqueness
    final completeBoard = generateCompleteBoard();
    var puzzleBoard = completeBoard.copyWith();
    
    final positions = <Position>[];
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        positions.add(Position(row, col));
      }
    }
    
    positions.shuffle(_random);
    
    for (final pos in positions) {
      final emptyCell = const SudokuCell.empty();
      final testBoard = puzzleBoard.setCell(pos.row, pos.col, emptyCell);
      
      if (_hasUniqueSolution(testBoard)) {
        puzzleBoard = testBoard;
      }
    }
    
    return puzzleBoard.copyWith(
      difficulty: difficulty,
      originalGrid: _copyGrid(completeBoard.grid),
    );
  }
  
  /// Generate a puzzle with diagonal emphasis
  static SudokuBoard _generateDiagonalPuzzle(Difficulty difficulty) {
    final completeBoard = generateCompleteBoard();
    var puzzleBoard = completeBoard.copyWith();
    
    final targetClues = AppConstants.difficultyClues[difficulty] ?? 35;
    
    // Prefer keeping diagonal cells
    final diagonalPositions = <Position>[];
    final otherPositions = <Position>[];
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (row == col || row + col == AppConstants.boardSize - 1) {
          diagonalPositions.add(Position(row, col));
        } else {
          otherPositions.add(Position(row, col));
        }
      }
    }
    
    // Shuffle other positions for removal
    otherPositions.shuffle(_random);
    
    int removed = 0;
    final cellsToRemove = AppConstants.totalCells - targetClues;
    
    // Remove from non-diagonal cells first
    for (final pos in otherPositions) {
      if (removed >= cellsToRemove) break;
      
      final emptyCell = const SudokuCell.empty();
      final testBoard = puzzleBoard.setCell(pos.row, pos.col, emptyCell);
      
      if (_hasUniqueSolution(testBoard)) {
        puzzleBoard = testBoard;
        removed++;
      }
    }
    
    return puzzleBoard.copyWith(
      difficulty: difficulty,
      originalGrid: _copyGrid(completeBoard.grid),
    );
  }
}

/// Different puzzle generation patterns
enum PuzzlePattern {
  standard,
  symmetric,
  minimal,
  diagonal,
}
