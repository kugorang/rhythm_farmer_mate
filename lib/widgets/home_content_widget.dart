import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../screens/my_home_page.dart'
    show PlayMode; // MyHomePageState의 public 메서드/변수 접근을 위해
import './timer_display_widget.dart';
import './bpm_control_section_widget.dart';
import './progress_display_widget.dart';
import './music_control_widget.dart';
import './challenge_control_button_widget.dart';
import './song_selection_widget.dart';
import './playback_mode_control_widget.dart';

class HomeContentWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isChallengeRunning;
  final Song selectedSong;
  final List<Song> songList;
  final Function(Song?) onSongChanged;
  final String timerText;
  final BorderRadius defaultBorderRadius;
  final bool beatHighlighter;
  final bool bpmChangedByTap;
  final double bpmIndicatorScale;
  final Color bpmIndicatorColor;
  final Color bpmTextColor;
  final List<DateTime> tapTimestamps;
  final int currentManualBpm;
  final Function(int) onChangeBpmToPreset;
  final Function(int) onChangeBpm;
  final Function(int) onStartBpmAdjustTimer;
  final Function() onStopBpmAdjustTimer;
  final Function() onHandleTapForBpm;
  final double progressPercent;
  final bool isPlaying;
  final Duration? audioDuration;
  final double currentPlaybackSpeed;
  final Function() onPlayPause;
  final Function() onStop;
  final Function() onChallengeButtonPressed;
  final int slowBpm;
  final int normalBpm;
  final int fastBpm;
  final PlayMode playMode;
  final Function(PlayMode) onPlayModeChanged;

  const HomeContentWidget({
    super.key,
    required this.isLoadingSong,
    required this.isChallengeRunning,
    required this.selectedSong,
    required this.songList,
    required this.onSongChanged,
    required this.timerText,
    required this.defaultBorderRadius,
    required this.beatHighlighter,
    required this.bpmChangedByTap,
    required this.bpmIndicatorScale,
    required this.bpmIndicatorColor,
    required this.bpmTextColor,
    required this.tapTimestamps,
    required this.currentManualBpm,
    required this.onChangeBpmToPreset,
    required this.onChangeBpm,
    required this.onStartBpmAdjustTimer,
    required this.onStopBpmAdjustTimer,
    required this.onHandleTapForBpm,
    required this.progressPercent,
    required this.isPlaying,
    required this.audioDuration,
    required this.currentPlaybackSpeed,
    required this.onPlayPause,
    required this.onStop,
    required this.onChallengeButtonPressed,
    this.slowBpm = 60,
    this.normalBpm = 90,
    this.fastBpm = 120,
    required this.playMode,
    required this.onPlayModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canInteractWithSettings = !isChallengeRunning && !isLoadingSong;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0, // 반응형 패딩은 MyHomePage에서 처리
        vertical: 24.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isLoadingSong)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          SongSelectionWidget(
            songList: songList,
            selectedSong: selectedSong,
            isLoading: isLoadingSong,
            isChallengeRunning: isChallengeRunning,
            onSongChanged: onSongChanged,
          ),
          PlaybackModeControlWidget(
            currentPlayMode: playMode,
            onPlayModeChanged: onPlayModeChanged,
            isDisabled: isLoadingSong || isChallengeRunning,
          ),
          TimerDisplayWidget(
            isLoadingSong: isLoadingSong,
            timerText: timerText,
            borderRadius: defaultBorderRadius,
          ),
          const SizedBox(height: 12),
          Visibility(
            visible: canInteractWithSettings, // 직접 계산
            child: BpmControlSectionWidget(
              isLoadingSong: isLoadingSong,
              isChallengeRunning: isChallengeRunning,
              currentManualBpm: currentManualBpm,
              beatHighlighter: beatHighlighter,
              bpmChangedByTap: bpmChangedByTap,
              bpmIndicatorScale: bpmIndicatorScale,
              bpmIndicatorColor: bpmIndicatorColor,
              bpmTextColor: bpmTextColor,
              defaultBorderRadius: defaultBorderRadius,
              tapTimestamps: tapTimestamps,
              onChangeBpmToPreset: onChangeBpmToPreset,
              onChangeBpm: onChangeBpm,
              onStartBpmAdjustTimer: onStartBpmAdjustTimer,
              onStopBpmAdjustTimer: onStopBpmAdjustTimer,
              onHandleTapForBpm: onHandleTapForBpm,
              slowBpm: slowBpm,
              normalBpm: normalBpm,
              fastBpm: fastBpm,
            ),
          ),
          if (canInteractWithSettings) // 직접 계산
            const SizedBox(height: 24)
          else
            const SizedBox(height: 12),
          ProgressDisplayWidget(
            isLoadingSong: isLoadingSong,
            isChallengeRunning: isChallengeRunning,
            progressPercent: progressPercent,
          ),
          const SizedBox(height: 30),
          MusicControlWidget(
            isLoadingSong: isLoadingSong,
            isChallengeRunning: isChallengeRunning,
            isPlaying: isPlaying,
            selectedSong: selectedSong,
            audioDuration: audioDuration,
            currentPlaybackSpeed: currentPlaybackSpeed,
            currentManualBpm: currentManualBpm,
            defaultBorderRadius: defaultBorderRadius,
            onPlayPause: onPlayPause,
            onStop: onStop,
          ),
          const SizedBox(height: 30),
          ChallengeControlButtonWidget(
            isLoadingSong: isLoadingSong,
            isChallengeRunning: isChallengeRunning,
            onPressed: onChallengeButtonPressed,
          ),
        ],
      ),
    );
  }
}
