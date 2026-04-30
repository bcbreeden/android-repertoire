import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/piece.dart';
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

  @override
  Widget build(BuildContext context) {
    final stageColor = kStageColors[piece.status] ?? kGoldColor;
    final isRepertoire = piece.isRepertoire;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isRepertoire
              ? const Color(0xFF1F1A0E)
              : kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRepertoire ? kGoldColor.withOpacity(0.5) : kDividerColor,
            width: isRepertoire ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          piece.name,
                          style: TextStyle(
                            color: isRepertoire ? kGoldLight : kTextPrimary,
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
                            style: const TextStyle(
                              color: kTextSecondary,
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
                  _StageBadge(
                    label: kStageLabels[piece.status] ?? piece.status,
                    color: stageColor,
                    isRepertoire: isRepertoire,
                  ),
                ],
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
      lastPracticed.year,
      lastPracticed.month,
      lastPracticed.day,
    );

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
      iconColor = kTextSecondary;
      icon = Icons.history;
    } else {
      dateStr = '${DateFormat('MMM d').format(lastPracticed)}, $timeStr';
      iconColor = kTextSecondary;
      icon = Icons.history;
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: const TextStyle(color: kTextSecondary, fontSize: 11),
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

class _ProgressIndicators extends StatelessWidget {
  final Piece piece;
  final Color stageColor;

  const _ProgressIndicators({required this.piece, required this.stageColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniProgress(
            label: 'Measures',
            value: piece.measuresLearnedPct / 100,
            display: piece.measuresLearned != null
                ? '${piece.measuresLearned}/${piece.measures}'
                : '${piece.measures} total',
            color: stageColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniProgress(
            label: 'Tempo',
            value: piece.tempoPct / 100,
            display: piece.currentTempo != null && piece.targetTempo != null
                ? '${piece.currentTempo}/${piece.targetTempo} BPM'
                : piece.currentTempo != null
                    ? '${piece.currentTempo} BPM'
                    : '—',
            color: stageColor,
          ),
        ),
      ],
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final String label;
  final double value;
  final String display;
  final Color color;

  const _MiniProgress({
    required this.label,
    required this.value,
    required this.display,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
            Text(
              display,
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: kDividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
