import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_provider.dart';

class ReadingGoalsScreen extends ConsumerStatefulWidget {
  const ReadingGoalsScreen({super.key});

  @override
  ConsumerState<ReadingGoalsScreen> createState() => _ReadingGoalsScreenState();
}

class _ReadingGoalsScreenState extends ConsumerState<ReadingGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookNotifierProvider.notifier).fetchGoals();
    });
  }

  void _showGoalDialog({Map<String, dynamic>? existingGoal}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existingGoal != null;

    final targetController = TextEditingController(
      text: isEditing ? existingGoal['targetBooks'].toString() : '',
    );
    final yearController = TextEditingController(
      text: isEditing
          ? existingGoal['year'].toString()
          : DateTime.now().year.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        String? localError;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              title: Text(
                isEditing ? 'Edit Goal Target' : 'Create Reading Goal',
                style: const TextStyle(
                  color: Color(0xFF4A2B33),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: const TextStyle(
                          color: Color(0xFFE85D75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!isEditing) ...[
                      TextFormField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFF4A2B33)),
                        decoration: InputDecoration(
                          labelText: 'Goal Year',
                          labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                          filled: true,
                          fillColor: const Color(0xFFFFF5F1),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD6CC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6F91),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a year';
                          }
                          final parsedYear = int.tryParse(value);
                          if (parsedYear == null ||
                              parsedYear < 1000 ||
                              parsedYear > 3000) {
                            return 'Enter a valid year';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFF4A2B33)),
                      decoration: InputDecoration(
                        labelText: 'Target Books',
                        labelStyle: const TextStyle(color: Color(0xFF9A6A73)),
                        filled: true,
                        fillColor: const Color(0xFFFFF5F1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD6CC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6F91),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter target book count';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count <= 0) {
                          return 'Goal value must be greater than zero';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF9A6A73)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F91),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final target = int.parse(targetController.text);
                      final year = int.parse(yearController.text);

                      setStateDialog(() {
                        localError = null;
                      });

                      bool success;
                      if (isEditing) {
                        success = await ref.read(bookNotifierProvider.notifier).updateGoal(
                          existingGoal['id'] as int,
                          target,
                        );
                      } else {
                        success = await ref.read(bookNotifierProvider.notifier).createGoal(
                          target,
                          year,
                        );
                      }

                      if (success) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Goal updated successfully'
                                    : 'Goal created successfully',
                              ),
                              backgroundColor: const Color(0xFFFF6F91),
                            ),
                          );
                        }
                      } else {
                        setStateDialog(() {
                          localError =
                              ref.read(bookNotifierProvider).errorMessage ??
                              'An error occurred';
                        });
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF4A2B33)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookNotifierProvider);
    final goals = bookState.goals;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F1),
      appBar: AppBar(
        title: const Text(
          'Reading Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A2B33)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (bookState.isGoalsLoading && goals.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6F91)),
            );
          }

          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Color(0xFFFFD6CC),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Goals Configured',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4A2B33),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Setting a goal is the first step toward building a reading habit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9A6A73)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F91),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add, color: Color(0xFF4A2B33)),
                      label: const Text(
                        'Set Your First Goal',
                        style: TextStyle(
                          color: Color(0xFF4A2B33),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showGoalDialog(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index] as Map<String, dynamic>;
              final year = goal['year'] as int? ?? 2026;
              final targetBooks = goal['targetBooks'] as int? ?? 1;
              final completedBooks = goal['completedBooks'] as int? ?? 0;
              final progressPercentage =
                  (goal['progressPercentage'] as num? ?? 0.0).toDouble();
              final status = goal['status'] as String? ?? 'Not Started';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'Achieved'
                                    ? const Color(0xFFFF8FA3).withOpacity(0.15)
                                    : const Color(0xFFFF6F91).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Achieved'
                                      ? const Color(0xFFFF8FA3)
                                      : const Color(0xFFFF9EAA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFFFF6F91),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _showGoalDialog(existingGoal: goal),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedBooks of $targetBooks books completed',
                          style: const TextStyle(
                            color: Color(0xFF9A6A73),
                            fontSize: 13,
                          ),
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
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          if (goals.isEmpty) return const SizedBox();
          return FloatingActionButton(
            backgroundColor: const Color(0xFFFF6F91),
            child: const Icon(Icons.add, color: Color(0xFF4A2B33)),
            onPressed: () => _showGoalDialog(),
          );
        },
      ),
    );
  }
}
