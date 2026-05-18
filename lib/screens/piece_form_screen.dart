import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/piece_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/book_field.dart';

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
  late final TextEditingController _pageNumberController;
  // Book field uses Autocomplete's internal controller; we store a reference.
  TextEditingController? _bookFieldController;
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
        TextEditingController(text: p?.measures?.toString() ?? '');
    _measuresLearnedController =
        TextEditingController(text: p?.measuresLearned?.toString() ?? '');
    _currentTempoController =
        TextEditingController(text: p?.currentTempo?.toString() ?? '');
    _targetTempoController =
        TextEditingController(text: p?.targetTempo?.toString() ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _pageNumberController = TextEditingController(text: p?.page?.toString() ?? '');
    _status = p?.status ?? kStageLearning;
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
    _pageNumberController.dispose();
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

    final bookText = (_bookFieldController?.text ?? '').trim();
    final piece = Piece(
      id: widget.piece?.id,
      name: _nameController.text.trim(),
      composer: _composerController.text.trim().isEmpty
          ? null
          : _composerController.text.trim(),
      measures: _measuresController.text.trim().isEmpty
          ? null
          : int.tryParse(_measuresController.text),
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
      book: bookText.isEmpty ? null : bookText,
      page: _pageNumberController.text.trim().isEmpty
          ? null
          : int.tryParse(_pageNumberController.text),
      status: _status,
      createdAt: widget.piece?.createdAt ?? now,
      updatedAt: now,
      learningAt: widget.piece?.learningAt,
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
    return isEditing ? _buildEditForm(context) : _buildWizard(context);
  }

  // ── Full edit form ───────────────────────────────────────────────────────

  Widget _buildEditForm(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(
          'Edit Song',
          style: TextStyle(
              color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? context.colors.textSecondary : kGoldColor,
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
              _SectionLabel(text: 'Basic Info'),
              const SizedBox(height: 8),
              _buildTextField(
                context: context,
                controller: _nameController,
                label: 'Song Title',
                hint: 'e.g. Moonlight Sonata',
                isRequired: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Song title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                context: context,
                controller: _composerController,
                label: 'Composer',
                hint: 'e.g. Ludwig van Beethoven',
              ),
              const SizedBox(height: 12),
              BookField(
                initialValue: widget.piece?.book ?? '',
                bookNames: context.watch<PieceProvider>().bookNames,
                onControllerReady: (c) => _bookFieldController = c,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                context: context,
                controller: _pageNumberController,
                label: 'Page Number',
                hint: 'e.g. 42',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                context: context,
                controller: _measuresController,
                label: 'Total Measures',
                hint: 'e.g. 64',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SectionLabel(text: 'Practice Progress'),
              const SizedBox(height: 8),
              _buildTextField(
                context: context,
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
                      context: context,
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
                      context: context,
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
              _SectionLabel(text: 'Stage'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: context.colors.textSecondary),
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
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Change via Advance button',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(text: 'Notes'),
              const SizedBox(height: 8),
              _buildTextField(
                context: context,
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

  Widget _buildWizard(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(
          _wizardTitles[_currentStep],
          style: TextStyle(
              color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
                _buildStep1(context),
                _buildStep2(context),
              ],
            ),
          ),
          _buildNavButtons(context),
        ],
      ),
    );
  }

  static const _wizardTitles = [
    'What are you learning?',
    'Any notes?',
  ];

  Widget _buildStep1(BuildContext context) {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              context: context,
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
              context: context,
              controller: _composerController,
              label: 'Composer',
              hint: 'e.g. Ludwig van Beethoven',
            ),
            const SizedBox(height: 16),
            BookField(
              initialValue: widget.piece?.book ?? '',
              bookNames: context.watch<PieceProvider>().bookNames,
              onControllerReady: (c) => _bookFieldController = c,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: _pageNumberController,
              label: 'Page Number',
              hint: 'e.g. 42',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              key: const Key('wizard-measures'),
              controller: _measuresController,
              label: 'Total Measures',
              hint: 'e.g. 64',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
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
              context: context,
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

  Widget _buildStep2(BuildContext context) {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              context: context,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: kGoldColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use practice notes to track tricky sections, fingering tips, or reminders for your next session.',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.5),
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

  Widget _buildNavButtons(BuildContext context) {
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
                    foregroundColor: context.colors.textSecondary,
                    side: BorderSide(color: context.colors.divider),
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
                    : Text(isLast ? 'Add Song' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
    required BuildContext context,
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
      style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: context.colors.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textSecondary.withOpacity(0.5)),
        filled: true,
        fillColor: context.colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.divider),
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
                  color: isDone || isActive ? kGoldColor : context.colors.divider,
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

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
