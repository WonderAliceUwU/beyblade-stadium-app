import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../screens/title_screen.dart';
import '../../../widgets/bey_wheel.dart';
import '../domain/battle_session_state.dart';
import 'widgets/battle_screen_view.dart';
import 'widgets/win_screen_view.dart';

class BattlePresentationData {
  final BattleSessionState state;
  final BeySeries series;
  final String font;
  final TextStyle textStyle;
  final List<String> countdownSequence;
  final List<BeyInfo> beys;
  final Animation<Offset> countdownSlide;
  final Animation<double> finishOpacity;
  final Animation<Offset> finishSlide;
  final VideoPlayerController? videoController;
  final bool showVideo;
  final bool isVideoReady;
  final bool isClosingVideo;
  final bool isMusicMuted;
  final String currentTrackLabel;

  const BattlePresentationData({
    required this.state,
    required this.series,
    required this.font,
    required this.textStyle,
    required this.countdownSequence,
    required this.beys,
    required this.countdownSlide,
    required this.finishOpacity,
    required this.finishSlide,
    required this.videoController,
    required this.showVideo,
    required this.isVideoReady,
    required this.isClosingVideo,
    required this.isMusicMuted,
    required this.currentTrackLabel,
  });
}

class BattlePresentationCallbacks {
  final VoidCallback onPointerDown;
  final VoidCallback onLeftLockToggle;
  final VoidCallback onRightLockToggle;
  final ValueChanged<BeyInfo> onLeftBeyChanged;
  final ValueChanged<BeyInfo> onRightBeyChanged;
  final VoidCallback onPlay;
  final VoidCallback onWarning;
  final VoidCallback onLeftSpinFinish;
  final VoidCallback onLeftOverFinish;
  final VoidCallback onRightSpinFinish;
  final VoidCallback onRightOverFinish;
  final VoidCallback onToggleMusic;
  final VoidCallback onSkipTrack;
  final VoidCallback onResetScores;
  final VoidCallback onCloseVideo;

  const BattlePresentationCallbacks({
    required this.onPointerDown,
    required this.onLeftLockToggle,
    required this.onRightLockToggle,
    required this.onLeftBeyChanged,
    required this.onRightBeyChanged,
    required this.onPlay,
    required this.onWarning,
    required this.onLeftSpinFinish,
    required this.onLeftOverFinish,
    required this.onRightSpinFinish,
    required this.onRightOverFinish,
    required this.onToggleMusic,
    required this.onSkipTrack,
    required this.onResetScores,
    required this.onCloseVideo,
  });
}

class WinPresentationCallbacks {
  final VoidCallback onResetBattle;
  final VoidCallback onToggleMusic;
  final VoidCallback onSkipTrack;

  const WinPresentationCallbacks({
    required this.onResetBattle,
    required this.onToggleMusic,
    required this.onSkipTrack,
  });
}

abstract class BattleSeriesPresenter {
  Widget buildBattleView(
    BattlePresentationData data,
    BattlePresentationCallbacks callbacks,
  );

  Widget buildWinView(
    BattlePresentationData data,
    AnimationController motifController,
    WinPresentationCallbacks callbacks,
  );
}

class ClassicBattleSeriesPresenter implements BattleSeriesPresenter {
  const ClassicBattleSeriesPresenter();

  @override
  Widget buildBattleView(
    BattlePresentationData data,
    BattlePresentationCallbacks callbacks,
  ) {
    return BattleScreenView(
      state: data.state,
      series: data.series,
      font: data.font,
      textStyle: data.textStyle,
      countdownSequence: data.countdownSequence,
      beys: data.beys,
      countdownSlide: data.countdownSlide,
      finishOpacity: data.finishOpacity,
      finishSlide: data.finishSlide,
      videoController: data.videoController,
      showVideo: data.showVideo,
      isVideoReady: data.isVideoReady,
      isClosingVideo: data.isClosingVideo,
      isMusicMuted: data.isMusicMuted,
      currentTrackLabel: data.currentTrackLabel,
      onPointerDown: callbacks.onPointerDown,
      onLeftLockToggle: callbacks.onLeftLockToggle,
      onRightLockToggle: callbacks.onRightLockToggle,
      onLeftBeyChanged: callbacks.onLeftBeyChanged,
      onRightBeyChanged: callbacks.onRightBeyChanged,
      onPlay: callbacks.onPlay,
      onWarning: callbacks.onWarning,
      onLeftSpinFinish: callbacks.onLeftSpinFinish,
      onLeftOverFinish: callbacks.onLeftOverFinish,
      onRightSpinFinish: callbacks.onRightSpinFinish,
      onRightOverFinish: callbacks.onRightOverFinish,
      onToggleMusic: callbacks.onToggleMusic,
      onSkipTrack: callbacks.onSkipTrack,
      onResetScores: callbacks.onResetScores,
      onCloseVideo: callbacks.onCloseVideo,
    );
  }

  @override
  Widget buildWinView(
    BattlePresentationData data,
    AnimationController motifController,
    WinPresentationCallbacks callbacks,
  ) {
    return WinScreenView(
      state: data.state,
      series: data.series,
      textStyle: data.textStyle,
      motifController: motifController,
      isMusicMuted: data.isMusicMuted,
      currentTrackLabel: data.currentTrackLabel,
      onResetBattle: callbacks.onResetBattle,
      onToggleMusic: callbacks.onToggleMusic,
      onSkipTrack: callbacks.onSkipTrack,
    );
  }
}
