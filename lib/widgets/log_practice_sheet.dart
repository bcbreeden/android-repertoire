import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

enum _TimerState { idle, running, paused, stopped }

class LogPracticeSheet extends StatefulWidget {
  final int? pieceId;
  const LogPracticeSheet({super.key, this.pieceId});

  @override
  State<LogPracticeSheet> createState() => _LogPracticeSheetState();
}

class _LogPracticeSheetState extends State<LogPracticeSheet>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _measuresController;
  late final TextEditingController _bpmController;
  late final TextEditingController _notesController;

  int? _selectedPieceId;
  bool _isSaving = false;

  // Timer state
  _TimerState _timerState = _TimerState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  DateTime? _startedAt;        // wall-clock time the current run segment began
  Duration _accumulated = Duration.zero; // elapsed before current run segment

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedPieceId = widget.pieceId;
    _measuresController = TextEditingController();
    _bpmController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.pieceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
  }

  void _prefill() {
    final provider = context.read<PieceProvider>();
    final piece = provider.getPieceById(widget.pieceId!);
    if (piece == null) return;
    if (piece.measuresLearned != null) {
      _measuresController.text = piece.measuresLearned.toString();
    }
    if (piece.currentTempo != null) {
      _bpmController.text = piece.currentTempo.toString();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _timerState == _TimerState.running &&
        _startedAt != null) {
      // Snap elapsed to wall-clock time, correcting for sleep drift.
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
    _measuresController.dispose();
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
    final pieceId = _selectedPieceId;
    if (pieceId == null) return;
    if (!_formKey.currentState!.validate()) return;

    // Stop timer if still running or paused
    if (_timerState == _TimerState.running ||
        _timerState == _TimerState.paused) {
      _stopTimer();
    }

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
    final provider = context.watch<PieceProvider>();
    final pieces = provider.pieces;
    final selectedPiece = _selectedPieceId != null
        ? provider.getPieceById(_selectedPieceId!)
        : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
              const SizedBox(height: 20),

              // Timer display
              _TimerDisplay(
                elapsed: _elapsed,
                state: _timerState,
                onStart: _startTimer,
                onPause: _pauseTimer,
                onResume: _resumeTimer,
                onStop: _stopTimer,
              ),
              const SizedBox(height: 24),

              // Piece — picker when opened generically, info row when pre-selected
              const Text('Song',
                  style: TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              if (widget.pieceId == null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      hint: const Text('Select a song',
                          style: TextStyle(color: kTextSecondary)),
                      style:
                          const TextStyle(color: kTextPrimary, fontSize: 14),
                      items: pieces
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedPieceId = id;
                          if (id != null) {
                            final piece = provider.getPieceById(id);
                            if (piece?.measuresLearned != null) {
                              _measuresController.text =
                                  piece!.measuresLearned.toString();
                            }
                            if (piece?.currentTempo != null) {
                              _bpmController.text =
                                  piece!.currentTempo.toString();
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPiece?.name ?? '—',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedPiece?.composer != null &&
                          selectedPiece!.composer!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          selectedPiece.composer!,
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Song details (total measures + target BPM)
              if (selectedPiece != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note,
                        size: 13, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${selectedPiece.measures} measures total',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                    ),
                    if (selectedPiece.targetTempo != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.speed, size: 13, color: kTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${selectedPiece.targetTempo} BPM',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Measures + BPM
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
                        if (n == null) return 'Invalid number';
                        if (selectedPiece != null && n > selectedPiece.measures) {
                          return 'Max ${selectedPiece.measures}';
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
                        if (n == null) return 'Invalid number';
                        if (selectedPiece?.targetTempo != null &&
                            n > selectedPiece!.targetTempo!) {
                          return 'Max ${selectedPiece.targetTempo}';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              _field(
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
                  onPressed:
                      (_isSaving || _selectedPieceId == null) ? null : _save,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Timer display widget ──────────────────────────────────────────────────────

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
      bgColor = kCardColor;
    } else {
      borderColor = kDividerColor;
      bgColor = kCardColor;
    }

    Color timerColor;
    if (isRunning) {
      timerColor = kGoldColor;
    } else if (isPaused) {
      timerColor = Colors.orangeAccent;
    } else if (isStopped) {
      timerColor = const Color(0xFF4CAF50);
    } else {
      timerColor = kTextSecondary;
    }

    String subtitle;
    if (isStopped) {
      subtitle = 'Session complete';
    } else if (isRunning) {
      subtitle = 'Practice in progress';
    } else if (isPaused) {
      subtitle = 'Paused';
    } else {
      subtitle = 'Start the timer when you begin';
    }

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
          // Timer readout
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
                      : kTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          if (!isStopped)
            if (isRunning)
              // Running: Pause + End Practice
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
              // Paused: Resume + End Practice
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
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
