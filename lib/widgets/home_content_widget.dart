import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../models/song_category.dart'; // SongCategoryType을 사용하기 위해 추가
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
  final bool isYoutubeMode;

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
    required this.isYoutubeMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bool localAudioControlsEnabled =
        !isChallengeRunning && !isLoadingSong && !isYoutubeMode;
    final bool bpmControlsEnabled = !isChallengeRunning && !isLoadingSong;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 스크롤 가능한 상단 영역 (컨텐츠 영역)
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
                  if (isLoadingSong && !isYoutubeMode) // 유튜브 로딩은 플레이어가 처리
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!isYoutubeMode)
                    SongSelectionWidget(
                      songList: songList,
                      selectedSong: selectedSong,
                      isLoading: isLoadingSong,
                      isChallengeRunning: isChallengeRunning,
                      onSongChanged: onSongChanged,
                      initialFilterCategory: null, // 초기 필터 설정 없음
                    ),
                  const SizedBox(height: 16),
                  PlaybackModeControlWidget(
                    currentPlayMode: playMode,
                    onPlayModeChanged: onPlayModeChanged,
                    isDisabled: isLoadingSong || isChallengeRunning,
                  ),
                  const SizedBox(height: 16),
                  TimerDisplayWidget(
                    isLoadingSong: isLoadingSong,
                    timerText: timerText,
                    borderRadius: defaultBorderRadius,
                  ),
                  const SizedBox(height: 16),
                  if (bpmControlsEnabled)
                    BpmControlSectionWidget(
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
                ],
              ),
            ),
          ),
        ),

        // 하단 고정 영역 (제어 영역) - SafeArea로 감싸서 안전한 영역에 표시
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
                  isChallengeRunning: isChallengeRunning,
                  progressPercent: progressPercent,
                ),
                const SizedBox(height: 16),
                if (localAudioControlsEnabled)
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
                if (localAudioControlsEnabled) const SizedBox(height: 16),
                ChallengeControlButtonWidget(
                  isLoadingSong: isLoadingSong,
                  isChallengeRunning: isChallengeRunning,
                  onPressed: onChallengeButtonPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
