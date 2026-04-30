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
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _composerController;
  late final TextEditingController _measuresController;
  late final TextEditingController _measuresLearnedController;
  late final TextEditingController _currentTempoController;
  late final TextEditingController _targetTempoController;
  late final TextEditingController _notesController;
  late String _status;

  final PageController _pageController = PageController();
  int _currentStep = 0;
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
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final keys = [_step1Key, _step2Key];
    if (!keys[_currentStep].currentState!.validate()) return;
    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    // For wizard, validate the current (last) step
    final keys = [_step1Key, _step2Key];
    final key = isEditing ? _editFormKey : keys[_currentStep];
    if (!key.currentState!.validate()) return;

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

  @override
  Widget build(BuildContext context) {
    return isEditing ? _buildEditForm() : _buildWizard();
  }

  // ── Full edit form ───────────────────────────────────────────────────────

  Widget _buildEditForm() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
        title: const Text(
          'Edit Piece',
          style: TextStyle(
              color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
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
        key: _editFormKey,
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Piece title is required'
                    : null,
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
                  if (n == null || n < 1) return 'Enter a valid number';
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kDividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: kTextSecondary),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kStageColors[_status] ?? kGoldColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kStageLabels[_status] ?? _status,
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    const Text(
                      'Change via Advance button',
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Wizard ───────────────────────────────────────────────────────────────

  Widget _buildWizard() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
        title: Text(
          _wizardTitles[_currentStep],
          style: const TextStyle(
              color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 2),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  static const _wizardTitles = [
    'What are you learning?',
    'Any notes?',
  ];

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              key: const Key('wizard-title'),
              controller: _nameController,
              label: 'Piece Title',
              hint: 'e.g. Moonlight Sonata',
              isRequired: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Piece title is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _composerController,
              label: 'Composer',
              hint: 'e.g. Ludwig van Beethoven',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: const Key('wizard-measures'),
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
                if (n == null || n < 1) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _targetTempoController,
              label: 'Target BPM',
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
            const SizedBox(height: 16),
            _buildTextField(
              controller: _currentTempoController,
              label: 'Current BPM',
              hint: 'Your current practice tempo',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Invalid BPM';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              label: 'Practice Notes',
              hint: 'Tips, reminders, tricky sections...',
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGoldColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGoldColor.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: kGoldColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use practice notes to track tricky sections, fingering tips, or reminders for your next session.',
                      style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    final isLast = _currentStep == 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextSecondary,
                    side: const BorderSide(color: kDividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : (isLast ? _save : _nextStep),
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
                    : Text(isLast ? 'Add Piece' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
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
      key: key,
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
}

// ── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: isDone || isActive ? kGoldColor : kDividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

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
