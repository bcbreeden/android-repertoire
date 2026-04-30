import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

class LogPracticeSheet extends StatefulWidget {
  final int? pieceId;
  const LogPracticeSheet({super.key, this.pieceId});

  @override
  State<LogPracticeSheet> createState() => _LogPracticeSheetState();
}

class _LogPracticeSheetState extends State<LogPracticeSheet> {
  late final TextEditingController _measuresController;
  late final TextEditingController _bpmController;
  late final TextEditingController _notesController;
  int? _selectedPieceId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPieceId = widget.pieceId;
    _measuresController = TextEditingController();
    _bpmController = TextEditingController();
    _notesController = TextEditingController();

    // Pre-fill with current values if pieceId given
    if (widget.pieceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<PieceProvider>();
        final piece = provider.getPieceById(widget.pieceId!);
        if (piece != null) {
          if (piece.measuresLearned != null) {
            _measuresController.text = piece.measuresLearned.toString();
          }
          if (piece.currentTempo != null) {
            _bpmController.text = piece.currentTempo.toString();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _measuresController.dispose();
    _bpmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pieceId = _selectedPieceId;
    if (pieceId == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<PieceProvider>();
    await provider.logPractice(
      pieceId,
      measuresLearned: _measuresController.text.trim().isEmpty
          ? null
          : int.tryParse(_measuresController.text),
      currentBpm: _bpmController.text.trim().isEmpty
          ? null
          : int.tryParse(_bpmController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PieceProvider>();
    final pieces = provider.pieces;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: kGoldColor),
                const SizedBox(width: 8),
                const Text(
                  'Log Practice',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Piece picker (if no pieceId pre-selected)
            if (widget.pieceId == null) ...[
              const Text('Piece', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kDividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedPieceId,
                    isExpanded: true,
                    dropdownColor: kCardColor,
                    hint: const Text('Select a piece', style: TextStyle(color: kTextSecondary)),
                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    items: pieces.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedPieceId = id;
                        if (id != null) {
                          final piece = provider.getPieceById(id);
                          if (piece?.measuresLearned != null) {
                            _measuresController.text = piece!.measuresLearned.toString();
                          }
                          if (piece?.currentTempo != null) {
                            _bpmController.text = piece!.currentTempo.toString();
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _measuresController,
                    label: 'Measures Learned',
                    hint: 'e.g. 32',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _bpmController,
                    label: 'Current BPM',
                    hint: 'e.g. 72',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              controller: _notesController,
              label: 'Session Notes (optional)',
              hint: 'How did it go?',
              maxLines: 3,
              isNumeric: false,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSaving || _selectedPieceId == null) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: const Color(0xFF1A1200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: kGoldColor, strokeWidth: 2),
                      )
                    : const Text('Save Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumeric = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.multiline,
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLines: maxLines,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: kCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kGoldColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
