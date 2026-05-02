import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';
import '../widgets/log_practice_sheet.dart';
import '../widgets/paywall_sheet.dart';
import 'home_screen.dart';
import 'piece_form_screen.dart';
import 'practice_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isPracticeTab => _tabController.index == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.piano, color: kGoldColor, size: 24),
            SizedBox(width: 8),
            Text(
              'Repertoire',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science_outlined, color: kTextSecondary),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kGoldColor,
          indicatorWeight: 2,
          labelColor: kGoldColor,
          unselectedLabelColor: kTextSecondary,
          labelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Practice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PiecesTab(),
          PracticeTab(),
        ],
      ),
      floatingActionButton: Consumer<PieceProvider>(
        builder: (context, provider, _) {
          if (_isPracticeTab && provider.pieces.isEmpty) return const SizedBox.shrink();
          return GestureDetector(
            onLongPress: _isPracticeTab ? null : () => _showLogSheet(context),
            child: FloatingActionButton(
              onPressed: _isPracticeTab
                  ? () => _showLogSheet(context)
                  : () => _addPiece(context),
              backgroundColor: kGoldColor,
              foregroundColor: const Color(0xFF1A1200),
              tooltip: _isPracticeTab ? 'Log Practice' : 'Add Song',
              child: Icon(_isPracticeTab ? Icons.edit_note : Icons.add),
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
        backgroundColor: kCardColor,
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

  void _showLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LogPracticeSheet(),
    );
  }
}
