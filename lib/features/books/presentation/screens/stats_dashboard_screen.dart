import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_provider.dart';
import '../widgets/sakura_background.dart';

class StatsDashboardScreen extends ConsumerStatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  ConsumerState<StatsDashboardScreen> createState() =>
      _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends ConsumerState<StatsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookNotifierProvider.notifier).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookNotifierProvider);
    final notifier = ref.read(bookNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        title: const Text(
          'Reading Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A3142),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3A3142)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3A3142)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SakuraBackground(
        child: Builder(
          builder: (context) {
            if (bookState.isDashboardLoading &&
                bookState.dashboardStats == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE78FB3)),
              );
            }

            final stats = bookState.dashboardStats;
            if (stats == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 80,
                      color: Color(0xFFFFDCE8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No stats available',
                      style: TextStyle(color: Color(0xFF3A3142), fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE78FB3),
                      ),
                      onPressed: () => notifier.fetchDashboardStats(),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Color(0xFF3A3142)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final collection =
                stats['collectionStats'] as Map<String, dynamic>? ?? {};
            final reading =
                stats['readingStats'] as Map<String, dynamic>? ?? {};
            final genreAnalysis =
                stats['genreAnalysis'] as Map<String, dynamic>? ?? {};
            final insights =
                stats['readingInsights'] as Map<String, dynamic>? ?? {};
            final goal = stats['readingGoal'] as Map<String, dynamic>? ?? {};

            final totalBooks = collection['totalBooks'] as int? ?? 0;
            final totalBooksRead = collection['totalBooksRead'] as int? ?? 0;
            final currentlyReading =
                collection['currentlyReading'] as int? ?? 0;
            final totalPagesRead = reading['totalPagesRead'] as int? ?? 0;

            final completionRate = (reading['completionRate'] as num? ?? 0.0)
                .toDouble();
            final averageRating = (reading['averageRating'] as num? ?? 0.0)
                .toDouble();

            final genreList =
                (genreAnalysis['genreDistribution'] as List<dynamic>?) ?? [];
            final favoriteGenre =
                genreAnalysis['favoriteGenre'] as String? ?? 'N/A';

            final streak = insights['readingStreak'] as int? ?? 0;
            final finishedThisMonth =
                insights['booksFinishedThisMonth'] as int? ?? 0;
            final finishedThisYear =
                insights['booksFinishedThisYear'] as int? ?? 0;

            return RefreshIndicator(
              onRefresh: () => notifier.fetchDashboardStats(),
              color: const Color(0xFFE78FB3),
              backgroundColor: const Color(0xFFFFFFFF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2x2 Grid of Summary Metrics
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildSummaryCard(
                          title: 'Total Books',
                          value: '$totalBooks',
                          icon: Icons.library_books,
                          color: const Color(0xFFE78FB3),
                        ),
                        _buildSummaryCard(
                          title: 'Finished',
                          value: '$totalBooksRead',
                          icon: Icons.assignment_turned_in,
                          color: const Color(0xFF0F766E),
                        ),
                        _buildSummaryCard(
                          title: 'Reading Now',
                          value: '$currentlyReading',
                          icon: Icons.menu_book,
                          color: const Color(0xFF14B8A6),
                        ),
                        _buildSummaryCard(
                          title: 'Pages Read',
                          value: '$totalPagesRead',
                          icon: Icons.auto_stories,
                          color: const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Streak & Activity Section
                    _buildInsightsCard(
                      streak: streak,
                      monthCompletions: finishedThisMonth,
                      yearCompletions: finishedThisYear,
                    ),
                    const SizedBox(height: 24),

                    // Reading Goal Integration (If active)
                    if (goal.isNotEmpty) ...[
                      _buildGoalCard(goal),
                      const SizedBox(height: 24),
                    ],

                    // Completion Rate & Average Rating Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildGaugeCard(
                            title: 'Completion Rate',
                            percentage: completionRate,
                            color: const Color(0xFFE78FB3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRatingCard(
                            title: 'Avg Rating',
                            rating: averageRating,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Favorite Genre highlight
                    _buildFavoriteGenreCard(favoriteGenre),
                    const SizedBox(height: 24),

                    // Genre Distribution Visual Progress Lists
                    if (genreList.isNotEmpty) ...[
                      _buildGenreDistributionCard(genreList, totalBooks),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8B7E95),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF3A3142),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard({
    required int streak,
    required int monthCompletions,
    required int yearCompletions,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Insights',
            style: TextStyle(
              color: Color(0xFF3A3142),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightMetric(
                label: 'Streak',
                value: '$streak Days',
                icon: Icons.local_fire_department,
                color: const Color(0xFFE78FB3),
              ),
              Container(
                height: 32,
                width: 1,
                color: const Color(0xFFFFDCE8).withValues(alpha: 0.5),
              ),
              _buildInsightMetric(
                label: 'This Month',
                value: '$monthCompletions',
                icon: Icons.calendar_today,
                color: const Color(0xFF8B7E95),
              ),
              Container(
                height: 32,
                width: 1,
                color: const Color(0xFFFFDCE8).withValues(alpha: 0.5),
              ),
              _buildInsightMetric(
                label: 'This Year',
                value: '$yearCompletions',
                icon: Icons.insights,
                color: const Color(0xFFF8BBD9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF3A3142),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B7E95), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required double percentage,
    required Color color,
  }) {
    final value = percentage / 100.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B7E95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFFFF8FA),
                  color: color,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF3A3142),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard({required String title, required double rating}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B7E95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB020),
                      size: 28,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                      style: const TextStyle(
                        color: Color(0xFF3A3142),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Average Rating',
                  style: TextStyle(color: Color(0xFF8B7E95), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteGenreCard(String genre) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE78FB3), Color(0xFFF8BBD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFFFFFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite Genre',
                  style: TextStyle(
                    color: const Color(0xFF3A3142).withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  genre,
                  style: const TextStyle(
                    color: Color(0xFF3A3142),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreDistributionCard(List<dynamic> genreList, int totalBooks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genre Distribution',
            style: TextStyle(
              color: Color(0xFF3A3142),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...genreList.map((entry) {
            final genre = entry['genre'] as String? ?? 'N/A';
            final count = entry['count'] as int? ?? 0;
            final progress = totalBooks > 0 ? count / totalBooks : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        genre,
                        style: const TextStyle(
                          color: Color(0xFF3A3142),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$count book${count == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: Color(0xFF8B7E95),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFFFF8FA),
                      color: const Color(0xFFE78FB3),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final year = goal['year'] as int? ?? 2026;
    final targetBooks = goal['targetBooks'] as int? ?? 1;
    final completedBooks = goal['completedBooks'] as int? ?? 0;
    final progressPercentage = (goal['progressPercentage'] as num? ?? 0.0)
        .toDouble();
    final status = goal['status'] as String? ?? 'Not Started';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE78FB3).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFDCE8).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$year Reading Goal',
                style: const TextStyle(
                  color: Color(0xFF3A3142),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE78FB3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFFE78FB3),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedBooks of $targetBooks books completed',
                style: const TextStyle(color: Color(0xFF8B7E95), fontSize: 13),
              ),
              Text(
                '${progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFFE78FB3),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: targetBooks > 0
                  ? (completedBooks / targetBooks).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: const Color(0xFFFFF8FA),
              color: const Color(0xFFE78FB3),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
