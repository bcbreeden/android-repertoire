import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/practice_session.dart';
import '../models/exercise_session.dart';
import '../providers/exercise_provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PieceProvider, ExerciseProvider>(
      builder: (context, pieces, exercises, _) {
        final allSongSessions = pieces.practiceSessions;
        final allExSessions = exercises.sessions;

        final totalSessions = allSongSessions.length + allExSessions.length;
        final totalSeconds = _totalSeconds(allSongSessions, allExSessions);
        final streak = pieces.streak;

        if (totalSessions == 0 && pieces.totalCount == 0) {
          return const _EmptyStats();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Summary row ───────────────────────────────────────────────
            _SummaryRow(
              totalSessions: totalSessions,
              totalSeconds: totalSeconds,
              streak: streak,
            ),
            const SizedBox(height: 16),

            // ── This week ─────────────────────────────────────────────────
            _ThisWeekCard(
              songSessions: allSongSessions,
              exSessions: allExSessions,
            ),
            const SizedBox(height: 16),

            // ── Last 7 days bar chart ──────────────────────────────────────
            _Last7DaysCard(
              songSessions: allSongSessions,
              exSessions: allExSessions,
            ),
            const SizedBox(height: 16),

            // ── Song progress ─────────────────────────────────────────────
            if (pieces.totalCount > 0) ...[
              _SongProgressCard(
                totalPieces: pieces.totalCount,
                repertoireCount: pieces.repertoireCount,
                stageCounts: pieces.stageCounts,
                overallPct: pieces.overallProgressPct,
              ),
              const SizedBox(height: 16),
            ],

            // ── Most practiced ────────────────────────────────────────────
            if (allSongSessions.isNotEmpty)
              _MostPracticedCard(
                sessions: allSongSessions,
                pieces: pieces,
              ),
          ],
        );
      },
    );
  }

  static int _totalSeconds(
      List<PracticeSession> song, List<ExerciseSession> ex) {
    int total = 0;
    for (final s in song) {
      total += s.durationSeconds ?? 0;
    }
    for (final s in ex) {
      total += s.durationSeconds ?? 0;
    }
    return total;
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 48, color: kTextSecondary),
          SizedBox(height: 12),
          Text(
            'No stats yet',
            style: TextStyle(
                color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Log a practice session to see your stats here.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int totalSessions;
  final int totalSeconds;
  final int streak;

  const _SummaryRow({
    required this.totalSessions,
    required this.totalSeconds,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Total Sessions',
          value: totalSessions.toString(),
          unit: totalSessions == 1 ? 'session' : 'sessions',
          icon: Icons.event_note,
          color: kTextPrimary,
        ),
        const SizedBox(width: 10),
        _StatBox(
          label: 'Total Time',
          value: _formatDuration(totalSeconds),
          icon: Icons.timer_outlined,
          color: kGoldColor,
        ),
        const SizedBox(width: 10),
        _StatBox(
          label: 'Streak',
          value: '${streak}d',
          icon: Icons.local_fire_department,
          color: const Color(0xFFFF6B35),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unit != null)
              Text(
                unit!,
                style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}

// ── This week card ─────────────────────────────────────────────────────────────

class _ThisWeekCard extends StatelessWidget {
  final List<PracticeSession> songSessions;
  final List<ExerciseSession> exSessions;

  const _ThisWeekCard({
    required this.songSessions,
    required this.exSessions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start of current week (Monday)
    final weekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));

    int sessions = 0;
    int seconds = 0;

    for (final s in songSessions) {
      if (!s.timestamp.isBefore(weekStart)) {
        sessions++;
        seconds += s.durationSeconds ?? 0;
      }
    }
    for (final s in exSessions) {
      if (!s.timestamp.isBefore(weekStart)) {
        sessions++;
        seconds += s.durationSeconds ?? 0;
      }
    }

    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final timeStr = seconds == 0
        ? '0 min'
        : h > 0
            ? '${h}h ${m}m'
            : '${m} min';

    return _Card(
      label: 'THIS WEEK',
      child: Row(
        children: [
          _InlineStatTile(
            value: '$sessions ${sessions == 1 ? 'session' : 'sessions'}',
            label: 'this week',
            icon: Icons.event_note,
            color: kTextPrimary,
          ),
          const SizedBox(width: 24),
          _InlineStatTile(
            value: timeStr,
            label: 'practiced this week',
            icon: Icons.timer_outlined,
            color: kGoldColor,
          ),
        ],
      ),
    );
  }
}

// ── Last 7 days bar chart ──────────────────────────────────────────────────────

class _Last7DaysCard extends StatelessWidget {
  final List<PracticeSession> songSessions;
  final List<ExerciseSession> exSessions;

  const _Last7DaysCard({
    required this.songSessions,
    required this.exSessions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final counts = <DateTime, int>{};
    for (final d in days) {
      counts[d] = 0;
    }

    bool _sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    for (final s in songSessions) {
      final day =
          DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }
    for (final s in exSessions) {
      final day =
          DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }

    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);

    return _Card(
      label: 'LAST 7 DAYS · sessions',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final count = counts[day] ?? 0;
          final isToday = _sameDay(day, now);
          final barFlex = maxCount == 0 ? 1 : (count == 0 ? 1 : count);
          final emptyFlex = maxCount == 0 ? 0 : (maxCount - count);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  if (count > 0)
                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: isToday ? kGoldColor : kTextPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 60,
                    child: Column(
                      children: [
                        Flexible(flex: emptyFlex == 0 ? 1 : emptyFlex, child: const SizedBox()),
                        Flexible(
                          flex: barFlex,
                          child: Container(
                            decoration: BoxDecoration(
                              color: count == 0
                                  ? kDividerColor
                                  : isToday
                                      ? kGoldColor
                                      : kGoldColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: TextStyle(
                      color: isToday ? kGoldColor : kTextSecondary,
                      fontSize: 10,
                      fontWeight:
                          isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Song progress card ─────────────────────────────────────────────────────────

class _SongProgressCard extends StatelessWidget {
  final int totalPieces;
  final int repertoireCount;
  final Map<String, int> stageCounts;
  final double overallPct;

  const _SongProgressCard({
    required this.totalPieces,
    required this.repertoireCount,
    required this.stageCounts,
    required this.overallPct,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: 'SONG PROGRESS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InlineStatTile(
                value: '$totalPieces ${totalPieces == 1 ? 'song' : 'songs'}',
                label: 'total',
                icon: Icons.library_music,
                color: kTextPrimary,
              ),
              const SizedBox(width: 24),
              _InlineStatTile(
                value: '$repertoireCount ${repertoireCount == 1 ? 'song' : 'songs'}',
                label: 'mastered',
                icon: Icons.star,
                color: kGoldColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Overall progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallPct / 100,
                    minHeight: 8,
                    backgroundColor: kDividerColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(kGoldColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${overallPct.round()}%',
                style: const TextStyle(
                    color: kGoldColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stage breakdown bar
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
                .map((stage) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kStageColors[stage] ?? kGoldColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${kStageLabels[stage] ?? stage}: ${stageCounts[stage]} ${stageCounts[stage] == 1 ? 'song' : 'songs'}',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 10),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String stage, int count, int total) {
    if (count == 0 || total == 0) return const SizedBox.shrink();
    final flex = (count / total * 100).round().clamp(1, 100);
    return Expanded(
      flex: flex,
      child: Container(color: kStageColors[stage] ?? kGoldColor),
    );
  }
}

// ── Most practiced card ────────────────────────────────────────────────────────

class _MostPracticedCard extends StatelessWidget {
  final List<PracticeSession> sessions;
  final PieceProvider pieces;

  const _MostPracticedCard({
    required this.sessions,
    required this.pieces,
  });

  @override
  Widget build(BuildContext context) {
    // Group by pieceId
    final counts = <int, int>{};
    for (final s in sessions) {
      counts[s.pieceId] = (counts[s.pieceId] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return _Card(
      label: 'MOST PRACTICED',
      child: Column(
        children: [
          for (int i = 0; i < top.length; i++) ...[
            if (i > 0)
              const Divider(height: 16, color: kDividerColor),
            _MostPracticedRow(
              rank: i + 1,
              piece: pieces.getPieceById(top[i].key),
              sessionCount: top[i].value,
            ),
          ],
        ],
      ),
    );
  }
}

class _MostPracticedRow extends StatelessWidget {
  final int rank;
  final dynamic piece; // Piece?
  final int sessionCount;

  const _MostPracticedRow({
    required this.rank,
    required this.piece,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final stageColor =
        piece != null ? (kStageColors[piece.status] ?? kGoldColor) : kGoldColor;
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$rank',
            style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          width: 3,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: stageColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                piece?.name ?? 'Unknown Song',
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              if (piece?.composer != null)
                Text(
                  piece!.composer!,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Text(
          '$sessionCount ${sessionCount == 1 ? 'session' : 'sessions'}',
          style: const TextStyle(color: kTextSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String label;
  final Widget child;

  const _Card({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InlineStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _InlineStatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            Icon(icon, size: 12, color: kTextSecondary),
            const SizedBox(width: 3),
            Text(label,
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
