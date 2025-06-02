import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import 'sudoku_cell.dart';

/// Position in the Sudoku grid
class Position extends Equatable {
  final int row;
  final int col;
  
  const Position(this.row, this.col);
  
  /// Whether this position is valid (within grid bounds)
  bool get isValid => 
      row >= 0 && row < AppConstants.boardSize && 
      col >= 0 && col < AppConstants.boardSize;
  
  /// Get the box index (0-8) for this position
  int get boxIndex => (row ~/ AppConstants.boxSize) * AppConstants.boxSize + (col ~/ AppConstants.boxSize);
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
  };
  
  /// Create from JSON
  factory Position.fromJson(Map<String, dynamic> json) => Position(
    json['row'] as int,
    json['col'] as int,
  );
  
  @override
  List<Object?> get props => [row, col];
  
  @override
  String toString() => 'Position($row, $col)';
}

/// Represents the complete 9x9 Sudoku board
class SudokuBoard extends Equatable {
  /// The 9x9 grid of cells
  final List<List<SudokuCell>> grid;
  
  /// The difficulty level of this puzzle
  final Difficulty difficulty;
  
  /// Unique identifier for this puzzle
  final String puzzleId;
  
  /// When this puzzle was created
  final DateTime createdAt;
  
  /// The original puzzle (with clues only)
  final List<List<SudokuCell>>? originalGrid;
  
  const SudokuBoard({
    required this.grid,
    required this.difficulty,
    required this.puzzleId,
    required this.createdAt,
    this.originalGrid,
  });
  
  /// Create an empty board
  factory SudokuBoard.empty({
    Difficulty difficulty = Difficulty.easy,
    String? puzzleId,
  }) {
    final grid = List.generate(
      AppConstants.boardSize,
      (row) => List.generate(
        AppConstants.boardSize,
        (col) => const SudokuCell.empty(),
      ),
    );
    
    return SudokuBoard(
      grid: grid,
      difficulty: difficulty,
      puzzleId: puzzleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
  }
  
  /// Get a cell at the specified position
  SudokuCell getCell(int row, int col) {
    if (row < 0 || row >= AppConstants.boardSize || 
        col < 0 || col >= AppConstants.boardSize) {
      throw RangeError('Invalid position: ($row, $col)');
    }
    return grid[row][col];
  }
  
  /// Get a cell at the specified position (using Position object)
  SudokuCell getCellAt(Position position) {
    return getCell(position.row, position.col);
  }
  
  /// Set a cell at the specified position
  SudokuBoard setCell(int row, int col, SudokuCell cell) {
    final newGrid = _copyGrid();
    newGrid[row][col] = cell;
    return copyWith(grid: newGrid);
  }
  
  /// Set a cell at the specified position (using Position object)
  SudokuBoard setCellAt(Position position, SudokuCell cell) {
    return setCell(position.row, position.col, cell);
  }
  
  /// Get all cells in a row
  List<SudokuCell> getRow(int row) {
    return List.from(grid[row]);
  }
  
  /// Get all cells in a column
  List<SudokuCell> getColumn(int col) {
    return List.generate(
      AppConstants.boardSize,
      (row) => grid[row][col],
    );
  }
  
  /// Get all cells in a 3x3 box
  List<SudokuCell> getBox(int boxIndex) {
    final boxRow = (boxIndex ~/ AppConstants.boxSize) * AppConstants.boxSize;
    final boxCol = (boxIndex % AppConstants.boxSize) * AppConstants.boxSize;
    
    final cells = <SudokuCell>[];
    for (int r = boxRow; r < boxRow + AppConstants.boxSize; r++) {
      for (int c = boxCol; c < boxCol + AppConstants.boxSize; c++) {
        cells.add(grid[r][c]);
      }
    }
    return cells;
  }
  
  /// Get the box index for a position
  int getBoxIndex(int row, int col) {
    return (row ~/ AppConstants.boxSize) * AppConstants.boxSize + 
           (col ~/ AppConstants.boxSize);
  }
  
  /// Get all positions that conflict with the given position
  Set<Position> getConflictingPositions(int row, int col) {
    final conflicts = <Position>{};
    
    // Add row conflicts
    for (int c = 0; c < AppConstants.boardSize; c++) {
      if (c != col) conflicts.add(Position(row, c));
    }
    
    // Add column conflicts
    for (int r = 0; r < AppConstants.boardSize; r++) {
      if (r != row) conflicts.add(Position(r, col));
    }
    
    // Add box conflicts
    final boxStartRow = (row ~/ AppConstants.boxSize) * AppConstants.boxSize;
    final boxStartCol = (col ~/ AppConstants.boxSize) * AppConstants.boxSize;
    
    for (int r = boxStartRow; r < boxStartRow + AppConstants.boxSize; r++) {
      for (int c = boxStartCol; c < boxStartCol + AppConstants.boxSize; c++) {
        if (r != row || c != col) {
          conflicts.add(Position(r, c));
        }
      }
    }
    
    return conflicts;
  }
  
  /// Check if placing a value at the given position would be valid
  bool isValidPlacement(int row, int col, int value) {
    if (value < 1 || value > 9) return false;
    
    final conflicts = getConflictingPositions(row, col);
    for (final conflict in conflicts) {
      if (getCell(conflict.row, conflict.col).value == value) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Check if the board is completely filled
  bool get isComplete {
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (grid[row][col].isEmpty) return false;
      }
    }
    return true;
  }
  
  /// Check if the board is valid (no conflicts)
  bool get isValid {
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = grid[row][col];
        if (cell.hasValue && !isValidPlacement(row, col, cell.value)) {
          return false;
        }
      }
    }
    return true;
  }
  
  /// Check if the puzzle is solved (complete and valid)
  bool get isSolved => isComplete && isValid;
  
  /// Get the number of filled cells
  int get filledCells {
    int count = 0;
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (grid[row][col].hasValue) count++;
      }
    }
    return count;
  }
  
  /// Get the number of empty cells
  int get emptyCells => AppConstants.totalCells - filledCells;
  
  /// Get all positions of empty cells
  List<Position> get emptyPositions {
    final positions = <Position>[];
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (grid[row][col].isEmpty) {
          positions.add(Position(row, col));
        }
      }
    }
    return positions;
  }
  
  /// Create a deep copy of the grid
  List<List<SudokuCell>> _copyGrid() {
    return List.generate(
      AppConstants.boardSize,
      (row) => List.generate(
        AppConstants.boardSize,
        (col) => grid[row][col],
      ),
    );
  }
  
  /// Copy this board with updated properties
  SudokuBoard copyWith({
    List<List<SudokuCell>>? grid,
    Difficulty? difficulty,
    String? puzzleId,
    DateTime? createdAt,
    List<List<SudokuCell>>? originalGrid,
  }) {
    return SudokuBoard(
      grid: grid ?? _copyGrid(),
      difficulty: difficulty ?? this.difficulty,
      puzzleId: puzzleId ?? this.puzzleId,
      createdAt: createdAt ?? this.createdAt,
      originalGrid: originalGrid ?? this.originalGrid,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    'difficulty': difficulty.name,
    'puzzleId': puzzleId,
    'createdAt': createdAt.toIso8601String(),
    'originalGrid': originalGrid?.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
  };
  
  /// Create from JSON
  factory SudokuBoard.fromJson(Map<String, dynamic> json) {
    final gridJson = json['grid'] as List<dynamic>;
    final grid = gridJson.map((rowJson) => 
      (rowJson as List<dynamic>).map((cellJson) => 
        SudokuCell.fromJson(cellJson as Map<String, dynamic>)
      ).toList()
    ).toList();
    
    List<List<SudokuCell>>? originalGrid;
    if (json['originalGrid'] != null) {
      final originalGridJson = json['originalGrid'] as List<dynamic>;
      originalGrid = originalGridJson.map((rowJson) => 
        (rowJson as List<dynamic>).map((cellJson) => 
          SudokuCell.fromJson(cellJson as Map<String, dynamic>)
        ).toList()
      ).toList();
    }
    
    return SudokuBoard(
      grid: grid,
      difficulty: Difficulty.values.firstWhere((d) => d.name == json['difficulty']),
      puzzleId: json['puzzleId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      originalGrid: originalGrid,
    );
  }
  
  @override
  List<Object?> get props => [grid, difficulty, puzzleId, createdAt, originalGrid];
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('SudokuBoard (${difficulty.displayName}):');
    for (int row = 0; row < AppConstants.boardSize; row++) {
      if (row % 3 == 0 && row != 0) {
        buffer.writeln('------+-------+------');
      }
      for (int col = 0; col < AppConstants.boardSize; col++) {
        if (col % 3 == 0 && col != 0) {
          buffer.write('| ');
        }
        final cell = grid[row][col];
        buffer.write(cell.isEmpty ? '.' : cell.value.toString());
        buffer.write(' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
