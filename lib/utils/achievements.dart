import 'package:flutter/material.dart';
import '../providers/exercise_provider.dart';
import '../providers/piece_provider.dart';

typedef AchievementCheck = bool Function(
    PieceProvider pieces, ExerciseProvider exercises);

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCheck check;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.check,
  });
}

int _totalSeconds(PieceProvider p, ExerciseProvider e) =>
    p.practiceSessions.fold(0, (s, x) => s + (x.durationSeconds ?? 0)) +
    e.sessions.fold(0, (s, x) => s + (x.durationSeconds ?? 0));

const _kOrange = Color(0xFFFF6B35);
const _kGold = Color(0xFFC9A227);
const _kGreen = Color(0xFF4CAF50);
const _kBlue = Color(0xFF42A5F5);
const _kPurple = Color(0xFFAB47BC);

final List<Achievement> kAchievements = [
  // ── First steps ──────────────────────────────────────────────────────────
  Achievement(
    id: 'first_session',
    name: 'First Note',
    description: 'Log your very first practice session.',
    icon: Icons.piano,
    color: _kGold,
    check: (p, e) => p.practiceSessions.isNotEmpty || e.sessions.isNotEmpty,
  ),

  // ── Practice time ─────────────────────────────────────────────────────────
  Achievement(
    id: 'one_hour',
    name: 'Hour In',
    description: 'Accumulate 1 hour of total practice.',
    icon: Icons.timer_outlined,
    color: _kGold,
    check: (p, e) => _totalSeconds(p, e) >= 3600,
  ),
  Achievement(
    id: 'ten_hours',
    name: 'Committed',
    description: 'Accumulate 10 hours of total practice.',
    icon: Icons.timer,
    color: _kGold,
    check: (p, e) => _totalSeconds(p, e) >= 36000,
  ),
  Achievement(
    id: 'hundred_hours',
    name: 'Century',
    description: 'Accumulate 100 hours of total practice.',
    icon: Icons.emoji_events,
    color: _kGold,
    check: (p, e) => _totalSeconds(p, e) >= 360000,
  ),

  // ── Streaks ───────────────────────────────────────────────────────────────
  Achievement(
    id: 'streak_3',
    name: 'On a Roll',
    description: 'Practice 3 days in a row.',
    icon: Icons.local_fire_department,
    color: _kOrange,
    check: (p, e) => p.streak >= 3,
  ),
  Achievement(
    id: 'streak_7',
    name: 'Week Warrior',
    description: 'Practice every day for a full week.',
    icon: Icons.local_fire_department,
    color: _kOrange,
    check: (p, e) => p.streak >= 7,
  ),
  Achievement(
    id: 'streak_30',
    name: 'Unstoppable',
    description: 'Practice 30 days in a row.',
    icon: Icons.local_fire_department,
    color: _kOrange,
    check: (p, e) => p.streak >= 30,
  ),

  // ── Songs ─────────────────────────────────────────────────────────────────
  Achievement(
    id: 'first_song',
    name: 'First Song',
    description: 'Add your first song to the library.',
    icon: Icons.library_music,
    color: _kBlue,
    check: (p, e) => p.pieces.isNotEmpty,
  ),
  Achievement(
    id: 'collector',
    name: 'Collector',
    description: 'Add 5 songs to your library.',
    icon: Icons.library_music,
    color: _kBlue,
    check: (p, e) => p.totalCount >= 5,
  ),
  Achievement(
    id: 'first_master',
    name: 'Mastered',
    description: 'Advance your first song to Repertoire.',
    icon: Icons.star,
    color: _kGold,
    check: (p, e) => p.repertoireCount >= 1,
  ),
  Achievement(
    id: 'virtuoso',
    name: 'Virtuoso',
    description: 'Have 5 songs in Repertoire.',
    icon: Icons.workspace_premium,
    color: _kPurple,
    check: (p, e) => p.repertoireCount >= 5,
  ),

  // ── Exercises ─────────────────────────────────────────────────────────────
  Achievement(
    id: 'first_exercise',
    name: 'First Rep',
    description: 'Log your first exercise session.',
    icon: Icons.fitness_center,
    color: _kGreen,
    check: (p, e) => e.sessions.isNotEmpty,
  ),

  // ── Speed ─────────────────────────────────────────────────────────────────
  Achievement(
    id: 'speed_demon',
    name: 'Speed Demon',
    description: 'Reach 120 BPM in any session.',
    icon: Icons.speed,
    color: _kOrange,
    check: (p, e) =>
        p.practiceSessions.any((s) => (s.currentBpm ?? 0) >= 120) ||
        e.sessions.any((s) => (s.bpm ?? 0) >= 120),
  ),
];
