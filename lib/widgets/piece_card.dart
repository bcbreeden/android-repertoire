import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class PieceCard extends StatelessWidget {
  final Piece piece;
  final VoidCallback onTap;
  final DateTime? lastPracticed;

  const PieceCard({
    super.key,
    required this.piece,
    required this.onTap,
    this.lastPracticed,
  });

  bool get _needsPractice {
    if (lastPracticed == null) return true;
    return DateTime.now().difference(lastPracticed!).inDays >= 3;
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = kStageColors[piece.status] ?? kGoldColor;
    final isRepertoire = piece.isRepertoire;
    final progress = (piece.measuresLearnedPct / 100).clamp(0.0, 1.0);
    final needsPractice = _needsPractice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isRepertoire ? const Color(0xFF1F1A0E) : context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRepertoire ? kGoldColor.withOpacity(0.5) : context.colors.divider,
            width: isRepertoire ? 1.5 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needsPractice)
              Container(width: 3, color: Colors.amber),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        needsPractice ? 13 : 16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                piece.name,
                                style: TextStyle(
                                  color: isRepertoire ? kGoldLight : context.colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (piece.composer != null &&
                                  piece.composer!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  piece.composer!,
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              _LastPracticedRow(lastPracticed: lastPracticed),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StageBadge(
                          label: kStageLabels[piece.status] ?? piece.status,
                          color: stageColor,
                          isRepertoire: isRepertoire,
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: context.colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stageColor.withOpacity(0.55),
                    ),
                    minHeight: 3,
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
}

class _LastPracticedRow extends StatelessWidget {
  final DateTime? lastPracticed;

  const _LastPracticedRow({required this.lastPracticed});

  @override
  Widget build(BuildContext context) {
    if (lastPracticed == null) {
      return const Row(
        children: [
          Icon(Icons.schedule, size: 12, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'Never practiced',
            style: TextStyle(color: Colors.amber, fontSize: 11),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final practiceDay = DateTime(
      lastPracticed!.year,
      lastPracticed!.month,
      lastPracticed!.day,
    );
    final daysDiff = today.difference(practiceDay).inDays;
    final timeStr = DateFormat('h:mm a').format(lastPracticed!);

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
    } else if (daysDiff >= 3) {
      dateStr = '${DateFormat('MMM d').format(lastPracticed!)}, $timeStr';
      iconColor = Colors.amber;
      icon = Icons.schedule;
    } else {
      dateStr = '${DateFormat('MMM d').format(lastPracticed!)}, $timeStr';
      iconColor = context.colors.textSecondary;
      icon = Icons.history;
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: TextStyle(
            color: daysDiff >= 3 ? Colors.amber : context.colors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isRepertoire;

  const _StageBadge({
    required this.label,
    required this.color,
    required this.isRepertoire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRepertoire) ...[
            Icon(Icons.star, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
