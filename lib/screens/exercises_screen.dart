import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/exercise_card.dart';
import '../widgets/log_exercise_sheet.dart';
import 'exercise_detail_screen.dart';

class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key});

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: kGoldColor));
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.error!,
                    style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadExercises,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.exercises.isEmpty) {
          return const _EmptyExerciseState();
        }

        return RefreshIndicator(
          color: kGoldColor,
          backgroundColor: colors.card,
          onRefresh: provider.loadExercises,
          child: CustomScrollView(
            key: const Key('exercises_scroll'),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exercise = provider.exercises[index];
                    return ExerciseCard(
                      key: ValueKey(exercise.id),
                      exercise: exercise,
                      lastPracticed: provider
                          .lastSessionDateForExercise(exercise.id!),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exercise: exercise),
                        ),
                      ),
                      onPlay: () => _showLogSheet(context, exercise.id!),
                    );
                  },
                  childCount: provider.exercises.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        );
      },
    );
  }

  void _showLogSheet(BuildContext context, int exerciseId) {
    final cardColor = context.colors.card;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LogExerciseSheet(exerciseId: exerciseId),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: colors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises yet',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add scales, arpeggios, or any exercise\nyou want to keep practicing',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
