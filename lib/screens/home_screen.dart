import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/providers.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// Home screen with main menu and difficulty selection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkForSavedGame();
  }

  Future<void> _checkForSavedGame() async {
    final gameProvider = context.read<GameProvider>();
    final hasSaved = await gameProvider.hasSavedGame();
    if (mounted) {
      setState(() {
        _hasSavedGame = hasSaved;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh saved game status when returning to this screen
    _checkForSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                children: [
                  // App title and logo
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_3x3,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sudoku Swami',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Challenge your mind with logic',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Difficulty selection
                  Column(
                    children: [
                      Text(
                        'Choose Difficulty',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      ...Difficulty.values.map(
                        (difficulty) => _DifficultyCard(
                          difficulty: difficulty,
                          onTap: () => _startNewGame(context, difficulty),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.play_arrow,
                              label: 'Resume Game',
                              onTap: _hasSavedGame
                                  ? () => _resumeGame(context)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.bar_chart,
                              label: 'Statistics',
                              onTap: () => _showStatistics(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () => _showSettings(context),
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(difficulty: difficulty, isNewGame: true),
      ),
    );
  }

  void _resumeGame(BuildContext context) async {
    final gameProvider = context.read<GameProvider>();

    // Check if there's a saved game
    final hasSaved = await gameProvider.hasSavedGame();
    if (!hasSaved) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved game found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Load and resume the saved game
    final success = await gameProvider.loadSavedGame();
    if (success && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GameScreen(
            difficulty:
                Difficulty.easy, // This will be overridden by the loaded state
            isNewGame: false,
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.lastError ?? 'Failed to load saved game'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStatistics(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const StatisticsScreen()));
  }

  void _showSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}

/// Card widget for difficulty selection
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback onTap;

  const _DifficultyCard({required this.difficulty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExtreme = difficulty == Difficulty.extreme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isExtreme
                  ? Border.all(color: theme.colorScheme.error, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Difficulty icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDifficultyIcon(),
                    color: _getDifficultyColor(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Difficulty info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExtreme ? theme.colorScheme.error : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficulty.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isExtreme) ...[
                        const SizedBox(height: 4),
                        Text(
                          'No hints or feedback',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Difficulty indicator
                Column(
                  children: [
                    ...List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        width: 4,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index < _getDifficultyLevel()
                              ? _getDifficultyColor(context)
                              : theme.colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
      case Difficulty.extreme:
        return colorScheme.error;
    }
  }

  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case Difficulty.easy:
        return Icons.sentiment_satisfied;
      case Difficulty.medium:
        return Icons.sentiment_neutral;
      case Difficulty.hard:
        return Icons.sentiment_dissatisfied;
      case Difficulty.extreme:
        return Icons.warning;
    }
  }

  int _getDifficultyLevel() {
    switch (difficulty) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
      case Difficulty.extreme:
        return 4;
    }
  }
}

/// Reusable action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isFullWidth;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
