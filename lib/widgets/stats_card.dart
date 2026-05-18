import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class StatsCard extends StatelessWidget {
  final int totalPieces;
  final int repertoireCount;
  final int streak;
  final Map<String, int> stageCounts;

  const StatsCard({
    super.key,
    required this.totalPieces,
    required this.repertoireCount,
    required this.streak,
    required this.stageCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _StatTile(
                label: 'Total Songs',
                value: totalPieces.toString(),
                icon: Icons.library_music,
                color: context.colors.textPrimary,
              ),
              const SizedBox(width: 16),
              _StatTile(
                label: 'Mastered',
                value: repertoireCount.toString(),
                icon: Icons.star,
                color: kGoldColor,
              ),
              const SizedBox(width: 16),
              _StatTile(
                label: 'Streak',
                value: '${streak}d',
                icon: Icons.local_fire_department,
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),
          if (totalPieces > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (final stage in kStageOrder)
                      _buildSegment(stage, stageCounts[stage] ?? 0, totalPieces),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: kStageOrder
                  .where((s) => (stageCounts[s] ?? 0) > 0)
                  .map((stage) => _StageLegend(
                        stage: stage,
                        count: stageCounts[stage] ?? 0,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(String stage, int count, int total) {
    if (count == 0 || total == 0) return const SizedBox.shrink();
    final flex = (count / total * 100).round().clamp(1, 100);
    return Expanded(
      flex: flex,
      child: Container(
        color: kStageColors[stage] ?? kGoldColor,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageLegend extends StatelessWidget {
  final String stage;
  final int count;

  const _StageLegend({required this.stage, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = kStageColors[stage] ?? kGoldColor;
    final label = kStageLabels[stage] ?? stage;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
