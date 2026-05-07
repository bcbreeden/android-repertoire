import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import '../widgets/log_practice_sheet.dart';
import 'celebration_screen.dart';
import 'piece_form_screen.dart';

class PieceDetailScreen extends StatefulWidget {
  final int pieceId;

  const PieceDetailScreen({super.key, required this.pieceId});

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PieceProvider>(
      builder: (context, provider, _) {
        final piece = provider.getPieceById(widget.pieceId);

        if (piece == null) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              backgroundColor: kBackgroundColor,
              iconTheme: const IconThemeData(color: kTextPrimary),
            ),
            body: const Center(
              child: Text(
                'Song not found',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
          );
        }

        final stageColor = kStageColors[piece.status] ?? kGoldColor;
        final isRepertoire = piece.isRepertoire;

        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: isRepertoire
                ? const Color(0xFF1A1400)
                : kBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isRepertoire ? kGoldColor : kTextPrimary,
            ),
            title: Text(
              piece.name,
              style: TextStyle(
                color: isRepertoire ? kGoldLight : kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(context, piece),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, piece, provider),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero header
                _HeroHeader(piece: piece, stageColor: stageColor),

                // Progress bars
                _ProgressSection(piece: piece, stageColor: stageColor),

                // Log Practice button
                _LogPracticeButton(pieceId: piece.id!),

                // Promote button
                _StageActions(
                  piece: piece,
                  stageColor: stageColor,
                  onAdvance: () => _advanceStage(context, piece, provider),
                ),

                // Notes
                if (piece.notes != null && piece.notes!.isNotEmpty)
                  _NotesSection(notes: piece.notes!),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _advanceStage(
      BuildContext context, Piece piece, PieceProvider provider) async {
    final newStageLabel =
        kStageLabels[nextStage(piece.status)] ?? nextStage(piece.status);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text(
          'Promote to $newStageLabel?',
          style: const TextStyle(color: kTextPrimary),
        ),
        content: const Text(
          "Make sure you're ready — this can't be undone.",
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final updated = await provider.advanceStage(piece);
      if (updated != null && context.mounted) {
        if (updated.status == kStageRepertoire) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CelebrationScreen(pieceName: updated.name),
            ),
          );
        } else {
          final label = kStageLabels[updated.status] ?? updated.status;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Advanced to $label!'),
              backgroundColor: kStageColors[updated.status] ?? kGoldColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context, Piece piece) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PieceFormScreen(piece: piece)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Piece piece, PieceProvider provider) async {
    final sessionCount =
        provider.practiceSessions.where((s) => s.pieceId == piece.id).length;
    final sessionWarning = sessionCount > 0
        ? ' This will also delete $sessionCount practice ${sessionCount == 1 ? 'session' : 'sessions'}.'
        : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text(
          'Delete Song?',
          style: TextStyle(color: kTextPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${piece.name}"?$sessionWarning This cannot be undone.',
          style: const TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deletePiece(piece.id!);
      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HeroHeader extends StatelessWidget {
  final Piece piece;
  final Color stageColor;

  const _HeroHeader({required this.piece, required this.stageColor});

  @override
  Widget build(BuildContext context) {
    final isRepertoire = piece.isRepertoire;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: isRepertoire
            ? const Color(0xFF1F1A0E)
            : kSurfaceColor,
        border: const Border(
          bottom: BorderSide(color: kDividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (piece.composer != null && piece.composer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                piece.composer!,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stageColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stageColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRepertoire)
                      const Icon(Icons.star, size: 14, color: kGoldColor),
                    if (isRepertoire) const SizedBox(width: 4),
                    Text(
                      kStageLabels[piece.status] ?? piece.status,
                      style: TextStyle(
                        color: stageColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.piano, size: 14, color: kTextSecondary),
              const SizedBox(width: 4),
              Text(
                '${piece.measures} measures',
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Piece piece;
  final Color stageColor;

  const _ProgressSection({required this.piece, required this.stageColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressBar(
            label: 'Measures Learned',
            value: piece.measuresLearnedPct / 100,
            display: piece.measuresLearned != null
                ? '${piece.measuresLearned} / ${piece.measures} (${piece.measuresLearnedPct.toStringAsFixed(0)}%)'
                : '${piece.measures} total',
            color: stageColor,
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            label: 'Tempo',
            value: piece.tempoPct / 100,
            display: piece.currentTempo != null && piece.targetTempo != null
                ? '${piece.currentTempo} / ${piece.targetTempo} BPM (${piece.tempoPct.toStringAsFixed(0)}%)'
                : piece.currentTempo != null
                    ? '${piece.currentTempo} BPM (no target set)'
                    : 'Not set',
            color: stageColor,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final String display;
  final Color color;

  const _ProgressBar({
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
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
            ),
            Text(
              display,
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: kDividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _LogPracticeButton extends StatelessWidget {
  final int pieceId;

  const _LogPracticeButton({required this.pieceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: kCardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => LogPracticeSheet(pieceId: pieceId),
          ),
          icon: const Icon(Icons.edit_note, size: 18),
          label: const Text('Log Practice'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kGoldColor,
            side: const BorderSide(color: kGoldColor, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _StageActions extends StatelessWidget {
  final Piece piece;
  final Color stageColor;
  final VoidCallback onAdvance;

  const _StageActions({
    required this.piece,
    required this.stageColor,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = isLastStage(piece.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Advance button
          if (!isLast)
            ElevatedButton.icon(
              onPressed: onAdvance,
              icon: const Icon(Icons.arrow_upward),
              label: Text(
                'Promote to ${kStageLabels[nextStage(piece.status)] ?? 'Next Stage'}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: stageColor,
                foregroundColor: isLastStage(nextStage(piece.status))
                    ? const Color(0xFF1A1200)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: kGoldColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGoldColor.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: kGoldColor),
                  SizedBox(width: 8),
                  Text(
                    'In Repertoire!',
                    style: TextStyle(
                      color: kGoldColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
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
            const Row(
              children: [
                Icon(Icons.notes, size: 14, color: kTextSecondary),
                SizedBox(width: 6),
                Text(
                  'Practice Notes',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
