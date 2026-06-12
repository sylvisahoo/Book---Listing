import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.currentUser;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9A6A73),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A2B33),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF6F91).withOpacity(0.2),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFFE85D75)),
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                            backgroundColor: Color(0xFFFF6F91),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Library Overview Card
              Container(
                padding: const EdgeInsets.all(24),
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
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 40,
                      color: Color(0xFF4A2B33),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Personal Library',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2B33),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4A2B33).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Features Header
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2B33),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildFeatureTile(
                      icon: Icons.book,
                      title: 'My Books',
                      subtitle: 'Add, edit and organize your books',
                      onTap: () {
                        Navigator.pushNamed(context, '/books');
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.bar_chart,
                      title: 'Reading Stats',
                      subtitle: 'View analytics and insights',
                      onTap: () {
                        Navigator.pushNamed(context, '/stats-dashboard');
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.emoji_events,
                      title: 'Annual Goals',
                      subtitle: 'Set goals and track milestones',
                      onTap: () {
                        Navigator.pushNamed(context, '/goals');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD6CC)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F91).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF6F91)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2B33),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A6A73),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFFFD6CC),
            ),
          ],
        ),
      ),
    );
  }
}
