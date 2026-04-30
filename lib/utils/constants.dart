import 'package:flutter/material.dart';

// Stage identifiers
const String kStagelearning = 'learning';
const String kStageNotePerfection = 'note_perfection';
const String kStageDynamicsPerfection = 'dynamics_perfection';
const String kStageTempoPerfection = 'tempo_perfection';
const String kStageRepertoire = 'repertoire';

const List<String> kStageOrder = [
  kStagelearning,
  kStageNotePerfection,
  kStageDynamicsPerfection,
  kStageTempoPerfection,
  kStageRepertoire,
];

const Map<String, String> kStageLabels = {
  kStagelearning: 'Learning',
  kStageNotePerfection: 'Note Perfection',
  kStageDynamicsPerfection: 'Dynamics Perfection',
  kStageTempoPerfection: 'Tempo Perfection',
  kStageRepertoire: 'Mastered',
};

const Map<String, String> kStageDescriptions = {
  kStagelearning: 'Working through piece measure by measure',
  kStageNotePerfection: 'All notes played correctly',
  kStageDynamicsPerfection: 'All notes with correct dynamics',
  kStageTempoPerfection: 'All notes and dynamics at any tempo',
  kStageRepertoire: 'All notes, dynamics, at correct target tempo',
};

const Map<String, Color> kStageColors = {
  kStagelearning: Color(0xFF4CAF50),
  kStageNotePerfection: Color(0xFF2196F3),
  kStageDynamicsPerfection: Color(0xFFFF8F00),
  kStageTempoPerfection: Color(0xFF9C27B0),
  kStageRepertoire: Color(0xFFC9A227),
};

// App Colors
const Color kBackgroundColor = Color(0xFF111318);
const Color kSurfaceColor = Color(0xFF1E2128);
const Color kCardColor = Color(0xFF252932);
const Color kGoldColor = Color(0xFFC9A227);
const Color kGoldLight = Color(0xFFE8C547);
const Color kTextPrimary = Color(0xFFE8EAF0);
const Color kTextSecondary = Color(0xFF9CA3AF);
const Color kDividerColor = Color(0xFF2D3340);

// Stage timestamp keys (database column names)
const String kLearningAt = 'learning_at';
const String kNotePerfectionAt = 'note_perfection_at';
const String kDynamicsPerfectionAt = 'dynamics_perfection_at';
const String kTempoPerfectionAt = 'tempo_perfection_at';
const String kRepertoireAt = 'repertoire_at';

const Map<String, String> kStageTimestampKeys = {
  kStagelearning: kLearningAt,
  kStageNotePerfection: kNotePerfectionAt,
  kStageDynamicsPerfection: kDynamicsPerfectionAt,
  kStageTempoPerfection: kTempoPerfectionAt,
  kStageRepertoire: kRepertoireAt,
};

String nextStage(String currentStage) {
  final idx = kStageOrder.indexOf(currentStage);
  if (idx < 0 || idx >= kStageOrder.length - 1) return currentStage;
  return kStageOrder[idx + 1];
}

bool isLastStage(String stage) => stage == kStageRepertoire;

int stageIndex(String stage) => kStageOrder.indexOf(stage);
