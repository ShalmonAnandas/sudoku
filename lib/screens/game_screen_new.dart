import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../providers/providers.dart';

/// Main game screen where the Sudoku game is played
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final bool isNewGame;
  final GameState? savedGameState;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.isNewGame = false,
    this.savedGameState,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() {
    final gameProvider = context.read<GameProvider>();
    
    // Initialize game based on parameters
    if (widget.isNewGame) {
      gameProvider.startNewGame(widget.difficulty);
    } else if (widget.savedGameState != null) {
      gameProvider.resumeGame(widget.savedGameState!);
    } else {
      // Fallback to new game
      gameProvider.startNewGame(widget.difficulty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // Handle error snackbar
        if (gameProvider.lastError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(context, gameProvider.lastError!);
            gameProvider.clearTemporaryState();
          });
        }

        // Handle game completion
        if (gameProvider.gameState?.isCompleted == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameCompleteDialog(context, gameProvider);
          });
        }

        if (gameProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.difficulty.displayName} Sudoku'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error if game failed to load
        if (gameProvider.gameState == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.difficulty.displayName} Sudoku'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    gameProvider.lastError ?? 'Failed to load game',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, gameProvider),
          body: gameProvider.isPaused 
              ? _buildPausedView(context, gameProvider) 
              : _buildGameView(context, gameProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameProvider gameProvider) {
    return AppBar(
      title: Text('${widget.difficulty.displayName} Sudoku'),
      actions: [
        IconButton(
          icon: Icon(gameProvider.isPaused ? Icons.play_arrow : Icons.pause),
          onPressed: gameProvider.isGameActive
              ? (gameProvider.isPaused
                  ? gameProvider.resumeGamePlay
                  : gameProvider.pauseGame)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _showRestartDialog(context, gameProvider),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, gameProvider, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save',
              child: ListTile(
                leading: Icon(Icons.save),
                title: Text('Save Game'),
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
            const PopupMenuItem(
              value: 'home',
              child: ListTile(
                leading: Icon(Icons.home),
                title: Text('Back to Home'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPausedView(BuildContext context, GameProvider gameProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Game Paused',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap play to resume',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: gameProvider.resumeGamePlay,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    
    return Column(
      children: [
        // Game info bar
        _buildGameInfoBar(context, gameProvider),
        // Sudoku board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SudokuBoardWidget(
              board: gameState.board,
              selectedPosition: gameProvider.selectedPosition,
              isNotesMode: gameProvider.isNotesMode,
              showConflicts: gameState.board.difficulty.hasFeedback,
              showHints: gameState.board.difficulty.hasFeedback,
              highlightedCells: gameProvider.highlightedCells,
              errorCells: gameProvider.errorCells,
              hintCells: gameProvider.hintCells,
              onCellTap: gameProvider.selectCell,
              onCellInput: gameProvider.makeMove,
              onNotesUpdate: gameProvider.updateNotes,
              onBoardComplete: () => _showGameCompleteDialog(context, gameProvider),
            ),
          ),
        ),
        // Game controls and number input
        Column(
          children: [
            // Traditional controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    context,
                    icon: Icons.undo,
                    label: 'Undo',
                    onPressed: gameState.canUndo ? gameProvider.undoMove : null,
                  ),
                  _buildControlButton(
                    context,
                    icon: Icons.redo,
                    label: 'Redo',
                    onPressed: gameState.canRedo ? gameProvider.redoMove : null,
                  ),
                  _buildControlButton(
                    context,
                    icon: Icons.lightbulb,
                    label: 'Hint',
                    onPressed: gameState.canUseHint ? gameProvider.getHint : null,
                  ),
                  _buildControlButton(
                    context,
                    icon: Icons.clear,
                    label: 'Clear',
                    onPressed: gameProvider.selectedPosition != null ? gameProvider.clearSelectedCell : null,
                  ),
                ],
              ),
            ),
            
            // Number input panel
            NumberInputPanel(
              isNotesMode: gameProvider.isNotesMode,
              onNumberSelected: gameProvider.insertNumber,
              onNotesToggle: gameProvider.toggleNotesMode,
              onClear: gameProvider.clearSelectedCell,
              availableNumbers: gameProvider.availableNumbers,
              numberCounts: gameProvider.numberCounts,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameInfoBar(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Timer
          _buildInfoItem(
            context,
            icon: Icons.timer,
            label: 'Time',
            value: _formatTime(gameState.elapsedSeconds),
          ),
          const SizedBox(width: 24),
          
          // Score (if applicable)
          if (gameState.board.difficulty.hasScoring) ...[
            _buildInfoItem(
              context,
              icon: Icons.star,
              label: 'Score',
              value: gameState.score.toString(),
            ),
            const SizedBox(width: 24),
          ],
          
          // Errors
          _buildInfoItem(
            context,
            icon: Icons.error_outline,
            label: 'Errors',
            value: gameState.errorsCount.toString(),
            valueColor: gameState.errorsCount > 0 
                ? Theme.of(context).colorScheme.error 
                : null,
          ),          // Hints used
          const Spacer(),
          _buildInfoItem(
            context,
            icon: Icons.lightbulb_outline,
            label: 'Hints',
            value: '${gameState.hintsUsed}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: onPressed != null 
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: onPressed != null 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, GameProvider gameProvider, String action) {
    switch (action) {
      case 'save':
        _saveGame(context, gameProvider);
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
      case 'home':
        _showExitDialog(context, gameProvider);
        break;
    }
  }
  void _saveGame(BuildContext context, GameProvider gameProvider) async {
    final success = await gameProvider.saveCurrentGame();
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game saved successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar(context, gameProvider.lastError ?? 'Failed to save game');
      }
    }
  }

  void _showRestartDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Game'),
        content: const Text('Are you sure you want to restart? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              gameProvider.startNewGame(widget.difficulty);
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game'),
        content: const Text('Are you sure you want to exit? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),          TextButton(
            onPressed: () async {
              // Save game before exiting
              await gameProvider.saveCurrentGame();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home  
              }
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
  void _showGameCompleteDialog(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You completed the puzzle!'),
            const SizedBox(height: 16),
            Text('Time: ${_formatTime(gameState.elapsedSeconds)}'),
            Text('Score: ${gameState.score}'),
            Text('Errors: ${gameState.errorsCount}'),
            Text('Hints used: ${gameState.hintsUsed}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              gameProvider.startNewGame(widget.difficulty);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
