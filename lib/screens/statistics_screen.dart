import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/test_data_generator.dart';
import '../services/test_data_generator.dart';

/// Statistics screen showing game performance and achievements
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    // Refresh statistics when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).refreshStatistics();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          // Add a menu for generating test data (only in development)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'generate_test_data') {
                await TestDataGenerator.saveTestData();
                // Refresh after generating
                if (context.mounted) {
                  Provider.of<StatisticsProvider>(context, listen: false).refreshStatistics();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'generate_test_data',
                child: Text('Generate Test Data'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Achievements', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, statsProvider, child) {
          if (statsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (statsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${statsProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => statsProvider.refreshStatistics(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(statsProvider),
              _buildProgressTab(statsProvider),
              _buildAchievementsTab(statsProvider),
            ],
          );
        },
      ),
    );
  }
  Widget _buildOverviewTab(StatisticsProvider statsProvider) {
    final stats = statsProvider.statistics;
    
    // Format the average time nicely
    final avgTimeFormatted = GameStatistics.formatTime(stats.averageTime);
    
    // Format total play time in hours and minutes
    final totalPlayHours = (stats.totalPlayTime / 3600).floor();
    final totalPlayMinutes = ((stats.totalPlayTime % 3600) / 60).floor();
    final totalPlayTimeFormatted = '${totalPlayHours}h ${totalPlayMinutes}m';
    
    // Format win rate with 1 decimal place
    final winRateFormatted = stats.winRate.toStringAsFixed(1);
    
    // Format best score with commas for thousands
    final bestScoreFormatted = stats.bestScore.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (match) => '${match.group(1)},'
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(
          title: 'Overall Performance',
          children: [
            _buildStatRow('Games Played', '${stats.gamesPlayed}', Icons.games),
            _buildStatRow('Games Won', '${stats.gamesWon}', Icons.emoji_events),
            _buildStatRow('Win Rate', '$winRateFormatted%', Icons.percent),
            _buildStatRow('Average Time', avgTimeFormatted, Icons.timer),
            _buildStatRow('Best Score', bestScoreFormatted, Icons.star),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildStatsCard(
          title: 'Difficulty Breakdown',
          children: Difficulty.values.map((difficulty) {
            final diffStats = statsProvider.getDifficultyStats(difficulty);
            return _buildDifficultyRow(
              difficulty, 
              diffStats.gamesPlayed, 
              diffStats.gamesWon, 
              diffStats.bestTimeFormatted,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        _buildStatsCard(
          title: 'Playing Habits',
          children: [
            _buildStatRow('Total Play Time', totalPlayTimeFormatted, Icons.schedule),
            _buildStatRow('Longest Streak', '${stats.longestStreak} days', Icons.local_fire_department),
            _buildStatRow('Current Streak', '${stats.currentStreak} days', Icons.trending_up),
            _buildStatRow('Hints Used', '${stats.hintsUsed}', Icons.lightbulb),
          ],
        ),
      ],
    );
  }
  Widget _buildProgressTab(StatisticsProvider statsProvider) {
    final stats = statsProvider.statistics;
    
    // Count perfect games (no errors, no hints)
    final perfectGames = stats.gameRecords.where((game) => 
      game.completed && game.errorCount == 0 && game.hintsUsed == 0
    ).length;
    
    // Format highest score with commas
    final highestScore = stats.bestScore.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (match) => '${match.group(1)},'
    );
    
    // Calculate error rate (errors per game)
    final totalErrors = stats.gameRecords.fold(0, (sum, game) => sum + game.errorCount);
    final errorRate = stats.gamesPlayed > 0 
        ? (totalErrors / stats.gamesPlayed * 100).toStringAsFixed(1)
        : '0.0';
    
    // Calculate hint usage percentage
    final totalHints = stats.hintsUsed;
    final hintUsageRate = stats.gamesPlayed > 0
        ? (totalHints / stats.gamesPlayed * 100).toStringAsFixed(1)
        : '0.0';
    
    // Calculate average time compared to best times
    final avgSpeed = stats.averageTime > 0
        ? ((stats.averageTime - (stats.bestTimeForDifficulty(Difficulty.medium) / 2)) / 
           stats.averageTime * 100).toStringAsFixed(1)
        : '0.0';
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsCard(
          title: 'Recent Performance',
          children: [
            _buildProgressChart(),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildStatsCard(
          title: 'Personal Records',
          children: [
            _buildRecordRow(
              'Fastest Easy', 
              GameStatistics.formatTime(statsProvider.getDifficultyStats(Difficulty.easy).bestTime), 
              Icons.speed
            ),
            _buildRecordRow(
              'Fastest Medium', 
              GameStatistics.formatTime(statsProvider.getDifficultyStats(Difficulty.medium).bestTime), 
              Icons.speed
            ),
            _buildRecordRow(
              'Fastest Hard', 
              GameStatistics.formatTime(statsProvider.getDifficultyStats(Difficulty.hard).bestTime), 
              Icons.speed
            ),
            _buildRecordRow('Highest Score', highestScore, Icons.star),
            _buildRecordRow('Perfect Games', perfectGames.toString(), Icons.emoji_events),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildStatsCard(
          title: 'Improvement Areas',
          children: [
            _buildImprovementRow('Error Rate', double.parse(errorRate), 'Try to be more careful'),
            _buildImprovementRow('Hint Usage', double.parse(hintUsageRate), 'Challenge yourself more'),
            _buildImprovementRow('Speed', double.parse(avgSpeed), 'Practice pattern recognition'),
          ],
        ),
      ],
    );
  }
  Widget _buildAchievementsTab(StatisticsProvider statsProvider) {
    final achievements = statsProvider.getAchievements();
    
    // Sort achievements: unlocked first, then by progress
    achievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      if (!a.isUnlocked && !b.isUnlocked) return b.progress.compareTo(a.progress);
      return 0;
    });
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: achievements.map((achievement) => 
        _buildAchievementCard(
          title: achievement.definition.title,
          description: achievement.definition.description,
          icon: achievement.definition.icon,
          isUnlocked: achievement.isUnlocked,
          progress: achievement.progress,
        ),
      ).toList(),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyRow(Difficulty difficulty, int played, int won, String bestTime) {
    final winRate = played > 0 ? (won / played * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                difficulty.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$won/$played',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Win Rate: $winRate%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Best Time: $bestTime',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: played > 0 ? won / played : 0,
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Win Rate Over Time',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Chart placeholder\n(Coming soon)'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementRow(String area, double score, String suggestion) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  area,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
    required double progress,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked 
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isUnlocked 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? null : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 8),
            if (!isUnlocked) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: isUnlocked 
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
