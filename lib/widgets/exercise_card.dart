import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final DateTime? lastPracticed;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onPlay,
    this.lastPracticed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise.source != null &&
                        exercise.source!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        exercise.source!,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (lastPracticed != null) ...[
                      const SizedBox(height: 4),
                      _LastPracticedRow(lastPracticed: lastPracticed!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kGoldColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGoldColor.withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 13, color: kGoldColor),
                      SizedBox(width: 3),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: kGoldColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastPracticedRow extends StatelessWidget {
  final DateTime lastPracticed;
  const _LastPracticedRow({required this.lastPracticed});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final practiceDay = DateTime(
        lastPracticed.year, lastPracticed.month, lastPracticed.day);
    final timeStr = DateFormat('h:mm a').format(lastPracticed);

    String dateStr;
    Color iconColor;
    IconData icon;

    if (practiceDay == today) {
      dateStr = 'Today, $timeStr';
      iconColor = Colors.green;
      icon = Icons.check_circle;
    } else if (practiceDay == yesterday) {
      dateStr = 'Yesterday, $timeStr';
      iconColor = context.colors.textSecondary;
      icon = Icons.history;
    } else {
      dateStr = '${DateFormat('MMM d').format(lastPracticed)}, $timeStr';
      iconColor = context.colors.textSecondary;
      icon = Icons.history;
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(dateStr,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
