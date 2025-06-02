import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../engine/engine.dart';
import '../constants/app_constants.dart';
import '../services/services.dart';

/// Main game state provider that manages the Sudoku game state
class GameProvider extends ChangeNotifier {
  GameController? _gameController;
  GameState? _gameState;
  Position? _selectedPosition;
  bool _isNotesMode = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String? _lastError;
  GameHint? _lastHint;
  MoveValidation? _lastMoveValidation;
  
  // Getters
  GameController? get gameController => _gameController;
  GameState? get gameState => _gameState;
  Position? get selectedPosition => _selectedPosition;
  bool get isNotesMode => _isNotesMode;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  GameHint? get lastHint => _lastHint;
  MoveValidation? get lastMoveValidation => _lastMoveValidation;
  
  // Computed properties
  bool get isGameActive => _gameState != null && 
                          !_gameState!.isCompleted && 
                          !_isPaused;
  
  bool get hasGameInProgress => _gameState != null && !_gameState!.isCompleted;
  
  Set<Position> get highlightedCells {
    if (_selectedPosition == null || _gameState == null) return {};
    
    final highlighted = <Position>{};
    final selectedCell = _gameState!.board.getCellAt(_selectedPosition!);
    
    // Highlight cells with same value if selected cell has a value
    if (selectedCell.hasValue) {
      for (int row = 0; row < AppConstants.boardSize; row++) {
        for (int col = 0; col < AppConstants.boardSize; col++) {
          final cell = _gameState!.board.getCell(row, col);
          if (cell.value == selectedCell.value && cell.hasValue) {
            highlighted.add(Position(row, col));
          }
        }
      }
    }
    
    // Highlight related cells (same row, column, box)
    final conflicts = _gameState!.board.getConflictingPositions(
      _selectedPosition!.row, 
      _selectedPosition!.col,
    );
    highlighted.addAll(conflicts);
    highlighted.add(_selectedPosition!);
    
    return highlighted;
  }
    Set<Position> get errorCells {
    if (_gameState == null) return {};
    
    final errorCells = <Position>{};
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = _gameState!.board.getCell(row, col);
        if (cell.hasValue && !cell.isFixed) {
          // Check if this value creates conflicts
          final conflicts = _findCellConflicts(row, col, cell.value);
          if (conflicts.isNotEmpty) {
            errorCells.add(Position(row, col));
          }
        }
      }
    }
    
    return errorCells;
  }
  
  /// Helper method to find conflicts for a specific cell
  List<Position> _findCellConflicts(int row, int col, int value) {
    if (_gameState == null) return [];
    
    final conflicts = <Position>[];
    final board = _gameState!.board;
    
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
  
  Set<Position> get hintCells {
    // Return positions that were recently hinted
    if (_lastHint != null) {
      return {_lastHint!.position};
    }
    return {};
  }
  
  Set<int> get availableNumbers => {1, 2, 3, 4, 5, 6, 7, 8, 9}; // Always allow all numbers
  
  Map<int, int> get numberCounts {
    if (_gameState == null) return {};
    
    final counts = <int, int>{};
    
    for (int i = 1; i <= 9; i++) {
      counts[i] = 0;
    }
    
    for (int row = 0; row < AppConstants.boardSize; row++) {
      for (int col = 0; col < AppConstants.boardSize; col++) {
        final cell = _gameState!.board.getCell(row, col);
        if (cell.hasValue) {
          counts[cell.value] = (counts[cell.value] ?? 0) + 1;
        }
      }
    }
    
    return counts;
  }
  
  /// Start a new game
  Future<void> startNewGame(Difficulty difficulty) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Dispose previous controller if exists
      _gameController?.dispose();
      
      // Create new game state
      final gameState = GameMechanics.startNewGame(difficulty);
      _gameController = GameController(gameState);
      _gameState = gameState;
      
      // Set up callbacks
      _setupGameControllerCallbacks();
      
      // Reset UI state
      _selectedPosition = null;
      _isNotesMode = false;
      _isPaused = false;
      _lastHint = null;
      _lastMoveValidation = null;
      
    } catch (e) {
      _setError('Failed to start new game: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Resume an existing game
  Future<void> resumeGame(GameState gameState) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Dispose previous controller if exists
      _gameController?.dispose();
      
      _gameController = GameController(gameState);
      _gameState = gameState;
      
      // Set up callbacks
      _setupGameControllerCallbacks();
      
      // Reset UI state
      _selectedPosition = null;
      _isNotesMode = false;
      _isPaused = gameState.isPaused;
      _lastHint = null;
      _lastMoveValidation = null;
      
    } catch (e) {
      _setError('Failed to resume game: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Save the current game state
  Future<bool> saveCurrentGame() async {
    if (_gameState == null) return false;
    
    try {
      _clearError();
      final success = await GameStorageService.saveGame(_gameState!);
      if (!success) {
        _setError('Failed to save game');
      }
      return success;
    } catch (e) {
      _setError('Error saving game: $e');
      return false;
    }
  }
  
  /// Load a saved game
  Future<bool> loadSavedGame() async {
    _setLoading(true);
    _clearError();
    
    try {
      final savedGameState = await GameStorageService.loadSavedGame();
      if (savedGameState != null) {
        await resumeGame(savedGameState);
        return true;
      } else {
        _setError('No saved game found');
        return false;
      }
    } catch (e) {
      _setError('Error loading saved game: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Check if there's a saved game available
  Future<bool> hasSavedGame() async {
    try {
      return await GameStorageService.hasSavedGame();
    } catch (e) {
      return false;
    }
  }
  
  /// Clear the saved game
  Future<bool> clearSavedGame() async {
    try {
      return await GameStorageService.clearSavedGame();
    } catch (e) {
      return false;
    }
  }
  
  /// Get saved game metadata
  Future<Map<String, dynamic>?> getSavedGameMetadata() async {
    try {
      return await GameStorageService.getSavedGameMetadata();
    } catch (e) {
      return null;
    }
  }
    /// Auto-save the current game (called automatically after state changes)
  Future<void> _autoSaveGame() async {
    if (_gameState == null || _gameState!.isCompleted) return;
    
    final isAutoSaveEnabled = await GameStorageService.isAutoSaveEnabled();
    if (isAutoSaveEnabled) {
      await saveCurrentGame();
    }
  }
  
  /// Select a cell on the board
  void selectCell(Position position) {
    if (_gameState == null) return;
    
    _selectedPosition = _selectedPosition == position ? null : position;
    notifyListeners();
  }
  
  /// Make a move on the board
  void makeMove(Position position, int value) {
    if (_gameController == null || !isGameActive) return;
    
    _clearError();
    _gameController!.makeMove(position.row, position.col, value);
  }
  
  /// Toggle notes mode
  void toggleNotesMode() {
    _isNotesMode = !_isNotesMode;
    notifyListeners();
  }
  
  /// Update notes for a cell
  void updateNotes(Position position, Set<int> notes) {
    if (_gameController == null || !isGameActive) return;
    
    _clearError();
    
    final currentCell = _gameState!.board.getCellAt(position);
    final currentNotes = currentCell.notes;
    
    // Find notes to add and remove
    final notesToAdd = notes.difference(currentNotes);
    final notesToRemove = currentNotes.difference(notes);
    
    // Apply changes
    for (final note in notesToAdd) {
      _gameController!.toggleNote(position.row, position.col, note);
    }
    for (final note in notesToRemove) {
      _gameController!.toggleNote(position.row, position.col, note);
    }
  }
  
  /// Clear the selected cell
  void clearSelectedCell() {
    if (_selectedPosition != null && _gameController != null && isGameActive) {
      _clearError();
      
      // Clear by setting value to 0 and clearing notes
      _gameController!.makeMove(_selectedPosition!.row, _selectedPosition!.col, 0);
      _gameController!.clearNotes(_selectedPosition!.row, _selectedPosition!.col);
    }
  }
  
  /// Undo last move
  void undoMove() {
    if (_gameController == null || !isGameActive) return;
    
    _clearError();
    _gameController!.undoMove();
  }
  
  /// Redo last move
  void redoMove() {
    if (_gameController == null || !isGameActive) return;
    
    _clearError();
    _gameController!.redoMove();
  }
  
  /// Get a hint
  void getHint() {
    if (_gameController == null || !isGameActive) return;
    
    _clearError();
    _gameController!.getHint();
  }
    /// Pause the game
  void pauseGame() {
    if (_gameController == null || !hasGameInProgress) return;
    
    _isPaused = true;
    _gameController!.pauseGame();
    notifyListeners();
    
    // Auto-save when pausing
    _autoSaveGame();
  }
  
  /// Resume the game
  void resumeGamePlay() {
    if (_gameController == null || !hasGameInProgress) return;
    
    _isPaused = false;
    _gameController!.resumeGamePlay();
    notifyListeners();
  }
  
  /// Insert number in selected cell or as note
  void insertNumber(int number) {
    if (_selectedPosition != null) {
      if (_isNotesMode) {
        final cell = _gameState!.board.getCellAt(_selectedPosition!);
        final newNotes = Set<int>.from(cell.notes);
        if (newNotes.contains(number)) {
          newNotes.remove(number);
        } else {
          newNotes.add(number);
        }
        updateNotes(_selectedPosition!, newNotes);
      } else {
        makeMove(_selectedPosition!, number);
      }
    }
  }
  
  /// Clear any temporary state (errors, hints, etc.)
  void clearTemporaryState() {
    _lastError = null;
    _lastHint = null;
    _lastMoveValidation = null;
    notifyListeners();
  }
  
  // Private methods
  void _setupGameControllerCallbacks() {
    if (_gameController == null) return;
      _gameController!.onGameStateChanged = (gameState) {
      _gameState = gameState;
      notifyListeners();
      // Auto-save after game state changes
      _autoSaveGame();
    };    _gameController!.onGameCompleted = () {
      // Game completed - clear saved game since it's done
      clearSavedGame();
      
      // Update statistics with completed game
      if (_gameState != null) {
        StatisticsService.addCompletedGame(_gameState!).then((success) {
          if (!success) {
            print('Failed to update statistics for completed game');
          }
        });
      }
      
      notifyListeners();
    };
    
    _gameController!.onError = (error) {
      _setError(error);
    };
    
    _gameController!.onMoveValidated = (validation) {
      _lastMoveValidation = validation;
      notifyListeners();
    };
    
    _gameController!.onHintProvided = (hint) {
      _lastHint = hint;
      notifyListeners();
    };
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }
  
  void _clearError() {
    _lastError = null;
  }
  
  @override
  void dispose() {
    _gameController?.dispose();
    super.dispose();
  }
}
