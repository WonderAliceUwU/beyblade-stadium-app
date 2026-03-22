import 'dart:math';

import 'package:flutter/services.dart';

import '../../../screens/title_screen.dart';
import '../../../widgets/bey_wheel.dart';
import '../presentation/battle_series_presenter.dart';

enum BattleFinishType { warning, spin, over }

class BattleAudioConfig {
  final List<String> bgPlaylist;
  final String clickSound;
  final String countdownSound;
  final double maxMusicVolume;
  final double duckMusicVolume;
  final String Function(int round) roundSoundFor;
  final String Function(BattleFinishType type, Random random) finishSoundFor;

  const BattleAudioConfig({
    required this.bgPlaylist,
    required this.clickSound,
    required this.countdownSound,
    required this.maxMusicVolume,
    required this.duckMusicVolume,
    required this.roundSoundFor,
    required this.finishSoundFor,
  });
}

class BattleSeriesConfig {
  final BeySeries series;
  final String fontFamily;
  final bool embossedText;
  final String? openingVideoAsset;
  final List<String> countdownSequence;
  final List<BeyInfo> beys;
  final BattleAudioConfig audio;
  final BattleShortcutConfig shortcuts;
  final BattleSeriesPresenter presenter;

  const BattleSeriesConfig({
    required this.series,
    required this.fontFamily,
    required this.embossedText,
    required this.openingVideoAsset,
    required this.countdownSequence,
    required this.beys,
    required this.audio,
    required this.shortcuts,
    required this.presenter,
  });

  bool get hasOpeningVideo => openingVideoAsset != null;

  static BattleSeriesConfig forSeries(BeySeries series) {
    switch (series) {
      case BeySeries.metal:
        return _metalConfig;
      case BeySeries.x:
        return _xReadyConfig;
    }
  }
}

class BattleShortcutConfig {
  final LogicalKeyboardKey leftSpinFinish;
  final LogicalKeyboardKey leftOverFinish;
  final LogicalKeyboardKey rightSpinFinish;
  final LogicalKeyboardKey rightOverFinish;
  final LogicalKeyboardKey warning;
  final LogicalKeyboardKey primaryAction;

  const BattleShortcutConfig({
    required this.leftSpinFinish,
    required this.leftOverFinish,
    required this.rightSpinFinish,
    required this.rightOverFinish,
    required this.warning,
    required this.primaryAction,
  });
}

class BattleRosters {
  static const List<BeyInfo> metal = [
    BeyInfo(name: 'Storm Pegasus 105RF', motif: 'pegasis', type: BeyType.attack),
    BeyInfo(
      name: 'Lightning L-Drago 100HF',
      motif: 'drago',
      type: BeyType.attack,
      spin: SpinDirection.counterClockwise,
    ),
    BeyInfo(name: 'Storm Aquario 100HF:S', motif: 'aquario', type: BeyType.attack),
    BeyInfo(name: 'Earth Aquila 145WD', motif: 'aquila', type: BeyType.defense),
    BeyInfo(name: 'Rock Leone 145WB', motif: 'leone', type: BeyType.defense),
    BeyInfo(name: 'Burn Phoenix 135MS', motif: 'phoenix', type: BeyType.stamina),
    BeyInfo(
      name: 'Flame Sagittario C-145S',
      motif: 'sagittario',
      type: BeyType.stamina,
    ),
    BeyInfo(name: 'Dark Wolf DF-145FS', motif: 'wolf', type: BeyType.balance),
    BeyInfo(
      name: 'Ray Unicorn D-125CS',
      motif: 'unicorn',
      type: BeyType.balance,
      imageScale: 1.22,
    ),
    BeyInfo(
      name: 'Samurai Pegasus W-125R2F',
      motif: 'samurai-pegasus',
      type: BeyType.attack,
      imageScale: 1.22,
      selectVoiceOverride: 'metal/sounds/bey-select/samurai-pegasus.mp3',
      winVoicesOverride: ['metal/sounds/bey-win/Samurai-Pegasus Win.mp3'],
      winNameOverride: 'Samurai Pegasus',
    ),
  ];

  // Placeholder until Beyblade X assets are added. The battle flow can already
  // switch to an X-specific roster, audio pack, and presenter through config.
  static const List<BeyInfo> xPrototype = metal;
}

const _classicPresenter = ClassicBattleSeriesPresenter();

final BattleSeriesConfig _metalConfig = BattleSeriesConfig(
  series: BeySeries.metal,
  fontFamily: 'MetalFight',
  embossedText: true,
  openingVideoAsset: 'assets/metal/video/opening-mf.mp4',
  countdownSequence: ['3', '2', '1', 'GOOO', 'SHOOT!!'],
  beys: BattleRosters.metal,
  audio: BattleAudioConfig(
    bgPlaylist: [
      'metal/sounds/bg-music/Metal Fight Theme.m4a',
      'metal/sounds/bg-music/Fatal Damage.opus',
      'metal/sounds/bg-music/Fly.m4a',
      'metal/sounds/bg-music/Wild Scent.opus',
      'metal/sounds/bg-music/Ryu-Kyu Humming.mp3',
      'metal/sounds/bg-music/Ogre Has Returned.flac',
      'metal/sounds/bg-music/Rainy and Departed.opus',
      'metal/sounds/bg-music/Pure Malice (KIWAMI ver.).opus',
    ],
    clickSound: 'metal/sounds/select.mp3',
    countdownSound: 'metal/sounds/countdown.m4a',
    maxMusicVolume: 0.10,
    duckMusicVolume: 0.02,
    roundSoundFor: _metalRoundSound,
    finishSoundFor: _metalFinishSound,
  ),
  shortcuts: const BattleShortcutConfig(
    leftSpinFinish: LogicalKeyboardKey.keyQ,
    leftOverFinish: LogicalKeyboardKey.keyA,
    rightSpinFinish: LogicalKeyboardKey.keyP,
    rightOverFinish: LogicalKeyboardKey.keyL,
    warning: LogicalKeyboardKey.keyZ,
    primaryAction: LogicalKeyboardKey.space,
  ),
  presenter: _classicPresenter,
);

final BattleSeriesConfig _xReadyConfig = BattleSeriesConfig(
  series: BeySeries.x,
  fontFamily: 'BeybladeX',
  embossedText: false,
  openingVideoAsset: null,
  countdownSequence: ['3', '2', '1', 'GOOO', 'SHOOT!!'],
  beys: BattleRosters.xPrototype,
  audio: BattleAudioConfig(
    bgPlaylist: _metalConfig.audio.bgPlaylist,
    clickSound: _metalConfig.audio.clickSound,
    countdownSound: _metalConfig.audio.countdownSound,
    maxMusicVolume: _metalConfig.audio.maxMusicVolume,
    duckMusicVolume: _metalConfig.audio.duckMusicVolume,
    roundSoundFor: _metalRoundSound,
    finishSoundFor: _metalFinishSound,
  ),
  shortcuts: _metalConfig.shortcuts,
  presenter: _classicPresenter,
);

String _metalRoundSound(int round) {
  final cappedRound = round > 7 ? 7 : round;
  return 'metal/sounds/round/round-$cappedRound.mp3';
}

String _metalFinishSound(BattleFinishType type, Random random) {
  switch (type) {
    case BattleFinishType.warning:
      return 'metal/sounds/finish/Warning 1.mp3';
    case BattleFinishType.spin:
      return random.nextInt(2) == 0
          ? 'metal/sounds/finish/Spin finish 1.mp3'
          : 'metal/sounds/finish/Spin Finish 2.mp3';
    case BattleFinishType.over:
      final version = random.nextInt(3) + 1;
      return 'metal/sounds/finish/Over finish $version.mp3';
  }
}
