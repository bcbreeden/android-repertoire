import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

// Timer state is intentionally duplicated from log_practice_sheet.dart
// so the two sheets remain independent.
enum _TimerState { idle, running, paused, stopped }

class LogExerciseSheet extends StatefulWidget {
  final int exerciseId;
  const LogExerciseSheet({super.key, required this.exerciseId});

  @override
  State<LogExerciseSheet> createState() => _LogExerciseSheetState();
}

class _LogExerciseSheetState extends State<LogExerciseSheet>
    with WidgetsBindingObserver {
  late final TextEditingController _bpmController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  _TimerState _timerState = _TimerState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bpmController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _timerState == _TimerState.running &&
        _startedAt != null) {
      setState(() {
        _elapsed = _accumulated + DateTime.now().difference(_startedAt!);
        _accumulated = _elapsed;
        _startedAt = DateTime.now();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _bpmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _accumulated = Duration.zero;
    _startedAt = DateTime.now();
    setState(() {
      _timerState = _TimerState.running;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    _ticker = null;
    _accumulated = _elapsed;
    _startedAt = null;
    setState(() => _timerState = _TimerState.paused);
  }

  void _resumeTimer() {
    _startedAt = DateTime.now();
    setState(() => _timerState = _TimerState.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    _accumulated = _elapsed;
    _startedAt = null;
    setState(() => _timerState = _TimerState.stopped);
  }

  int? get _durationSeconds {
    if (_timerState == _TimerState.idle) return null;
    return _elapsed.inSeconds > 0 ? _elapsed.inSeconds : null;
  }

  Future<void> _save() async {
    if (_timerState == _TimerState.running ||
        _timerState == _TimerState.paused) {
      _stopTimer();
    }

    setState(() => _isSaving = true);
    final provider = context.read<ExerciseProvider>();
    await provider.logSession(
      widget.exerciseId,
      bpm: _bpmController.text.trim().isEmpty
          ? null
          : int.tryParse(_bpmController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      durationSeconds: _durationSeconds,
    );
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
    final provider = context.watch<ExerciseProvider>();
    final exercise = provider.getExerciseById(widget.exerciseId);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 36 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: kGoldColor),
                  const SizedBox(width: 8),
                  Text(
                    'Log Exercise',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timer
              _TimerDisplay(
                elapsed: _elapsed,
                state: _timerState,
                onStart: _startTimer,
                onPause: _pauseTimer,
                onResume: _resumeTimer,
                onStop: _stopTimer,
              ),
              const SizedBox(height: 24),

              // Exercise info row
              Text('Exercise',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise?.name ?? '—',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (exercise?.source != null &&
                        exercise!.source!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        exercise.source!,
                        style: TextStyle(
                            color: context.colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // BPM field
              _field(
                context: context,
                controller: _bpmController,
                label: 'BPM',
                hint: 'e.g. 120',
              ),
              const SizedBox(height: 12),

              // Notes field
              _field(
                context: context,
                controller: _notesController,
                label: 'Session Notes (optional)',
                hint: 'How did it go?',
                maxLines: 3,
                isNumeric: false,
              ),
              const SizedBox(height: 20),

              // Save button
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
                      : const Text('Save Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumeric = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.multiline,
          inputFormatters:
              isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLines: maxLines,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: context.colors.textSecondary.withOpacity(0.5)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Timer display (mirrored from log_practice_sheet.dart) ────────────────────

class _TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final _TimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _TimerDisplay({
    required this.elapsed,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = state == _TimerState.running;
    final isPaused = state == _TimerState.paused;
    final isStopped = state == _TimerState.stopped;

    Color borderColor;
    Color bgColor;
    if (isRunning) {
      borderColor = kGoldColor.withOpacity(0.4);
      bgColor = kGoldColor.withOpacity(0.08);
    } else if (isPaused) {
      borderColor = Colors.orangeAccent.withOpacity(0.4);
      bgColor = Colors.orangeAccent.withOpacity(0.06);
    } else if (isStopped) {
      borderColor = const Color(0xFF4CAF50).withOpacity(0.4);
      bgColor = context.colors.card;
    } else {
      borderColor = context.colors.divider;
      bgColor = context.colors.card;
    }

    Color timerColor = isRunning
        ? kGoldColor
        : isPaused
            ? Colors.orangeAccent
            : isStopped
                ? const Color(0xFF4CAF50)
                : context.colors.textSecondary;

    String subtitle = isStopped
        ? 'Session complete'
        : isRunning
            ? 'Practice in progress'
            : isPaused
                ? 'Paused'
                : 'Start the timer when you begin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRunning)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    color: kGoldColor,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isPaused)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.pause, size: 20, color: timerColor),
                ),
              Text(
                _format(elapsed),
                style: TextStyle(
                  color: timerColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isStopped
                  ? const Color(0xFF4CAF50)
                  : isPaused
                      ? Colors.orangeAccent
                      : context.colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (!isStopped)
            if (isRunning)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause, size: 16),
                    label: const Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('End'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              )
            else if (isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: const Color(0xFF1A1200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('End'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Practice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGoldColor,
                    foregroundColor: const Color(0xFF1A1200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
