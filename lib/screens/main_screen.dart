import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/piece_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/log_practice_sheet.dart';
import '../widgets/paywall_sheet.dart';
import 'exercise_form_screen.dart';
import 'exercises_screen.dart';
import 'home_screen.dart';
import 'piece_form_screen.dart';
import 'practice_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  bool get _isSongsTab     => _currentIndex == 0;
  bool get _isExercisesTab => _currentIndex == 1;
  bool get _isPracticeTab  => _currentIndex == 2;
  bool get _isStatsTab     => _currentIndex == 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Consumer<PieceProvider>(
          builder: (context, provider, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Repertoire',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (provider.streak > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${provider.streak}',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, theme, _) => IconButton(
              icon: Icon(
                theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: colors.textSecondary,
              ),
              tooltip: theme.isDark ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: () => theme.toggle(),
            ),
          ),
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.science_outlined, color: colors.textSecondary),
              tooltip: 'Seed test data',
              onPressed: () async {
                await context.read<PieceProvider>().seedTestData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test data loaded')),
                  );
                }
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PiecesTab(),
          ExercisesTab(),
          PracticeTab(),
          StatsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.background,
          indicatorColor: kGoldColor.withOpacity(0.18),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: kGoldColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              );
            }
            return TextStyle(color: colors.textSecondary, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kGoldColor, size: 22);
            }
            return IconThemeData(color: colors.textSecondary, size: 22);
          }),
        ),
        child: NavigationBar(
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: 'Songs',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Exercises',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Practice',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer2<PieceProvider, ExerciseProvider>(
        builder: (context, pieceProvider, exerciseProvider, _) {
          if (_isStatsTab) return const SizedBox.shrink();
          if (_isPracticeTab &&
              pieceProvider.pieces.isEmpty &&
              exerciseProvider.exercises.isEmpty) {
            return const SizedBox.shrink();
          }
          if (_isExercisesTab) {
            return FloatingActionButton(
              onPressed: () => _addExercise(context),
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            );
          }
          if (_isPracticeTab) {
            return FloatingActionButton(
              onPressed: () => _showLogSheet(context),
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
              tooltip: 'Log Practice',
              child: const Icon(Icons.add),
            );
          }
          // Songs tab
          return GestureDetector(
            onLongPress: () => _showLogSheet(context),
            child: FloatingActionButton(
              onPressed: () => _addPiece(context),
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
              tooltip: 'Add Song',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addPiece(BuildContext context) async {
    final provider = context.read<PieceProvider>();
    if (!provider.canAddPiece) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const PaywallSheet(),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PieceFormScreen()),
    );
  }

  Future<void> _addExercise(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseFormScreen()),
    );
  }

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LogPracticeSheet(),
    );
  }
}
