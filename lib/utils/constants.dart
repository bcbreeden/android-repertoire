import 'package:flutter/material.dart';

// Stage identifiers
const String kStageLearning = 'learning';
const String kStageRepertoire = 'repertoire';

const List<String> kStageOrder = [
  kStageLearning,
  kStageRepertoire,
];

const Map<String, String> kStageLabels = {
  kStageLearning: 'Learning',
  kStageRepertoire: 'Repertoire',
};

const Map<String, String> kStageDescriptions = {
  kStageLearning: 'Actively working on this piece',
  kStageRepertoire: 'Polished and performance ready',
};

const Map<String, Color> kStageColors = {
  kStageLearning: Color(0xFF4CAF50),
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
const String kRepertoireAt = 'repertoire_at';

const Map<String, String> kStageTimestampKeys = {
  kStageLearning: kLearningAt,
  kStageRepertoire: kRepertoireAt,
};

String nextStage(String currentStage) {
  final idx = kStageOrder.indexOf(currentStage);
  if (idx < 0 || idx >= kStageOrder.length - 1) return currentStage;
  return kStageOrder[idx + 1];
}

bool isLastStage(String stage) => stage == kStageRepertoire;

int stageIndex(String stage) => kStageOrder.indexOf(stage);
