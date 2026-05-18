import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class StageProgressTracker extends StatelessWidget {
  final Piece piece;

  const StageProgressTracker({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(kStageOrder.length, (index) {
        final stage = kStageOrder[index];
        final isCurrentStage = piece.status == stage;
        final isPastStage = piece.stageIndex > index;
        final isFutureStage = piece.stageIndex < index;
        final timestamp = piece.timestampForStage(stage);
        final stageColor = kStageColors[stage] ?? kGoldColor;
        final isLast = index == kStageOrder.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    _StageNode(
                      color: stageColor,
                      isActive: isCurrentStage,
                      isCompleted: isPastStage,
                      isFuture: isFutureStage,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: isPastStage
                                ? stageColor.withOpacity(0.5)
                                : context.colors.divider,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content column
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: _StageContent(
                    stage: stage,
                    stageColor: stageColor,
                    isCurrentStage: isCurrentStage,
                    isPastStage: isPastStage,
                    isFutureStage: isFutureStage,
                    timestamp: timestamp,
                    piece: piece,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StageNode extends StatelessWidget {
  final Color color;
  final bool isActive;
  final bool isCompleted;
  final bool isFuture;

  const _StageNode({
    required this.color,
    required this.isActive,
    required this.isCompleted,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFuture
            ? context.colors.card
            : isActive
                ? color
                : color.withOpacity(0.3),
        border: Border.all(
          color: isFuture ? context.colors.divider : color,
          width: isActive ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 14, color: color)
            : isActive
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  )
                : null,
      ),
    );
  }
}

class _StageContent extends StatelessWidget {
  final String stage;
  final Color stageColor;
  final bool isCurrentStage;
  final bool isPastStage;
  final bool isFutureStage;
  final DateTime? timestamp;
  final Piece piece;

  const _StageContent({
    required this.stage,
    required this.stageColor,
    required this.isCurrentStage,
    required this.isPastStage,
    required this.isFutureStage,
    required this.timestamp,
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    final label = kStageLabels[stage] ?? stage;
    final description = kStageDescriptions[stage] ?? '';
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentStage
            ? stageColor.withOpacity(0.08)
            : isFutureStage
                ? Colors.transparent
                : context.colors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentStage
              ? stageColor.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isFutureStage ? context.colors.textSecondary : stageColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCurrentStage) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stageColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CURRENT',
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: isFutureStage ? context.colors.textSecondary.withOpacity(0.5) : context.colors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 11,
                  color: stageColor.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Reached ${dateFormat.format(timestamp!)}',
                  style: TextStyle(
                    color: stageColor.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                if (isCurrentStage) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${piece.daysAtStage}d)',
                    style: TextStyle(
                      color: stageColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
