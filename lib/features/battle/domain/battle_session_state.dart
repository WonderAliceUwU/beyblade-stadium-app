import '../../../widgets/bey_wheel.dart';

enum ArenaPhase { selecting, countdown }

class BattleSessionState {
  static const _sentinel = Object();

  final bool leftLocked;
  final bool rightLocked;
  final int leftScore;
  final int rightScore;
  final int currentRound;
  final BeyInfo? leftBey;
  final BeyInfo? rightBey;
  final ArenaPhase phase;
  final String finishText;
  final bool isAnimatingFinish;
  final bool isGameOver;
  final BeyInfo? winningBey;
  final bool winnerIsLeft;
  final int countdownIndex;

  const BattleSessionState({
    required this.leftLocked,
    required this.rightLocked,
    required this.leftScore,
    required this.rightScore,
    required this.currentRound,
    required this.leftBey,
    required this.rightBey,
    required this.phase,
    required this.finishText,
    required this.isAnimatingFinish,
    required this.isGameOver,
    required this.winningBey,
    required this.winnerIsLeft,
    required this.countdownIndex,
  });

  factory BattleSessionState.initial() {
    return const BattleSessionState(
      leftLocked: false,
      rightLocked: false,
      leftScore: 0,
      rightScore: 0,
      currentRound: 1,
      leftBey: null,
      rightBey: null,
      phase: ArenaPhase.selecting,
      finishText: '',
      isAnimatingFinish: false,
      isGameOver: false,
      winningBey: null,
      winnerIsLeft: true,
      countdownIndex: 0,
    );
  }

  bool get bothLocked => leftLocked && rightLocked;

  bool get interactionEnabled {
    return phase == ArenaPhase.selecting &&
        (!isAnimatingFinish || finishText.startsWith('ROUND'));
  }

  BattleSessionState copyWith({
    bool? leftLocked,
    bool? rightLocked,
    int? leftScore,
    int? rightScore,
    int? currentRound,
    Object? leftBey = _sentinel,
    Object? rightBey = _sentinel,
    ArenaPhase? phase,
    String? finishText,
    bool? isAnimatingFinish,
    bool? isGameOver,
    Object? winningBey = _sentinel,
    bool? winnerIsLeft,
    int? countdownIndex,
  }) {
    return BattleSessionState(
      leftLocked: leftLocked ?? this.leftLocked,
      rightLocked: rightLocked ?? this.rightLocked,
      leftScore: leftScore ?? this.leftScore,
      rightScore: rightScore ?? this.rightScore,
      currentRound: currentRound ?? this.currentRound,
      leftBey: identical(leftBey, _sentinel) ? this.leftBey : leftBey as BeyInfo?,
      rightBey:
          identical(rightBey, _sentinel) ? this.rightBey : rightBey as BeyInfo?,
      phase: phase ?? this.phase,
      finishText: finishText ?? this.finishText,
      isAnimatingFinish: isAnimatingFinish ?? this.isAnimatingFinish,
      isGameOver: isGameOver ?? this.isGameOver,
      winningBey: identical(winningBey, _sentinel)
          ? this.winningBey
          : winningBey as BeyInfo?,
      winnerIsLeft: winnerIsLeft ?? this.winnerIsLeft,
      countdownIndex: countdownIndex ?? this.countdownIndex,
    );
  }
}
