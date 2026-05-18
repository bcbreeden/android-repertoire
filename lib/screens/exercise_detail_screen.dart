import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/exercise_session.dart';
import '../providers/exercise_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/log_exercise_sheet.dart';
import 'exercise_form_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, _) {
        final current = provider.getExerciseById(exercise.id!) ?? exercise;
        final sessions = provider.sessionsForExercise(current.id!);

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.background,
            surfaceTintColor: Colors.transparent,
            title: Text(
              current.name,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseFormScreen(exercise: current),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, provider, current),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _InfoCard(exercise: current),
              ),
              if (sessions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                    child: Text(
                      'SESSION HISTORY',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final grouped = _groupByDate(sessions);
                      final dateKeys = grouped.keys.toList();
                      return _DayGroup(
                        date: dateKeys[index],
                        sessions: grouped[dateKeys[index]]!,
                      );
                    },
                    childCount: _groupByDate(sessions).length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showLogSheet(context, current.id!),
            backgroundColor: kGoldColor,
            foregroundColor: const Color(0xFF1A1200),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Log Session',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Map<DateTime, List<ExerciseSession>> _groupByDate(
      List<ExerciseSession> sessions) {
    final map = <DateTime, List<ExerciseSession>>{};
    for (final s in sessions) {
      final day =
          DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
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

  Future<void> _confirmDelete(
      BuildContext context, ExerciseProvider provider, Exercise e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Delete "${e.name}"? This will also remove all its sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteExercise(e.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Exercise exercise;
  const _InfoCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: kGoldColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (exercise.source != null && exercise.source!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                exercise.source!,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
              ),
            ),
          ],
          if (exercise.book != null && exercise.book!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  exercise.page != null
                      ? '${exercise.book}, p. ${exercise.page}'
                      : exercise.book!,
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: context.colors.divider, height: 1),
            const SizedBox(height: 12),
            Text(
              exercise.notes!,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Session history ──────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<ExerciseSession> sessions;
  const _DayGroup({required this.date, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = 'Today';
    } else if (date == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('MMMM d, yyyy').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.divider),
          ),
          child: Column(
            children: List.generate(sessions.length, (i) {
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                        height: 1,
                        color: context.colors.divider,
                        indent: 16,
                        endIndent: 16),
                  _SessionTile(session: sessions[i]),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ExerciseSession session;
  const _SessionTile({required this.session});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(session.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: kGoldColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (session.durationSeconds != null ||
              session.bpm != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (session.durationSeconds != null)
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(session.durationSeconds!),
                  ),
                if (session.bpm != null)
                  _Chip(
                    icon: Icons.speed,
                    label: '${session.bpm} BPM',
                  ),
              ],
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kGoldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGoldColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kGoldColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: kGoldColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
