import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../models/song_category.dart'; // SongCategoryType을 사용하기 위해 추가
// import '../screens/my_home_page.dart'
//     show PlayMode; // MyHomePageState의 public 메서드/변수 접근을 위해
import './timer_display_widget.dart';
import 'package:rhythm_farmer_mate/widgets/speed_control_section_widget.dart';
import './progress_display_widget.dart';
import './music_control_widget.dart';
// import './challenge_control_button_widget.dart'; // 사용 안 함
import 'package:rhythm_farmer_mate/screens/my_home_page.dart'
    show PomodoroState; // PomodoroState enum 가져오기
import 'package:rhythm_farmer_mate/widgets/pomodoro_control_button_widget.dart'
    show PomodoroState, PomodoroControlButtonWidget; // PomodoroState와 위젯 모두 가져옴
// import './song_selection_widget.dart';
// import './playback_mode_control_widget.dart';

class HomeContentWidget extends StatelessWidget {
  final bool isLoadingSong;
  final Song selectedSong; // 현재 재생 중인 단일 곡
  // final List<Song> songList; // 제거
  // final Function(Song?) onSongChanged; // 제거
  final String timerText;
  final BorderRadius defaultBorderRadius;
  // final bool beatHighlighter; // 삭제
  // final bool bpmChangedByTap; // 삭제
  // final double bpmIndicatorScale; // 삭제
  // final Color bpmIndicatorColor; // 삭제
  // final Color bpmTextColor; // 삭제
  // final List<DateTime> tapTimestamps; // 삭제
  final int currentManualBpm; // 현재 곡의 BPM (표시용 또는 속도 조절 기준)
  final Function(int) onChangeSpeedPreset; // 이름 변경됨
  final Function(int) onChangeSpeed; // 이름 변경됨
  final Function(int) onStartSpeedAdjustTimer; // 이름 변경됨
  final Function() onStopSpeedAdjustTimer; // 이름 변경됨
  // final Function() onHandleTapForBpm; // 삭제
  final double progressPercent;
  final bool isPlaying;
  final Duration? audioDuration; // 로컬 파일 재생 시 필요
  final double currentPlaybackSpeed;
  final Function() onPlayPause;
  final Function() onStop;
  final Function() onPomodoroButtonPressed;
  final int speedPresetSlow; // 이름 변경 (slowBpm -> speedPresetSlow)
  final int speedPresetNormal; // 이름 변경 (normalBpm -> speedPresetNormal)
  final int speedPresetFast; // 이름 변경 (fastBpm -> speedPresetFast)
  // final PlayMode playMode; // 제거
  // final Function(PlayMode) onPlayModeChanged; // 제거
  final bool isYoutubeMode;
  final PomodoroState currentPomodoroState;
  final int pomodoroCycleCount;

  const HomeContentWidget({
    super.key,
    required this.isLoadingSong,
    required this.selectedSong,
    required this.timerText,
    required this.defaultBorderRadius,
    // required this.beatHighlighter, // 삭제
    // required this.bpmChangedByTap, // 삭제
    // required this.bpmIndicatorScale, // 삭제
    // required this.bpmIndicatorColor, // 삭제
    // required this.bpmTextColor, // 삭제
    // required this.tapTimestamps, // 삭제
    required this.currentManualBpm,
    required this.onChangeSpeedPreset,
    required this.onChangeSpeed,
    required this.onStartSpeedAdjustTimer,
    required this.onStopSpeedAdjustTimer,
    // required this.onHandleTapForBpm, // 삭제
    required this.progressPercent,
    required this.isPlaying,
    this.audioDuration,
    required this.currentPlaybackSpeed,
    required this.onPlayPause,
    required this.onStop,
    required this.onPomodoroButtonPressed,
    required this.speedPresetSlow, // 이름 변경
    required this.speedPresetNormal, // 이름 변경
    required this.speedPresetFast, // 이름 변경
    // final PlayMode playMode, // 제거
    required this.isYoutubeMode,
    required this.currentPomodoroState,
    required this.pomodoroCycleCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bool localAudioControlsEnabled =
        currentPomodoroState == PomodoroState.stopped &&
        !isLoadingSong &&
        !isYoutubeMode;
    final bool
    speedControlsEnabled = // bpmControlsEnabled -> speedControlsEnabled
        currentPomodoroState == PomodoroState.stopped && !isLoadingSong;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (isLoadingSong && !isYoutubeMode)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // if (!isYoutubeMode) // SongSelectionWidget 제거
                  //   SongSelectionWidget(
                  //     songList: [], // songList 제거됨
                  //     selectedSong: selectedSong,
                  //     isLoading: isLoadingSong,
                  //     isChallengeRunning: isChallengeRunning,
                  //     onSongChanged: (song) {}, // onSongChanged 제거됨
                  //   ),
                  // const SizedBox(height: 16), // PlaybackModeControlWidget 제거로 인한 간격 조정 불필요 또는 재조정
                  // PlaybackModeControlWidget 제거
                  // PlaybackModeControlWidget(
                  //   currentPlayMode: PlayMode.normal, // playMode 제거됨
                  //   onPlayModeChanged: (mode) {}, // onPlayModeChanged 제거됨
                  //   isDisabled: isLoadingSong || isChallengeRunning,
                  // ),
                  // const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      selectedSong.title,
                      style: theme.textTheme.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (selectedSong.categoryType != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        '분류: ${selectedSong.categoryType.name}',
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TimerDisplayWidget(
                    isLoadingSong: isLoadingSong,
                    timerText: timerText,
                    borderRadius: defaultBorderRadius,
                  ),
                  const SizedBox(height: 24), // 간격 증가
                  if (speedControlsEnabled)
                    SpeedControlSectionWidget(
                      isLoadingSong: isLoadingSong,
                      isPomodoroActive:
                          currentPomodoroState !=
                          PomodoroState
                              .stopped, // isChallengeRunning 대신 isPomodoroActive 사용 및 값 전달
                      onChangeSpeedPreset: onChangeSpeedPreset,
                      onChangeSpeed: onChangeSpeed,
                      onStartSpeedAdjustTimer: onStartSpeedAdjustTimer,
                      onStopSpeedAdjustTimer: onStopSpeedAdjustTimer,
                      speedPresetSlow: speedPresetSlow,
                      speedPresetNormal: speedPresetNormal,
                      speedPresetFast: speedPresetFast,
                    ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.border.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProgressDisplayWidget(
                  isLoadingSong: isLoadingSong,
                  currentPomodoroState: currentPomodoroState,
                  progressPercent: progressPercent,
                ),
                const SizedBox(height: 16),
                if (localAudioControlsEnabled)
                  MusicControlWidget(
                    isLoadingSong: isLoadingSong,
                    currentPomodoroState: currentPomodoroState,
                    isPlaying: isPlaying,
                    selectedSong: selectedSong,
                    audioDuration: audioDuration,
                    currentPlaybackSpeed: currentPlaybackSpeed,
                    currentManualBpm: currentManualBpm,
                    defaultBorderRadius: defaultBorderRadius,
                    onPlayPause: onPlayPause,
                    onStop: onStop,
                  ),
                if (localAudioControlsEnabled) const SizedBox(height: 16),
                PomodoroControlButtonWidget(
                  isLoadingSong: isLoadingSong,
                  currentPomodoroState: currentPomodoroState,
                  onPressed: onPomodoroButtonPressed,
                  cycleCount: pomodoroCycleCount,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
