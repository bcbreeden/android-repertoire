import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import '../widgets/piece_card.dart';
import '../widgets/stats_card.dart';
import 'piece_detail_screen.dart';

class PiecesTab extends StatefulWidget {
  const PiecesTab({super.key});

  @override
  State<PiecesTab> createState() => _PiecesTabState();
}

class _PiecesTabState extends State<PiecesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PieceProvider>().loadPieces();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PieceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: kGoldColor));
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(provider.error!,
                    style: const TextStyle(color: kTextSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.clearError();
                    provider.loadPieces();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: kGoldColor,
          backgroundColor: kCardColor,
          onRefresh: () => provider.loadPieces(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    StatsCard(
                      totalPieces: provider.totalCount,
                      repertoireCount: provider.repertoireCount,
                      streak: provider.streak,
                      stageCounts: provider.stageCounts,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                  child: _RecentMilestones(provider: provider)),
              SliverToBoxAdapter(child: _FilterBar(provider: provider)),
              if (provider.filteredPieces.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    isFiltered: provider.activeFilter != 'all',
                    onAdd: () => Navigator.of(context).pushNamed('/add'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final piece = provider.filteredPieces[index];
                      return PieceCard(
                        piece: piece,
                        lastPracticed:
                            provider.lastPracticeDateForPiece(piece.id!),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PieceDetailScreen(pieceId: piece.id!)),
                        ),
                      );
                    },
                    childCount: provider.filteredPieces.length,
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

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final PieceProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final filters = ['all', ...kStageOrder];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filters.map((filter) {
          final isSelected = provider.activeFilter == filter;
          final color = filter == 'all'
              ? kTextPrimary
              : (kStageColors[filter] ?? kGoldColor);
          final label =
              filter == 'all' ? 'All' : (kStageLabels[filter] ?? filter);
          final count = filter == 'all'
              ? provider.totalCount
              : (provider.stageCounts[filter] ?? 0);

          return FilterChip(
            selected: isSelected,
            label: Text(
              count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                color: isSelected ? color : kTextSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onSelected: (_) => provider.setFilter(filter),
            backgroundColor: kCardColor,
            selectedColor: color.withOpacity(0.3),
            checkmarkColor: color,
            side: BorderSide(
              color: isSelected ? color.withOpacity(0.5) : kDividerColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }
}

// ── Recent milestones ─────────────────────────────────────────────────────────

class _RecentMilestones extends StatelessWidget {
  final PieceProvider provider;
  const _RecentMilestones({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.recentMilestones,
      builder: (context, snapshot) {
        final milestones = snapshot.data;
        if (milestones == null || milestones.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Recent Milestones',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
                children: List.generate(milestones.length, (index) {
                  final milestone = milestones[index];
                  final piece = milestone['piece'] as Piece;
                  final stage = milestone['stage'] as String;
                  final timestamp = milestone['timestamp'] as DateTime;
                  final color = kStageColors[stage] ?? kGoldColor;
                  final label = kStageLabels[stage] ?? stage;
                  final dateStr = DateFormat('MMM d').format(timestamp);

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                            height: 1,
                            color: kDividerColor,
                            indent: 16,
                            endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    piece.name,
                                    style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(label,
                                      style: TextStyle(
                                          color: color, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(dateStr,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAdd;

  const _EmptyState({required this.isFiltered, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_list_off
                  : Icons.library_music_outlined,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No pieces in this stage' : 'No pieces yet',
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try selecting a different filter'
                  : 'Add your first piece to get started',
              style: const TextStyle(color: kTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Piece'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: const Color(0xFF1A1200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
