import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/practice_session.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

class PracticeSessionDetailScreen extends StatefulWidget {
  final PracticeSession session;
  const PracticeSessionDetailScreen({super.key, required this.session});

  @override
  State<PracticeSessionDetailScreen> createState() =>
      _PracticeSessionDetailScreenState();
}

class _PracticeSessionDetailScreenState
    extends State<PracticeSessionDetailScreen> {
  late final TextEditingController _measuresController;
  late final TextEditingController _bpmController;
  late final TextEditingController _minutesController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late DateTime _timestamp;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _timestamp = s.timestamp;
    _measuresController =
        TextEditingController(text: s.measuresLearned?.toString() ?? '');
    _bpmController =
        TextEditingController(text: s.currentBpm?.toString() ?? '');
    _minutesController = TextEditingController(
        text: s.durationSeconds != null
            ? (s.durationSeconds! ~/ 60).toString()
            : '');
    _notesController = TextEditingController(text: s.notes ?? '');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kGoldColor,
            surface: kCardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _timestamp = DateTime(
          picked.year, picked.month, picked.day,
          _timestamp.hour, _timestamp.minute, _timestamp.second,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kGoldColor,
            surface: kCardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _timestamp = DateTime(
          _timestamp.year, _timestamp.month, _timestamp.day,
          picked.hour, picked.minute,
        );
      });
    }
  }

  @override
  void dispose() {
    _measuresController.dispose();
    _bpmController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<PieceProvider>();
    final minutesText = _minutesController.text.trim();
    final updated = widget.session.copyWith(
      timestamp: _timestamp,
      measuresLearned: _measuresController.text.trim().isEmpty
          ? null
          : int.tryParse(_measuresController.text),
      clearMeasuresLearned: _measuresController.text.trim().isEmpty,
      currentBpm: _bpmController.text.trim().isEmpty
          ? null
          : int.tryParse(_bpmController.text),
      clearCurrentBpm: _bpmController.text.trim().isEmpty,
      durationSeconds: minutesText.isEmpty
          ? null
          : (int.tryParse(minutesText) ?? 0) * 60,
      clearDurationSeconds: minutesText.isEmpty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      clearNotes: _notesController.text.trim().isEmpty,
    );
    await provider.updatePracticeSession(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
      provider.clearError();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text('Delete Session',
            style: TextStyle(color: kTextPrimary)),
        content: const Text(
          'Delete this practice session? This cannot be undone.',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<PieceProvider>();
      await provider.deletePracticeSession(widget.session.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PieceProvider>();
    final piece = provider.getPieceById(widget.session.pieceId);
    final stageColor =
        piece != null ? (kStageColors[piece.status] ?? kGoldColor) : kGoldColor;
    final dateStr = DateFormat('MMM d, yyyy').format(_timestamp);
    final timeStr = DateFormat('h:mm a').format(_timestamp);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Session Details',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 40,
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
                          piece?.name ?? 'Unknown Song',
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (piece?.composer != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            piece!.composer!,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _DateTimeChip(
                              icon: Icons.calendar_today,
                              label: dateStr,
                              onTap: _pickDate,
                            ),
                            const SizedBox(width: 8),
                            _DateTimeChip(
                              icon: Icons.access_time,
                              label: timeStr,
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Edit fields ───────────────────────────────────────────────
            const Text(
              'EDIT SESSION',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (piece != null &&
                (piece.measures > 0 || piece.targetTempo != null)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.music_note,
                      size: 13, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${piece.measures} measures total',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12),
                  ),
                  if (piece.targetTempo != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.speed, size: 13, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${piece.targetTempo} BPM',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _measuresController,
                    label: 'Measures Learned',
                    hint: 'e.g. 32',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null) return 'Invalid';
                      if (piece != null && n > piece.measures) {
                        return 'Max ${piece.measures}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _bpmController,
                    label: 'Current BPM',
                    hint: 'e.g. 72',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null) return 'Invalid';
                      if (piece?.targetTempo != null &&
                          n > piece!.targetTempo!) {
                        return 'Max ${piece.targetTempo}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _minutesController,
                    label: 'Duration (min)',
                    hint: 'e.g. 30',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _field(
              controller: _notesController,
              label: 'Session Notes',
              hint: 'How did it go?',
              maxLines: 4,
              isNumeric: false,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: const Color(0xFF1A1200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: kGoldColor, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
          ),
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
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.multiline,
          inputFormatters:
              isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: kTextSecondary.withOpacity(0.5)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kDividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: kGoldColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 10, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}
