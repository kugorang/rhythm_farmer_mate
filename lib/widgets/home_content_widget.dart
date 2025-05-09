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
    show PomodoroState, PlayMode; // PomodoroState enum 가져오기, PlayMode 추가
import 'package:rhythm_farmer_mate/widgets/pomodoro_control_button_widget.dart'
    show PomodoroState, PomodoroControlButtonWidget; // PomodoroState와 위젯 모두 가져옴
import './playback_mode_control_widget.dart'; // PlaybackModeControlWidget 임포트 추가
// import './song_selection_widget.dart';
// import './playback_mode_control_widget.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  final PlayMode playMode;
  final Function(PlayMode) onPlayModeChanged;
  final bool isYoutubeMode;
  final PomodoroState currentPomodoroState;
  final int pomodoroCycleCount;
  final YoutubePlayerController? youtubeController;
  final Function() onChangeToNextSong; // 다음 곡 변경 콜백 추가
  final Function() onChangeToPrevSong; // 이전 곡 변경 콜백 추가

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
    required this.playMode,
    required this.onPlayModeChanged,
    required this.isYoutubeMode,
    required this.currentPomodoroState,
    required this.pomodoroCycleCount,
    required this.onChangeToNextSong, // 필수 매개변수로 추가
    required this.onChangeToPrevSong, // 필수 매개변수로 추가
    this.youtubeController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bool localAudioControlsEnabled =
        currentPomodoroState == PomodoroState.stopped &&
        audioDuration != null &&
        !isLoadingSong &&
        !isYoutubeMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isLoadingSong && !isYoutubeMode)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (isYoutubeMode && youtubeController != null)
          _buildYoutubePlayer(context),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ShadCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 타이머 및 곡 정보
                        const SizedBox(height: 16),
                        Text(
                          selectedSong.title,
                          style: theme.textTheme.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '속도: ${selectedSong.bpm}',
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          timerText,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            height: 10,
                            child: ShadProgress(value: progressPercent),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // 속도 조절 범위가 있을 때만 표시
                if (localAudioControlsEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: theme.colorScheme.border,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          // 속도 조절 UI 내용
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      // 재생 콘트롤 버튼들 (재생/일시정지, 정지)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShadButton(
                            size: ShadButtonSize.lg,
                            onPressed: onPlayPause,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 32,
                            ),
                            child: Text(
                              isPlaying ? '일시정지' : '재생하기',
                              style: theme.textTheme.p.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          ShadButton(
                            size: ShadButtonSize.lg,
                            onPressed: onStop,
                            icon: const Icon(Icons.stop_circle, size: 32),
                            child: Text(
                              '처음으로',
                              style: theme.textTheme.p.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 재생 속도 조절 및 다음 곡 버튼
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 0.5배속
                            Tooltip(
                              message: '0.5배속',
                              child: ShadButton.ghost(
                                onPressed:
                                    () => onChangeSpeedPreset(speedPresetSlow),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        currentPlaybackSpeed == 0.5
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.2)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    '0.5x',
                                    style: TextStyle(
                                      color:
                                          currentPlaybackSpeed == 0.5
                                              ? theme.colorScheme.primary
                                              : theme
                                                  .colorScheme
                                                  .mutedForeground,
                                      fontWeight:
                                          currentPlaybackSpeed == 0.5
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 1.0배속
                            Tooltip(
                              message: '1.0배속',
                              child: ShadButton.ghost(
                                onPressed:
                                    () =>
                                        onChangeSpeedPreset(speedPresetNormal),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        currentPlaybackSpeed == 1.0
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.2)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    '1.0x',
                                    style: TextStyle(
                                      color:
                                          currentPlaybackSpeed == 1.0
                                              ? theme.colorScheme.primary
                                              : theme
                                                  .colorScheme
                                                  .mutedForeground,
                                      fontWeight:
                                          currentPlaybackSpeed == 1.0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 1.5배속
                            Tooltip(
                              message: '1.5배속',
                              child: ShadButton.ghost(
                                onPressed:
                                    () => onChangeSpeedPreset(speedPresetFast),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        currentPlaybackSpeed == 1.5
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.2)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    '1.5x',
                                    style: TextStyle(
                                      color:
                                          currentPlaybackSpeed == 1.5
                                              ? theme.colorScheme.primary
                                              : theme
                                                  .colorScheme
                                                  .mutedForeground,
                                      fontWeight:
                                          currentPlaybackSpeed == 1.5
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 구분선
                            const SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 1,
                              color: theme.colorScheme.border,
                            ),
                            const SizedBox(width: 8),

                            // 이전 곡 버튼
                            Tooltip(
                              message: '이전 곡',
                              child: ShadButton.ghost(
                                onPressed: onChangeToPrevSong,
                                child: Icon(
                                  Icons.skip_previous_rounded,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),

                            // 다음 곡 버튼
                            Tooltip(
                              message: '다음 곡',
                              child: ShadButton.ghost(
                                onPressed: onChangeToNextSong,
                                child: Icon(
                                  Icons.skip_next_rounded,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 재생 모드 선택 버튼들
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: '단일 재생',
                              child: ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed:
                                    () => onPlayModeChanged(PlayMode.normal),
                                child: Icon(
                                  Icons.arrow_right_alt,
                                  color:
                                      playMode == PlayMode.normal
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.mutedForeground,
                                  size: 24,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: '한 곡 반복',
                              child: ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed:
                                    () => onPlayModeChanged(PlayMode.repeat),
                                child: Icon(
                                  Icons.repeat_one,
                                  color:
                                      playMode == PlayMode.repeat
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.mutedForeground,
                                  size: 24,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: '전체 재생',
                              child: ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed:
                                    () => onPlayModeChanged(PlayMode.allSongs),
                                child: Icon(
                                  Icons.repeat,
                                  color:
                                      playMode == PlayMode.allSongs
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.mutedForeground,
                                  size: 24,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: '랜덤 재생',
                              child: ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed:
                                    () => onPlayModeChanged(PlayMode.shuffle),
                                child: Icon(
                                  Icons.shuffle,
                                  color:
                                      playMode == PlayMode.shuffle
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.mutedForeground,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 포모도로 시작/중지 버튼
                      currentPomodoroState == PomodoroState.stopped
                          ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: ShadButton.outline(
                              size: ShadButtonSize.lg,
                              onPressed: onPomodoroButtonPressed,
                              icon: const Icon(Icons.timer_outlined, size: 32),
                              child: Text(
                                '작업 시작하기',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                          : Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: ShadButton.destructive(
                              size: ShadButtonSize.lg,
                              onPressed: onPomodoroButtonPressed,
                              icon: const Icon(Icons.stop, size: 32),
                              child: Text(
                                '작업 중단하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                      // 포모도로 상태 표시
                      if (currentPomodoroState != PomodoroState.stopped)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            currentPomodoroState == PomodoroState.work
                                ? '작업 중... (${pomodoroCycleCount + 1}번째)'
                                : '휴식 중... (${pomodoroCycleCount}번 완료)',
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  currentPomodoroState == PomodoroState.work
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYoutubePlayer(BuildContext context) {
    final theme = ShadTheme.of(context);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 600.0 : size.width - 32;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: Colors.black,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxWidth * 9 / 16, // 16:9 비율 유지
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: youtubeController!,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      ),
    );
  }
}
