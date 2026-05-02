import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/practice_session.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import '../widgets/log_practice_sheet.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PieceProvider>(
      builder: (context, provider, _) {
        final sessions = provider.practiceSessions;

        if (sessions.isEmpty) {
          return _EmptyPractice(
            hasPieces: provider.pieces.isNotEmpty,
            onLog: () => _showLogSheet(context),
          );
        }

        // Group sessions by date
        final grouped = _groupByDate(sessions);
        final dateKeys = grouped.keys.toList();

        return RefreshIndicator(
          color: kGoldColor,
          backgroundColor: kCardColor,
          onRefresh: () => provider.loadPieces(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryCard(sessions: sessions),
              ),
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
                    final daySessions = grouped[date]!;
                    return _DayGroup(
                      date: date,
                      sessions: daySessions,
                      provider: provider,
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

  Map<DateTime, List<PracticeSession>> _groupByDate(
      List<PracticeSession> sessions) {
    final map = <DateTime, List<PracticeSession>>{};
    for (final s in sessions) {
      final day = DateTime(
          s.timestamp.year, s.timestamp.month, s.timestamp.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LogPracticeSheet(),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<PracticeSession> sessions;
  const _SummaryCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = sessions.where((s) =>
        s.timestamp.isAfter(weekStart.subtract(const Duration(days: 1)))).length;
    final today = sessions.where((s) {
      final d = s.timestamp;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDividerColor),
      ),
      child: Row(
        children: [
          _StatCell(label: 'Today', value: today.toString(),
              icon: Icons.today, color: kGoldColor),
          _divider(),
          _StatCell(label: 'This Week', value: thisWeek.toString(),
              icon: Icons.date_range, color: const Color(0xFF64B5F6)),
          _divider(),
          _StatCell(label: 'Total', value: sessions.length.toString(),
              icon: Icons.history, color: const Color(0xFF81C784)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 8),
        color: kDividerColor,
      );
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
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
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Day group ─────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<PracticeSession> sessions;
  final PieceProvider provider;

  const _DayGroup({
    required this.date,
    required this.sessions,
    required this.provider,
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
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDividerColor),
          ),
          child: Column(
            children: List.generate(sessions.length, (i) {
              final session = sessions[i];
              return Dismissible(
                key: ValueKey(session.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade800,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  provider.deletePracticeSession(session.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Column(
                  children: [
                    if (i > 0)
                      const Divider(
                          height: 1,
                          color: kDividerColor,
                          indent: 16,
                          endIndent: 16),
                    _SessionTile(session: session, provider: provider),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final PracticeSession session;
  final PieceProvider provider;

  const _SessionTile({required this.session, required this.provider});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
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
                    label: '${session.measuresLearned} measures',
                    color: stageColor,
                  ),
                if (session.currentBpm != null)
                  _Chip(
                    icon: Icons.speed,
                    label: '${session.currentBpm} BPM',
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
  final bool hasPieces;
  final VoidCallback onLog;
  const _EmptyPractice({required this.hasPieces, required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPieces ? Icons.edit_note : Icons.piano,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasPieces ? 'No sessions yet' : 'No songs yet',
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasPieces
                  ? 'Log your first practice session to start tracking your progress'
                  : 'Add a song in the Songs tab before logging practice',
              style: const TextStyle(color: kTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (hasPieces) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onLog,
                icon: const Icon(Icons.add),
                label: const Text('Log Practice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: const Color(0xFF1A1200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
