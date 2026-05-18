import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/piece_card.dart';
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
                    style: TextStyle(color: context.colors.textSecondary),
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
          backgroundColor: context.colors.card,
          onRefresh: () => provider.loadPieces(),
          child: CustomScrollView(
            key: const Key('pieces_scroll'),
            slivers: [
              SliverToBoxAdapter(child: _FilterBar(provider: provider)),
              if (provider.filteredPieces.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    isFiltered: provider.activeFilter != 'all',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i < filters.length - 1 ? 6 : 0),
              child: _buildChip(context, filters[i], provider),
            ),
        ],
      ),
    );
  }

  FilterChip _buildChip(BuildContext context, String filter, PieceProvider provider) {
    final isSelected = provider.activeFilter == filter;
    final color = filter == 'all'
        ? context.colors.textPrimary
        : (kStageColors[filter] ?? kGoldColor);
    final label = filter == 'all' ? 'All' : (kStageLabels[filter] ?? filter);
    final count = filter == 'all'
        ? provider.totalCount
        : (provider.stageCounts[filter] ?? 0);

    return FilterChip(
      selected: isSelected,
      label: Text(
        count > 0 ? '$label ($count)' : label,
        style: TextStyle(
          color: isSelected ? color : context.colors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onSelected: (_) => provider.setFilter(filter),
      backgroundColor: context.colors.card,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color.withOpacity(0.5) : context.colors.divider,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;

  const _EmptyState({required this.isFiltered});

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
              color: context.colors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No songs in this stage' : 'No songs yet',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try selecting a different filter'
                  : 'Add your first song to get started',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
