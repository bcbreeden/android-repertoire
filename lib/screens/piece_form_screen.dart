import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

class PieceFormScreen extends StatefulWidget {
  final Piece? piece;

  const PieceFormScreen({super.key, this.piece});

  @override
  State<PieceFormScreen> createState() => _PieceFormScreenState();
}

class _PieceFormScreenState extends State<PieceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _composerController;
  late final TextEditingController _measuresController;
  late final TextEditingController _measuresLearnedController;
  late final TextEditingController _currentTempoController;
  late final TextEditingController _targetTempoController;
  late final TextEditingController _notesController;
  late String _status;

  bool _isSaving = false;

  bool get isEditing => widget.piece != null;

  @override
  void initState() {
    super.initState();
    final p = widget.piece;
    _nameController = TextEditingController(text: p?.name ?? '');
    _composerController = TextEditingController(text: p?.composer ?? '');
    _measuresController =
        TextEditingController(text: p?.measures.toString() ?? '');
    _measuresLearnedController =
        TextEditingController(text: p?.measuresLearned?.toString() ?? '');
    _currentTempoController =
        TextEditingController(text: p?.currentTempo?.toString() ?? '');
    _targetTempoController =
        TextEditingController(text: p?.targetTempo?.toString() ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _status = p?.status ?? kStagelearning;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _composerController.dispose();
    _measuresController.dispose();
    _measuresLearnedController.dispose();
    _currentTempoController.dispose();
    _targetTempoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
        title: Text(
          isEditing ? 'Edit Piece' : 'Add Piece',
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              isEditing ? 'Save' : 'Add',
              style: TextStyle(
                color: _isSaving ? kTextSecondary : kGoldColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Basic Info'),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _nameController,
                label: 'Piece Title',
                hint: 'e.g. Moonlight Sonata',
                isRequired: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Piece title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _composerController,
                label: 'Composer',
                hint: 'e.g. Ludwig van Beethoven',
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _measuresController,
                label: 'Total Measures',
                hint: 'e.g. 64',
                isRequired: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Total measures is required';
                  }
                  final n = int.tryParse(v);
                  if (n == null || n < 1) {
                    return 'Enter a valid number of measures';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              _SectionLabel('Practice Progress'),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _measuresLearnedController,
                label: 'Measures Learned',
                hint: 'e.g. 32',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid number';
                  final total = int.tryParse(_measuresController.text);
                  if (total != null && n > total) {
                    return 'Cannot exceed total measures ($total)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _currentTempoController,
                      label: 'Current Tempo (BPM)',
                      hint: 'e.g. 60',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Invalid BPM';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _targetTempoController,
                      label: 'Target Tempo (BPM)',
                      hint: 'e.g. 120',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Invalid BPM';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel('Stage'),
              const SizedBox(height: 8),

              _StageSelector(
                value: _status,
                onChanged: (s) => setState(() => _status = s),
              ),

              const SizedBox(height: 20),
              _SectionLabel('Notes'),
              const SizedBox(height: 8),

              _buildTextField(
                controller: _notesController,
                label: 'Practice Notes',
                hint: 'Tips, reminders, tricky sections...',
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGoldColor,
                    foregroundColor: const Color(0xFF1A1200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: kGoldColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add Piece'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: kTextPrimary),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(color: kTextSecondary),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<PieceProvider>();
    final now = DateTime.now();

    final piece = Piece(
      id: widget.piece?.id,
      name: _nameController.text.trim(),
      composer: _composerController.text.trim().isEmpty
          ? null
          : _composerController.text.trim(),
      measures: int.parse(_measuresController.text),
      measuresLearned: _measuresLearnedController.text.trim().isEmpty
          ? null
          : int.parse(_measuresLearnedController.text),
      currentTempo: _currentTempoController.text.trim().isEmpty
          ? null
          : int.parse(_currentTempoController.text),
      targetTempo: _targetTempoController.text.trim().isEmpty
          ? null
          : int.parse(_targetTempoController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: _status,
      createdAt: widget.piece?.createdAt ?? now,
      updatedAt: now,
      learningAt: widget.piece?.learningAt,
      notePerfectionAt: widget.piece?.notePerfectionAt,
      dynamicsPerfectionAt: widget.piece?.dynamicsPerfectionAt,
      tempoPerfectionAt: widget.piece?.tempoPerfectionAt,
      repertoireAt: widget.piece?.repertoireAt,
    );

    if (isEditing) {
      await provider.updatePiece(piece);
    } else {
      await provider.addPiece(piece);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StageSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StageSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kStageOrder.map((stage) {
        final isSelected = value == stage;
        final color = kStageColors[stage] ?? kGoldColor;
        final label = kStageLabels[stage] ?? stage;

        return GestureDetector(
          onTap: () => onChanged(stage),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : kCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : kDividerColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : kTextSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : kTextSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
