import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/exercise_session.dart';
import '../models/practice_session.dart';
import '../providers/exercise_provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import 'exercise_detail_screen.dart';
import 'practice_session_detail_screen.dart';

// ── Unified entry ──────────────────────────────────────────────────────────────

class _Entry {
  final DateTime timestamp;
  final PracticeSession? practiceSession;
  final ExerciseSession? exerciseSession;

  _Entry.practice(PracticeSession s)
      : timestamp = s.timestamp,
        practiceSession = s,
        exerciseSession = null;

  _Entry.exercise(ExerciseSession s)
      : timestamp = s.timestamp,
        exerciseSession = s,
        practiceSession = null;
}

// ── PracticeTab ────────────────────────────────────────────────────────────────

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_Entry> _buildEntries(
      PieceProvider pieceProvider, ExerciseProvider exerciseProvider) {
    final entries = [
      ...pieceProvider.practiceSessions.map(_Entry.practice),
      ...exerciseProvider.sessions.map(_Entry.exercise),
    ];
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Map<DateTime, List<_Entry>> _groupByDate(List<_Entry> entries) {
    final map = <DateTime, List<_Entry>>{};
    for (final e in entries) {
      final day =
          DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<PieceProvider, ExerciseProvider>(
      builder: (context, pieceProvider, exerciseProvider, _) {
        final entries = _buildEntries(pieceProvider, exerciseProvider);

        if (entries.isEmpty) {
          return _EmptyPractice(
            hasSongsOrExercises: pieceProvider.pieces.isNotEmpty ||
                exerciseProvider.exercises.isNotEmpty,
          );
        }

        final grouped = _groupByDate(entries);
        final dateKeys = grouped.keys.toList();

        return RefreshIndicator(
          color: kGoldColor,
          backgroundColor: kCardColor,
          onRefresh: () async {
            await pieceProvider.loadPieces();
            await exerciseProvider.loadExercises();
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    'Session History',
                    style: TextStyle(
                      color: kTextSecondary,
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
                    final date = dateKeys[index];
                    return _DayGroup(
                      date: date,
                      entries: grouped[date]!,
                      pieceProvider: pieceProvider,
                      exerciseProvider: exerciseProvider,
                    );
                  },
                  childCount: dateKeys.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        );
      },
    );
  }

}

// ── Summary card ──────────────────────────────────────────────────────────────

// ── Day group ─────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<_Entry> entries;
  final PieceProvider pieceProvider;
  final ExerciseProvider exerciseProvider;

  const _DayGroup({
    required this.date,
    required this.entries,
    required this.pieceProvider,
    required this.exerciseProvider,
  });

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
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDividerColor),
          ),
          child: Column(
            children: List.generate(entries.length, (i) {
              final entry = entries[i];
              return Column(
                children: [
                  if (i > 0)
                    const Divider(
                        height: 1,
                        color: kDividerColor,
                        indent: 16,
                        endIndent: 16),
                  if (entry.practiceSession != null)
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeSessionDetailScreen(
                              session: entry.practiceSession!),
                        ),
                      ),
                      child: _SessionTile(
                          session: entry.practiceSession!,
                          provider: pieceProvider),
                    )
                  else
                    InkWell(
                      onTap: () {
                        final exercise = exerciseProvider
                            .getExerciseById(entry.exerciseSession!.exerciseId);
                        if (exercise != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        }
                      },
                      child: _ExerciseTile(
                          session: entry.exerciseSession!,
                          exerciseProvider: exerciseProvider),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Song session tile ─────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final PracticeSession session;
  final PieceProvider provider;

  const _SessionTile({required this.session, required this.provider});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final piece = provider.getPieceById(session.pieceId);
    final pieceName = piece?.name ?? 'Unknown Song';
    final stageColor = piece != null
        ? (kStageColors[piece.status] ?? kGoldColor)
        : kTextSecondary;
    final timeStr = DateFormat('h:mm a').format(session.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: stageColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pieceName,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (piece?.composer != null)
                      Text(
                        piece!.composer!,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
          if (session.measuresLearned != null ||
              session.currentBpm != null ||
              session.durationSeconds != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (session.durationSeconds != null)
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(session.durationSeconds!),
                    color: stageColor,
                  ),
                if (session.measuresLearned != null)
                  _Chip(
                    icon: Icons.piano,
                    label: piece?.measures != null
                        ? '${session.measuresLearned} / ${piece!.measures} measures'
                        : '${session.measuresLearned} measures',
                    color: stageColor,
                  ),
                if (session.currentBpm != null)
                  _Chip(
                    icon: Icons.speed,
                    label: piece?.targetTempo != null
                        ? '${session.currentBpm} / ${piece!.targetTempo} BPM'
                        : '${session.currentBpm} BPM',
                    color: stageColor,
                  ),
              ],
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: const TextStyle(
                color: kTextSecondary,
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

// ── Exercise session tile ─────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  final ExerciseSession session;
  final ExerciseProvider exerciseProvider;

  const _ExerciseTile(
      {required this.session, required this.exerciseProvider});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseProvider.getExerciseById(session.exerciseId);
    final name = exercise?.name ?? 'Unknown Exercise';
    final timeStr = DateFormat('h:mm a').format(session.timestamp);
    const color = kGoldColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise?.source != null &&
                        exercise!.source!.isNotEmpty)
                      Text(
                        exercise.source!,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        'Exercise',
                        style:
                            TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
          if (session.bpm != null || session.durationSeconds != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (session.durationSeconds != null)
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(session.durationSeconds!),
                    color: color,
                  ),
                if (session.bpm != null)
                  _Chip(
                    icon: Icons.speed,
                    label: '${session.bpm} BPM',
                    color: color,
                  ),
              ],
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notes!,
              style: const TextStyle(
                color: kTextSecondary,
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
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPractice extends StatelessWidget {
  final bool hasSongsOrExercises;
  const _EmptyPractice({required this.hasSongsOrExercises});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSongsOrExercises ? Icons.edit_note : Icons.piano,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasSongsOrExercises ? 'No sessions yet' : 'Nothing added yet',
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasSongsOrExercises
                  ? 'Log a song or exercise session to start tracking your progress'
                  : 'Add songs or exercises before logging practice',
              style: const TextStyle(color: kTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
