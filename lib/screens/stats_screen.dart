import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/practice_session.dart';
import '../models/exercise_session.dart';
import '../providers/exercise_provider.dart';
import '../providers/piece_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PieceProvider, ExerciseProvider>(
      builder: (context, pieces, exercises, _) {
        final allSongSessions = pieces.practiceSessions;
        final allExSessions = exercises.sessions;
        final totalSeconds = _totalSeconds(allSongSessions, allExSessions);
        final streak = pieces.streak;
        final isEmpty = pieces.totalCount == 0 &&
            allSongSessions.isEmpty &&
            allExSessions.isEmpty;

        final dataCard = _DataCard(
          pieceProvider: pieces,
          exerciseProvider: exercises,
        );

        if (isEmpty) {
          return Column(
            children: [
              const Expanded(child: _EmptyStats()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ThisWeekCard(
                    songSessions: allSongSessions,
                    exSessions: allExSessions),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: dataCard,
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Summary row ───────────────────────────────────────────────
            _SummaryRow(totalSeconds: totalSeconds, streak: streak),
            const SizedBox(height: 16),

            // ── This week ─────────────────────────────────────────────────
            _ThisWeekCard(songSessions: allSongSessions, exSessions: allExSessions),
            const SizedBox(height: 16),

            // ── Last 7 days bar chart ──────────────────────────────────────
            _Last7DaysCard(songSessions: allSongSessions, exSessions: allExSessions),
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
            if (allSongSessions.isNotEmpty) ...[
              _MostPracticedCard(sessions: allSongSessions, pieces: pieces),
              const SizedBox(height: 16),
            ],

            // ── Data management ───────────────────────────────────────────
            dataCard,
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

// ── Duration formatting ────────────────────────────────────────────────────────

/// Formats a minute count for the bar chart labels above each bar.
/// e.g. 45 → "45m", 60 → "1hr", 65 → "1hr 5m", 120 → "2hr"
String _formatBarLabel(int totalMinutes) {
  if (totalMinutes < 60) return '${totalMinutes}m';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? '${h}hr' : '${h}hr ${m}m';
}

String _formatPracticeDuration(int seconds) {
  if (seconds == 0) return '0 min';
  final totalMinutes = seconds ~/ 60;
  final totalHours = seconds ~/ 3600;
  if (totalHours >= 24) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    return h > 0 ? '${d}d ${h}h' : '${d}d';
  }
  if (totalHours > 0) {
    final m = (seconds % 3600) ~/ 60;
    return m > 0 ? '${totalHours}h ${m}m' : '${totalHours}h';
  }
  return '${totalMinutes}m';
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 48, color: context.colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No stats yet',
            style: TextStyle(
                color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Log a practice session to see your stats here.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int totalSeconds;
  final int streak;

  const _SummaryRow({
    required this.totalSeconds,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Total Time',
          value: _formatPracticeDuration(totalSeconds),
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
          color: context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
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
                    style: TextStyle(
                        color: context.colors.textSecondary,
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
                style: TextStyle(
                    color: context.colors.textSecondary,
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

class _ThisWeekCard extends StatefulWidget {
  final List<PracticeSession> songSessions;
  final List<ExerciseSession> exSessions;

  const _ThisWeekCard({
    required this.songSessions,
    required this.exSessions,
  });

  @override
  State<_ThisWeekCard> createState() => _ThisWeekCardState();
}

class _ThisWeekCardState extends State<_ThisWeekCard> {
  static const _kGoalKey = 'weekly_goal_hours';
  int? _goalHours;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _goalHours = prefs.getInt(_kGoalKey));
  }

  Future<void> _saveGoal(int? hours) async {
    final prefs = await SharedPreferences.getInstance();
    if (hours == null) {
      await prefs.remove(_kGoalKey);
    } else {
      await prefs.setInt(_kGoalKey, hours);
    }
    if (mounted) setState(() => _goalHours = hours);
  }

  int _weekSeconds() {
    final now = DateTime.now();
    // Rolling 7-day window: midnight 6 days ago through end of today.
    final windowStart = DateTime(now.year, now.month, now.day - 6);
    int seconds = 0;
    for (final s in widget.songSessions) {
      if (!s.timestamp.isBefore(windowStart)) seconds += s.durationSeconds ?? 0;
    }
    for (final s in widget.exSessions) {
      if (!s.timestamp.isBefore(windowStart)) seconds += s.durationSeconds ?? 0;
    }
    return seconds;
  }

  Future<void> _showGoalDialog() async {
    final result = await showDialog<_GoalResult>(
      context: context,
      builder: (_) => _GoalDialog(
        initialHours: _goalHours ?? 5,
        hasGoal: _goalHours != null,
      ),
    );
    if (result == null) return;
    await _saveGoal(result.clear ? null : result.hours);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _weekSeconds();
    final goalSeconds = _goalHours != null ? _goalHours! * 3600 : null;
    final progress = goalSeconds != null
        ? (seconds / goalSeconds).clamp(0.0, 1.0)
        : null;
    final goalMet = progress != null && progress >= 1.0;
    final progressColor = goalMet ? const Color(0xFF4CAF50) : kGoldColor;

    return _Card(
      label: 'LAST 7 DAYS',
      action: IconButton(
        icon: Icon(
          _goalHours != null ? Icons.flag : Icons.flag_outlined,
          size: 15,
          color: _goalHours != null ? kGoldColor : context.colors.textSecondary,
        ),
        onPressed: _showGoalDialog,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Set 7-day goal',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineStatTile(
            value: _formatPracticeDuration(seconds),
            label: goalSeconds != null
                ? 'of ${_goalHours}h goal'
                : 'past 7 days',
            icon: Icons.timer_outlined,
            color: goalMet ? progressColor : kGoldColor,
          ),
          if (goalSeconds != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: context.colors.divider,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  goalMet ? 'Done!' : '${(progress! * 100).round()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Weekly goal dialog ──────────────────────────────────────────────────────────

class _GoalResult {
  final int hours;
  final bool clear;
  const _GoalResult.set(this.hours) : clear = false;
  const _GoalResult.cleared() : hours = 0, clear = true;
}

class _GoalDialog extends StatefulWidget {
  final int initialHours;
  final bool hasGoal;

  const _GoalDialog({required this.initialHours, required this.hasGoal});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late double _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final h = _hours.round();
    return AlertDialog(
      backgroundColor: context.colors.card,
      title: Text(
        'Weekly Practice Goal',
        style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$h ${h == 1 ? 'hour' : 'hours'} per week',
            style: const TextStyle(
              color: kGoldColor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kGoldColor,
              inactiveTrackColor: context.colors.divider,
              thumbColor: kGoldColor,
              overlayColor: kGoldColor.withOpacity(0.15),
            ),
            child: Slider(
              value: _hours,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) => setState(() => _hours = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1h', style: TextStyle(color: context.colors.textSecondary, fontSize: 11)),
              Text('20h', style: TextStyle(color: context.colors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.hasGoal)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _GoalResult.cleared()),
            child: Text('Clear',
                style: TextStyle(color: context.colors.textSecondary)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: context.colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, _GoalResult.set(_hours.round())),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGoldColor,
            foregroundColor: const Color(0xFF1A1200),
          ),
          child: const Text('Set Goal'),
        ),
      ],
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
    final today = DateTime(now.year, now.month, now.day);
    // weekday: Mon=1 … Sun=7. Days since last Sunday:
    final daysSinceSunday = today.weekday % 7;
    final sunday = today.subtract(Duration(days: daysSinceSunday));
    final days = List.generate(7, (i) => sunday.add(Duration(days: i)));

    // seconds per day
    final minuteMap = <DateTime, int>{};
    for (final d in days) {
      minuteMap[d] = 0;
    }

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    for (final s in songSessions) {
      final day =
          DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      if (minuteMap.containsKey(day)) {
        minuteMap[day] = minuteMap[day]! + (s.durationSeconds ?? 0);
      }
    }
    for (final s in exSessions) {
      final day =
          DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      if (minuteMap.containsKey(day)) {
        minuteMap[day] = minuteMap[day]! + (s.durationSeconds ?? 0);
      }
    }

    final maxSeconds = minuteMap.values.fold(0, (a, b) => a > b ? a : b);

    return _Card(
      label: 'THIS WEEK · time',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final secs = minuteMap[day] ?? 0;
          final mins = secs ~/ 60;
          final isToday = sameDay(day, now);
          final barFlex = maxSeconds == 0 ? 1 : (secs == 0 ? 1 : secs);
          final emptyFlex = maxSeconds == 0 ? 0 : (maxSeconds - secs);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  if (mins > 0)
                    Text(
                      _formatBarLabel(mins),
                      style: TextStyle(
                        color: isToday ? kGoldColor : context.colors.textPrimary,
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
                        if (emptyFlex > 0)
                          Expanded(flex: emptyFlex, child: const SizedBox()),
                        Expanded(
                          flex: barFlex,
                          child: Container(
                            decoration: BoxDecoration(
                              color: secs == 0
                                  ? context.colors.divider
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
                      color: isToday ? kGoldColor : context.colors.textSecondary,
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
                color: context.colors.textPrimary,
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
                    backgroundColor: context.colors.divider,
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
                          style: TextStyle(
                              color: context.colors.textSecondary, fontSize: 10),
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
    // Group total durationSeconds by pieceId
    final seconds = <int, int>{};
    for (final s in sessions) {
      seconds[s.pieceId] = (seconds[s.pieceId] ?? 0) + (s.durationSeconds ?? 0);
    }
    final sorted = seconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return _Card(
      label: 'MOST PRACTICED',
      child: Column(
        children: [
          for (int i = 0; i < top.length; i++) ...[
            if (i > 0)
              Divider(height: 16, color: context.colors.divider),
            _MostPracticedRow(
              rank: i + 1,
              piece: pieces.getPieceById(top[i].key),
              totalSeconds: top[i].value,
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
  final int totalSeconds;

  const _MostPracticedRow({
    required this.rank,
    required this.piece,
    required this.totalSeconds,
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
            style: TextStyle(
                color: context.colors.textSecondary,
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
                style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              if (piece?.composer != null)
                Text(
                  piece!.composer!,
                  style: TextStyle(
                      color: context.colors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Text(
          _formatPracticeDuration(totalSeconds),
          style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? action;

  const _Card({required this.label, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (action != null) ...[
                const Spacer(),
                action!,
              ],
            ],
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
            Icon(icon, size: 12, color: context.colors.textSecondary),
            const SizedBox(width: 3),
            Text(label,
                style:
                    TextStyle(color: context.colors.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ── Data management card ───────────────────────────────────────────────────────

class _DataCard extends StatefulWidget {
  final PieceProvider pieceProvider;
  final ExerciseProvider exerciseProvider;

  const _DataCard({
    required this.pieceProvider,
    required this.exerciseProvider,
  });

  @override
  State<_DataCard> createState() => _DataCardState();
}

class _DataCardState extends State<_DataCard> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final json = jsonEncode(data);
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/repertoire_backup_$timestamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Repertoire Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    Map<String, dynamic> data;
    try {
      final content = await File(path).readAsString();
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid file — could not read backup'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!_isValidBackup(data)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File does not appear to be a Repertoire backup'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final pieceCount = (data['pieces'] as List).length;
    final sessionCount = (data['practice_sessions'] as List).length;
    final exerciseCount = (data['exercises'] as List).length;
    final cardColor = context.colors.card;
    final textPrimary = context.colors.textPrimary;
    final textSecondary = context.colors.textSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Replace all data?',
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          'Your current data will be replaced with:\n\n'
          '• $pieceCount ${pieceCount == 1 ? 'song' : 'songs'}\n'
          '• $sessionCount practice ${sessionCount == 1 ? 'session' : 'sessions'}\n'
          '• $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}\n\n'
          'This cannot be undone.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    try {
      await DatabaseHelper.instance.importAllData(data);
      await Future.wait([
        widget.pieceProvider.loadPieces(),
        widget.exerciseProvider.loadExercises(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  bool _isValidBackup(Map<String, dynamic> data) {
    return data['version'] is int &&
        data['pieces'] is List &&
        data['practice_sessions'] is List &&
        data['exercises'] is List &&
        data['exercise_sessions'] is List;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isExporting || _isImporting;
    return _Card(
      label: 'DATA',
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kGoldColor),
                    )
                  : const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kGoldColor,
                side: const BorderSide(color: kGoldColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : _import,
              icon: _isImporting
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.colors.textSecondary),
                    )
                  : const Icon(Icons.download_outlined, size: 16),
              label: const Text('Import'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
                side: BorderSide(color: context.colors.divider),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
