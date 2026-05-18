import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/book_field.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;
  const ExerciseFormScreen({super.key, this.exercise});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sourceController;
  late final TextEditingController _notesController;
  late final TextEditingController _pageController;
  TextEditingController? _bookFieldController;
  bool _isSaving = false;

  bool get isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _sourceController = TextEditingController(text: e?.source ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _pageController = TextEditingController(text: e?.page?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ExerciseProvider>();

    final name = _nameController.text.trim();
    final source = _sourceController.text.trim();
    final notes = _notesController.text.trim();
    final book = (_bookFieldController?.text ?? '').trim();
    final page = _pageController.text.trim().isEmpty
        ? null
        : int.tryParse(_pageController.text);
    final now = DateTime.now();

    if (isEditing) {
      final updated = widget.exercise!.copyWith(
        name: name,
        source: source.isEmpty ? null : source,
        notes: notes.isEmpty ? null : notes,
        book: book.isEmpty ? null : book,
        page: page,
        updatedAt: now,
        clearSource: source.isEmpty,
        clearNotes: notes.isEmpty,
        clearBook: book.isEmpty,
        clearPage: page == null,
      );
      await provider.updateExercise(updated);
    } else {
      final exercise = Exercise(
        name: name,
        source: source.isEmpty ? null : source,
        notes: notes.isEmpty ? null : notes,
        book: book.isEmpty ? null : book,
        page: page,
        createdAt: now,
        updatedAt: now,
      );
      await provider.addExercise(exercise);
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditing ? 'Edit Exercise' : 'New Exercise',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _label(context, 'Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              autofocus: !isEditing,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: _inputDecoration(context, 'e.g. Scales, Hanon No. 1'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            _label(context, 'Source (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sourceController,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: _inputDecoration(context, 'e.g. Hanon, Czerny, Original'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            _label(context, 'Book (optional)'),
            const SizedBox(height: 6),
            BookField(
              initialValue: widget.exercise?.book ?? '',
              bookNames: context.watch<ExerciseProvider>().bookNames,
              onControllerReady: (c) => _bookFieldController = c,
            ),
            const SizedBox(height: 20),
            _label(context, 'Page Number (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pageController,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: _inputDecoration(context, 'e.g. 42'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            _label(context, 'Notes (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: _inputDecoration(context, 'Any notes about this exercise…'),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 36),
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
                    : Text(isEditing ? 'Save Changes' : 'Add Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
      );

  InputDecoration _inputDecoration(BuildContext context, String hint) => InputDecoration(
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
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
