import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/piece_provider.dart';
import '../theme/app_colors.dart';
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
            backgroundColor: context.colors.background,
            appBar: AppBar(
              backgroundColor: context.colors.background,
              iconTheme: IconThemeData(color: context.colors.textPrimary),
            ),
            body: Center(
              child: Text(
                'Song not found',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
          );
        }

        final stageColor = kStageColors[piece.status] ?? kGoldColor;
        final isRepertoire = piece.isRepertoire;

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: isRepertoire
                ? const Color(0xFF1A1400)
                : context.colors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isRepertoire ? kGoldColor : context.colors.textPrimary,
            ),
            title: Text(
              piece.name,
              style: TextStyle(
                color: isRepertoire ? kGoldLight : context.colors.textPrimary,
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
    final cardColor = context.colors.card;
    final textPrimary = context.colors.textPrimary;
    final textSecondary = context.colors.textSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Promote to $newStageLabel?',
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          "Make sure you're ready — this can't be undone.",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
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
    final cardColor = context.colors.card;
    final textPrimary = context.colors.textPrimary;
    final textSecondary = context.colors.textSecondary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Delete Song?',
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${piece.name}"?$sessionWarning This cannot be undone.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: textSecondary)),
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
            : context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.divider),
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
                style: TextStyle(
                  color: context.colors.textSecondary,
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
          if (piece.measures != null)
            Row(
              children: [
                Icon(Icons.piano, size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${piece.measures} measures',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          if (piece.book != null && piece.book!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  piece.page != null
                      ? '${piece.book}, p. ${piece.page}'
                      : piece.book!,
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
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
    final showMeasures = piece.measures != null;
    final showTempo = piece.targetTempo != null;

    if (!showMeasures && !showTempo) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESS',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showMeasures)
                _DonutChart(
                  progress: piece.measuresLearnedPct / 100,
                  label: 'Measures',
                  valueText: piece.measuresLearned != null
                      ? '${piece.measuresLearned} / ${piece.measures}'
                      : '- / ${piece.measures}',
                  color: stageColor,
                ),
              if (showTempo)
                _DonutChart(
                  progress: piece.tempoPct / 100,
                  label: 'Tempo',
                  valueText: piece.currentTempo != null
                      ? '${piece.currentTempo} / ${piece.targetTempo} BPM'
                      : '- / ${piece.targetTempo} BPM',
                  color: stageColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final double progress;
  final String label;
  final String valueText;
  final Color color;

  const _DonutChart({
    required this.progress,
    required this.label,
    required this.valueText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: CustomPaint(
            painter: _DonutPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color,
              trackColor: context.colors.divider,
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _DonutPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc (clockwise from top)
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}

class _LogPracticeButton extends StatelessWidget {
  final int pieceId;

  const _LogPracticeButton({required this.pieceId});

  @override
  Widget build(BuildContext context) {
    final cardColor = context.colors.card;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: cardColor,
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
          color: context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Practice Notes',
                  style: TextStyle(
                    color: context.colors.textSecondary,
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
              style: TextStyle(
                color: context.colors.textPrimary,
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
