import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class StatsDashboardScreen extends StatefulWidget {
  final BookProvider bookProvider;
  const StatsDashboardScreen({super.key, required this.bookProvider});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bookProvider.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F1),
      appBar: AppBar(
        title: const Text(
          'Reading Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A2B33)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          if (provider.isDashboardLoading && provider.dashboardStats == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6F91)),
            );
          }

          final stats = provider.dashboardStats;
          if (stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: Color(0xFFFFD6CC),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No stats available',
                    style: TextStyle(color: Color(0xFF4A2B33), fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F91),
                    ),
                    onPressed: () => provider.fetchDashboardStats(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Color(0xFF4A2B33)),
                    ),
                  ),
                ],
              ),
            );
          }

          final collection =
              stats['collectionStats'] as Map<String, dynamic>? ?? {};
          final reading = stats['readingStats'] as Map<String, dynamic>? ?? {};
          final genreAnalysis =
              stats['genreAnalysis'] as Map<String, dynamic>? ?? {};
          final insights =
              stats['readingInsights'] as Map<String, dynamic>? ?? {};
          final goal = stats['readingGoal'] as Map<String, dynamic>? ?? {};

          final totalBooks = collection['totalBooks'] as int? ?? 0;
          final totalBooksRead = collection['totalBooksRead'] as int? ?? 0;
          final currentlyReading = collection['currentlyReading'] as int? ?? 0;
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
            onRefresh: () => provider.fetchDashboardStats(),
            color: const Color(0xFFFF6F91),
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
                        color: const Color(0xFFFF6F91),
                      ),
                      _buildSummaryCard(
                        title: 'Finished',
                        value: '$totalBooksRead',
                        icon: Icons.assignment_turned_in,
                        color: Color(0xFFFF8FA3),
                      ),
                      _buildSummaryCard(
                        title: 'Reading Now',
                        value: '$currentlyReading',
                        icon: Icons.menu_book,
                        color: Color(0xFFFFB3C6),
                      ),
                      _buildSummaryCard(
                        title: 'Pages Read',
                        value: '$totalPagesRead',
                        icon: Icons.auto_stories,
                        color: Color(0xFFFFC09F),
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
                          color: const Color(0xFFFF6F91),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD6CC)),
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
                  color: Color(0xFF9A6A73),
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
              color: Color(0xFF4A2B33),
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
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Insights',
            style: TextStyle(
              color: Color(0xFF4A2B33),
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
                color: Colors.deepOrangeAccent,
              ),
              Container(height: 32, width: 1, color: const Color(0xFFFFD6CC)),
              _buildInsightMetric(
                label: 'This Month',
                value: '$monthCompletions',
                icon: Icons.calendar_today,
                color: Colors.tealAccent,
              ),
              Container(height: 32, width: 1, color: const Color(0xFFFFD6CC)),
              _buildInsightMetric(
                label: 'This Year',
                value: '$yearCompletions',
                icon: Icons.insights,
                color: Colors.purpleAccent,
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
            color: Color(0xFF4A2B33),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9A6A73), fontSize: 11),
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
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A6A73),
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
                  backgroundColor: const Color(0xFFFFF5F1),
                  color: color,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF4A2B33),
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
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A6A73),
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
                    const Icon(Icons.star, color: Color(0xFFFF9EAA), size: 28),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                      style: const TextStyle(
                        color: Color(0xFF4A2B33),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Average Rating',
                  style: TextStyle(color: Color(0xFF9A6A73), fontSize: 10),
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
          colors: [Color(0xFFFF6F91), Color(0xFFFF9EAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F91).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF4A2B33).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: Color(0xFF4A2B33),
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
                    color: Color(0xFF4A2B33).withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  genre,
                  style: const TextStyle(
                    color: Color(0xFF4A2B33),
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
        border: Border.all(color: const Color(0xFFFFD6CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genre Distribution',
            style: TextStyle(
              color: Color(0xFF4A2B33),
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
                          color: Color(0xFF4A2B33),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$count book${count == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: Color(0xFF9A6A73),
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
                      backgroundColor: const Color(0xFFFFF5F1),
                      color: const Color(0xFFFF6F91),
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
        border: Border.all(color: const Color(0xFFFFD6CC)),
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
                  color: Color(0xFF4A2B33),
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
                  color: status == 'Achieved'
                      ? Color(0xFFFF8FA3).withOpacity(0.15)
                      : const Color(0xFFFF6F91).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Achieved'
                        ? Color(0xFFFF8FA3)
                        : const Color(0xFFFF9EAA),
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
                style: const TextStyle(color: Color(0xFF9A6A73), fontSize: 13),
              ),
              Text(
                '${progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFFFF6F91),
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
              backgroundColor: const Color(0xFFFFF5F1),
              color: const Color(0xFFFF6F91),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
