import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide BorderStyle;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/song.dart'; // 상대 경로 또는 package:rhythm_farmer_mate/models/song.dart
import '../models/song_category.dart'; // SongCategoryType enum import 추가
import '../widgets/home_content_widget.dart'; // 새로 추가된 위젯
import 'package:rhythm_farmer_mate/my_app.dart'; // themeModeNotifier 접근을 위해 추가 (또는 별도 파일로 분리)
// import '../widgets/metronome_settings_dialog_widget.dart'; // 삭제
import '../services/audio_service.dart'; // AudioService 추가
// import '../services/bpm_service.dart'; // 삭제
// import '../services/challenge_service.dart'; // 삭제됨
import '../widgets/pomodoro_control_button_widget.dart'
    show PomodoroState, PomodoroControlButtonWidget; // PomodoroState 임포트 확인
import '../widgets/playlist_dialog_widget.dart'; // 새로 추가된 위젯

// 재생 모드 정의
enum PlayMode {
  normal, // 기본 재생 (한 곡 재생 후 정지)
  repeat, // 한 곡 반복 재생
  allSongs, // 전체 목록 순차 재생 (추가)
  shuffle, // 랜덤 재생 (추가)
}

// enum PomodoroState { // 이 부분을 주석 처리 또는 삭제
//   work,
//   shortBreak,
//   stopped,
// }

class MyHomePage extends StatefulWidget {
  final Song selectedSong;
  final PlayMode initialPlayMode;
  final List<Song>? songList;

  const MyHomePage({
    super.key,
    required this.selectedSong,
    this.initialPlayMode = PlayMode.normal,
    this.songList,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioService _audioService;
  YoutubePlayerController? _youtubeController;
  bool _isPlaying = false;
  Duration? _audioDuration;
  bool _isLoadingSong = true;
  Timer? _pomodoroTimer; // _timer 변수명을 _pomodoroTimer로 변경 또는 그대로 사용
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isChallengeRunning = false; // 삭제
  double _progressPercent = 0.0;
  bool _beatHighlighter = false;
  bool _isMetronomeSoundEnabled = true; // 메트로놈 소리 활성화 여부 상태

  // 재생 모드 상태 변수
  late PlayMode _playMode;
  final Random _random = Random();
  late Song _currentSelectedSong;
  late List<Song> _currentPlaylist;
  int _currentSongIndex = 0;
  late int _currentManualBpm;
  double _currentPlaybackSpeed = 1.0;
  bool _isYoutubePlaying = false; // 유튜브 재생 상태 관찰용 (YoutubeValueBuilder에서 업데이트)
  Duration _youtubeDuration =
      Duration.zero; // 유트브 영상 길이 (YoutubeValueBuilder에서 업데이트)

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  final List<DateTime> _tapTimestamps = [];
  Timer? _tapTempoResetTimer;
  static const int _minTapsForBpm = 2;
  static const Duration _tapTempoTimeout = Duration(seconds: 2);
  bool _bpmChangedByTap = false;
  Timer? _speedAdjustTimer;

  PomodoroState _pomodoroState = PomodoroState.stopped; // 타입 명시
  int _pomodoroCycleCount = 0;

  static const Duration _workDuration = Duration(minutes: 25);
  static const Duration _shortBreakDuration = Duration(minutes: 5);

  bool get _isYoutubeMode => _currentSelectedSong.youtubeVideoId != null;

  List<int> _playedShuffleIndices = []; // 셔플 모드에서 이미 재생된 곡들의 인덱스 저장

  @override
  void initState() {
    super.initState();
    _playMode = widget.initialPlayMode;
    _currentPlaylist =
        (widget.songList != null && widget.songList!.isNotEmpty)
            ? List.from(widget.songList!)
            : [widget.selectedSong];

    if (_currentPlaylist.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_playMode == PlayMode.shuffle && _currentPlaylist.isNotEmpty) {
      _playedShuffleIndices.clear(); // 셔플 모드 시작 시 재생 기록 초기화
      _currentSongIndex = _random.nextInt(_currentPlaylist.length);
      _playedShuffleIndices.add(_currentSongIndex); // 첫 곡도 재생 기록에 추가
    } else {
      _currentSongIndex = _currentPlaylist.indexOf(widget.selectedSong);
      if (_currentSongIndex == -1) {
        _currentSelectedSong = widget.selectedSong;
        _currentPlaylist = [widget.selectedSong];
        _currentSongIndex = 0;
      }
    }
    if (_currentPlaylist.isNotEmpty) {
      _currentSelectedSong = _currentPlaylist[_currentSongIndex];
    }

    _currentManualBpm =
        _currentSelectedSong.bpm > 0 ? _currentSelectedSong.bpm : 90;
    _audioService = AudioService();
    _initAudio();
  }

  void _initAudio() {
    if (_isYoutubeMode) {
      Future.microtask(() => _initializeYoutubePlayer());
    } else if (_currentSelectedSong.filePath != null &&
        _currentSelectedSong.filePath!.isNotEmpty) {
      _setupAudioServiceCallbacks();
      _initAudioService();
    } else {
      if (mounted) setState(() => _isLoadingSong = false);
    }
    _updateTimerText();
    _updateProgress();
  }

  void _initializeYoutubePlayer() async {
    if (_currentSelectedSong.youtubeVideoId == null) {
      if (mounted) setState(() => _isLoadingSong = false);
      return;
    }
    await _youtubeController?.close(); // 이전 컨트롤러가 있다면 확실히 close
    if (mounted) setState(() => _isLoadingSong = true);
    final params = const YoutubePlayerParams(
      showControls: false,
      showFullscreenButton: false,
      strictRelatedVideos: true,
      enableCaption: false,
      color: 'red',
      interfaceLanguage: 'ko',
    );
    _youtubeController = YoutubePlayerController(params: params);
    await _youtubeController!.loadVideoById(
      videoId: _currentSelectedSong.youtubeVideoId!,
    );

    // listen을 사용하여 YouTube 이벤트 처리
    _youtubeController!.listen(_handleYoutubeStateChanged);

    // 만약 listen으로 즉시 duration을 못가져오는 경우 대비, 짧은 시간 후 강제 로딩 해제
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoadingSong) {
        setState(() => _isLoadingSong = false);
        if (_pomodoroState == PomodoroState.stopped &&
            _youtubeDuration == Duration.zero) {
          _remainingTime = _workDuration; // 대체값
          _updateTimerText();
          _updateProgress();
        }
      }
    });
  }

  // YouTube 플레이어 이벤트 처리 메서드
  void _handleYoutubeStateChanged(YoutubePlayerValue value) {
    if (!mounted) return;

    bool shouldSetState = false;

    // 재생 상태 변경 감지
    if (_isYoutubePlaying != (value.playerState == PlayerState.playing)) {
      _isYoutubePlaying = value.playerState == PlayerState.playing;
      shouldSetState = true;
    }

    // 영상 길이 초기화 및 변경 감지
    if (value.metaData.duration.inSeconds > 0 &&
        _youtubeDuration != value.metaData.duration) {
      _youtubeDuration = value.metaData.duration;
      if (_pomodoroState == PomodoroState.stopped) {
        // 현재 포모도로 상태가 정지 상태일 때만 남은 시간을 업데이트
        _youtubeController!.currentTime.then((currentSeconds) {
          final position = Duration(
            milliseconds: (currentSeconds * 1000).round(),
          );
          _remainingTime = _youtubeDuration - position;
          if (_remainingTime.isNegative) _remainingTime = Duration.zero;
          _updateTimerText();
          _updateProgress();
        });
      }

      if (_isLoadingSong) {
        setState(() => _isLoadingSong = false);
      }

      shouldSetState = true;
    }

    // 타이머가 정지 상태이고 재생 중일 때 시간 업데이트
    if (_pomodoroState == PomodoroState.stopped &&
        _youtubeDuration.inSeconds > 0 &&
        value.playerState == PlayerState.playing) {
      _youtubeController!.currentTime.then((currentSeconds) {
        final position = Duration(
          milliseconds: (currentSeconds * 1000).round(),
        );
        final newRemainingTime = _youtubeDuration - position;
        if (_remainingTime != newRemainingTime &&
            !newRemainingTime.isNegative) {
          _remainingTime = newRemainingTime;
          _updateTimerText();
          if (shouldSetState) {
            _updateProgress();
          }
        }
      });
    }

    // 플레이어 상태 변경 시 화면 갱신
    if (shouldSetState) {
      setState(() {
        _updateProgress();
      });
    }

    // 재생 종료 시 반복 재생 처리
    if (value.playerState == PlayerState.ended &&
        _pomodoroState == PomodoroState.stopped) {
      if (_playMode == PlayMode.repeat) {
        _youtubeController?.seekTo(seconds: 0);
        _youtubeController?.playVideo();
      } else {
        _handleYouTubeVideoEnded();
      }
    }

    // 플레이어 오류 상태 처리
    if (value.playerState == PlayerState.unknown) {
      if (mounted && _isLoadingSong) {
        setState(() => _isLoadingSong = false);
      }
      if (_pomodoroState == PomodoroState.stopped) {
        _remainingTime = _workDuration;
        _updateTimerText();
        _updateProgress();
      }
      print("YouTube Player Unknown State (potential error)");
    }
  }

  void _setupAudioServiceCallbacks() {
    _audioService.onPlayingStateChanged = (playing) {
      // setState(() { _isAudioPlaying = playing; }); // 필요 시 사용
    };
    _audioService.onDurationChanged = (duration) {
      if (mounted && duration != null) {
        if (_pomodoroState == PomodoroState.stopped) {
          _remainingTime = duration;
          _updateTimerText();
          _updateProgress();
        }
      }
    };
    _audioService.onError = (error) {
      if (mounted) setState(() => _isLoadingSong = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오디오 로드 오류: $error')));
    };
    _audioService.onCompletion = () {
      if (_currentSelectedSong.filePath != null &&
          _pomodoroState == PomodoroState.stopped) {
        if (_playMode == PlayMode.repeat) {
          _audioService.seek(Duration.zero);
          _audioService.play();
        }
      }
    };
  }

  void _initAudioService() async {
    if (_currentSelectedSong.filePath == null ||
        _currentSelectedSong.filePath!.isEmpty) {
      if (mounted) setState(() => _isLoadingSong = false);
      return;
    }
    if (mounted) setState(() => _isLoadingSong = true);
    try {
      await _audioService.loadSong(_currentSelectedSong);
      if (mounted) {
        if (_pomodoroState == PomodoroState.stopped &&
            _audioService.duration != null) {
          _remainingTime = _audioService.duration!;
          _updateTimerText();
          _updateProgress();
        }
        setState(() => _isLoadingSong = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSong = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오디오 로드 오류: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _audioService.dispose();
    _pomodoroTimer?.cancel();
    _tapTempoResetTimer?.cancel();
    _speedAdjustTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;
    final Color bpmIndicatorColor;
    final Color bpmTextColor;

    if (_isLoadingSong) {
      bpmIndicatorColor = theme.colorScheme.muted;
      bpmTextColor = theme.colorScheme.mutedForeground;
    } else if (_beatHighlighter) {
      bpmIndicatorColor =
          Color.lerp(theme.colorScheme.card, theme.colorScheme.primary, 0.35) ??
          theme.colorScheme.primary;
      bpmTextColor = theme.colorScheme.primary;
    } else if (_bpmChangedByTap) {
      bpmIndicatorColor =
          Color.lerp(theme.colorScheme.card, theme.colorScheme.primary, 0.1) ??
          theme.colorScheme.card;
      bpmTextColor = theme.colorScheme.primary;
    } else {
      bpmIndicatorColor = theme.colorScheme.card;
      bpmTextColor = theme.colorScheme.foreground;
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: _currentSelectedSong.title,
        onPlaylistPressed: _showPlaylistDialog,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 600 ? 16.0 : 24.0;

              // 통합된 단일 레이아웃 사용 (유튜브/일반 모드 구분 없음)
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: HomeContentWidget(
                        isLoadingSong: _isLoadingSong,
                        selectedSong: _currentSelectedSong,
                        timerText: _timerText,
                        defaultBorderRadius: defaultBorderRadius,
                        currentManualBpm: _currentManualBpm,
                        onChangeSpeedPreset: _changeSpeedToPreset,
                        onChangeSpeed: _changeSpeed,
                        onStartSpeedAdjustTimer:
                            (int delta) => _startSpeedAdjustTimer(delta),
                        onStopSpeedAdjustTimer:
                            () => _speedAdjustTimer?.cancel(),
                        progressPercent: _progressPercent,
                        isPlaying:
                            _isYoutubeMode
                                ? _isYoutubePlaying
                                : _audioService.isPlaying,
                        audioDuration:
                            _isYoutubeMode
                                ? _youtubeDuration
                                : _audioService.duration,
                        currentPlaybackSpeed: _currentPlaybackSpeed,
                        onPlayPause: _handlePlayPause,
                        onStop: _handleStop,
                        onPomodoroButtonPressed: () {
                          if (_pomodoroState == PomodoroState.stopped)
                            _startNextPomodoroPhase();
                          else
                            _stopPomodoro();
                        },
                        speedPresetSlow: slowBpm,
                        speedPresetNormal: normalBpm,
                        speedPresetFast: fastBpm,
                        isYoutubeMode: _isYoutubeMode,
                        currentPomodoroState: _pomodoroState,
                        pomodoroCycleCount: _pomodoroCycleCount,
                        playMode: _playMode,
                        onPlayModeChanged: _changePlayMode,
                        youtubeController: _youtubeController,
                        onChangeToNextSong: _playNextSong,
                        onChangeToPrevSong: _playPrevSong,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPlaylistDialog() {
    showShadDialog(
      context: context,
      builder:
          (dialogContext) => PlaylistDialogWidget(
            songList: _currentPlaylist,
            currentSelectedSong: _currentSelectedSong,
            currentPlayMode: _playMode,
            onSongSelected: (song) {
              Navigator.of(dialogContext).pop();
              int songIndex = _currentPlaylist.indexOf(song);
              if (songIndex != -1) {
                _changeToSongAtIndex(songIndex);
              }
            },
            onOverallPlayModeChanged: (newMode) {
              Navigator.of(dialogContext).pop();
              _changePlayMode(newMode);
            },
          ),
    );
  }

  Future<void> _handlePlayPause() async {
    if (_isLoadingSong || (_pomodoroState == PomodoroState.work)) return;
    if (_isYoutubeMode && _youtubeController != null) {
      if (_isYoutubePlaying)
        await _youtubeController!.pauseVideo();
      else {
        await _youtubeController!.setPlaybackRate(_currentPlaybackSpeed);
        await _youtubeController!.playVideo();
      }
    } else if (!_isYoutubeMode) {
      if (_audioService.isPlaying)
        _audioService.pause();
      else {
        if (_audioService.duration == null) return;
        _audioService.setSpeed(_currentPlaybackSpeed);
        _audioService.play();
      }
    }
  }

  Future<void> _handleStop() async {
    if (_pomodoroState != PomodoroState.stopped)
      _stopPomodoro();
    else {
      if (_isYoutubeMode && _youtubeController != null)
        await _youtubeController!.stopVideo();
      else if (!_isYoutubeMode && _audioService.isPlaying)
        _audioService.stop();
      _remainingTime =
          _isYoutubeMode && _youtubeDuration > Duration.zero
              ? _youtubeDuration
              : (!_isYoutubeMode &&
                      _audioService.duration != null &&
                      _audioService.duration! > Duration.zero
                  ? _audioService.duration!
                  : _workDuration);
      if (_remainingTime == Duration.zero &&
          _pomodoroState == PomodoroState.stopped)
        _remainingTime = _workDuration;
      _progressPercent = 0.0;
    }
    _updateTimerText();
    _updateProgress();
  }

  void _handleYouTubeVideoEnded() {
    if (_pomodoroState == PomodoroState.stopped) {
      _playNextSong();
    }
  }

  void _handleLocalAudioCompletion() {
    if (_currentSelectedSong.filePath != null &&
        _pomodoroState == PomodoroState.stopped) {
      _playNextSong();
    }
  }

  void _playNextSong() {
    if (_currentPlaylist.isEmpty) return;

    if (_playMode == PlayMode.repeat) {
      if (_isYoutubeMode && _youtubeController != null) {
        _youtubeController!.seekTo(seconds: 0);
        _youtubeController!.playVideo();
      } else if (!_isYoutubeMode) {
        _audioService.seek(Duration.zero);
        _audioService.play();
      }
      return;
    }

    if (_playMode == PlayMode.normal) {
      if (_currentPlaylist.length <= 1 ||
          _currentSongIndex >= _currentPlaylist.length - 1) {
        if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying)
          _youtubeController!.pauseVideo();
        else if (!_isYoutubeMode && _audioService.isPlaying)
          _audioService.pause();
        return;
      }
      _currentSongIndex = (_currentSongIndex + 1) % _currentPlaylist.length;
    } else if (_playMode == PlayMode.allSongs) {
      _currentSongIndex = (_currentSongIndex + 1) % _currentPlaylist.length;
    } else if (_playMode == PlayMode.shuffle) {
      if (_currentPlaylist.length > 1) {
        if (_playedShuffleIndices.length >= _currentPlaylist.length) {
          _playedShuffleIndices.clear(); // 모든 곡을 한 번씩 다 재생했으면 기록 초기화
        }
        int nextIndex;
        do {
          nextIndex = _random.nextInt(_currentPlaylist.length);
        } while (_playedShuffleIndices.contains(nextIndex)); // 아직 재생 안 된 곡 선택
        _currentSongIndex = nextIndex;
        _playedShuffleIndices.add(_currentSongIndex); // 재생 기록에 추가
      } else {
        _currentSongIndex = 0; // 곡이 하나면 그냥 그 곡 (또는 재생 중지)
        if (_playedShuffleIndices.isEmpty) _playedShuffleIndices.add(0);
      }
    }

    _changeToSongAtIndex(_currentSongIndex);
  }

  // 이전 곡 재생 메서드
  void _playPrevSong() {
    if (_currentPlaylist.isEmpty) return;

    if (_playMode == PlayMode.repeat) {
      if (_isYoutubeMode && _youtubeController != null) {
        _youtubeController!.seekTo(seconds: 0);
        _youtubeController!.playVideo();
      } else if (!_isYoutubeMode) {
        _audioService.seek(Duration.zero);
        _audioService.play();
      }
      return;
    }

    if (_playMode == PlayMode.normal) {
      if (_currentPlaylist.length <= 1 || _currentSongIndex <= 0) {
        if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying)
          _youtubeController!.pauseVideo();
        else if (!_isYoutubeMode && _audioService.isPlaying)
          _audioService.pause();
        return;
      }
      _currentSongIndex = (_currentSongIndex - 1);
    } else if (_playMode == PlayMode.allSongs) {
      _currentSongIndex =
          (_currentSongIndex - 1 + _currentPlaylist.length) %
          _currentPlaylist.length;
    } else if (_playMode == PlayMode.shuffle) {
      // 셔플 모드에서는 이전에 재생된 기록이 있으면 그 곡으로 이동
      if (_playedShuffleIndices.length > 1) {
        // 현재 인덱스를 제거하고 이전 인덱스로 이동
        _playedShuffleIndices.removeLast();
        _currentSongIndex = _playedShuffleIndices.last;
      } else {
        // 처음 곡이거나 기록이 부족할 경우 랜덤한 곡 선택
        int prevIndex;
        do {
          prevIndex = _random.nextInt(_currentPlaylist.length);
        } while (prevIndex == _currentSongIndex && _currentPlaylist.length > 1);
        _currentSongIndex = prevIndex;
        // 현재 인덱스가 있으면 유지, 없으면 새로 추가
        if (_playedShuffleIndices.isEmpty) {
          _playedShuffleIndices.add(_currentSongIndex);
        } else {
          _playedShuffleIndices[0] = _currentSongIndex;
        }
      }
    }

    _changeToSongAtIndex(_currentSongIndex);
  }

  void _changeToSongAtIndex(int index) {
    if (index < 0 || index >= _currentPlaylist.length) return;

    // 기존 오디오/비디오 정지
    if (_isYoutubeMode && _youtubeController != null) {
      _youtubeController!.stopVideo();
    } else if (!_isYoutubeMode) {
      _audioService.stop();
    }

    // 다음 곡으로 상태 업데이트
    setState(() {
      _currentSongIndex = index;
      _currentSelectedSong = _currentPlaylist[index];
      _isLoadingSong = true;
      _currentManualBpm =
          _currentSelectedSong.bpm > 0 ? _currentSelectedSong.bpm : 90;
      _youtubeDuration = Duration.zero;
      _remainingTime = Duration.zero;
      _progressPercent = 0.0;
      _updateTimerText();
      // _isYoutubePlaying = false; // _initAudio에서 처리됨
      // _audioService.isPlaying는 AudioService 내부 상태
    });
    _initAudio();
  }

  void _startNextPomodoroPhase() {
    if (_pomodoroState == PomodoroState.stopped ||
        _pomodoroState == PomodoroState.shortBreak) {
      setState(() {
        _pomodoroState = PomodoroState.work;
        _remainingTime = _workDuration;
        if (_pomodoroState == PomodoroState.stopped) _pomodoroCycleCount = 0;
      });
      if (!_isYoutubeMode && !_audioService.isPlaying)
        _audioService.play();
      else if (_isYoutubeMode &&
          _youtubeController != null &&
          !_isYoutubePlaying)
        _youtubeController!.playVideo();
    } else if (_pomodoroState == PomodoroState.work) {
      setState(() {
        _pomodoroState = PomodoroState.shortBreak;
        _remainingTime = _shortBreakDuration;
        _pomodoroCycleCount++;
      });
    }
    _startTimer();
  }

  void _stopPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoroState = PomodoroState.stopped;
      _remainingTime =
          _isYoutubeMode && _youtubeDuration > Duration.zero
              ? _youtubeDuration
              : (!_isYoutubeMode &&
                      _audioService.duration != null &&
                      _audioService.duration! > Duration.zero
                  ? _audioService.duration!
                  : _workDuration);
      if (_remainingTime == Duration.zero &&
          _pomodoroState == PomodoroState.stopped)
        _remainingTime = _workDuration;
      _progressPercent = 0.0;
      _pomodoroCycleCount = 0;
    });
    _updateTimerText();
    _updateProgress();
    if (!_isYoutubeMode && _audioService.isPlaying)
      _audioService.pause();
    else if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying)
      _youtubeController!.pauseVideo();
  }

  void _startTimer() {
    _pomodoroTimer?.cancel();
    _updateTimerText();
    _updateProgress();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        String message = '';
        if (_pomodoroState == PomodoroState.work)
          message = '농사 시간 종료! 휴식을 시작하세요.';
        else if (_pomodoroState == PomodoroState.shortBreak)
          message = '휴식 시간 종료! 다음 농사를 시작하세요.';
        if (message.isNotEmpty && mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        setState(() {});
        _remainingTime = Duration.zero;
        _updateTimerText();
        _updateProgress();
      } else {
        if (mounted) {
          setState(() {
            _remainingTime -= const Duration(seconds: 1);
          });
          _updateTimerText();
          await _updateProgress();
        }
      }
    });
  }

  @override
  Future<void> _updateProgress() async {
    if (!mounted) return;
    double newProgress = 0.0;
    Duration totalDurationForCurrentPhase;
    if (_pomodoroState == PomodoroState.work)
      totalDurationForCurrentPhase = _workDuration;
    else if (_pomodoroState == PomodoroState.shortBreak)
      totalDurationForCurrentPhase = _shortBreakDuration;
    else {
      if (mounted)
        setState(() {
          _progressPercent = 0.0;
        });
      return;
    }

    if (totalDurationForCurrentPhase.inSeconds > 0) {
      Duration elapsedTime = totalDurationForCurrentPhase - _remainingTime;
      if (elapsedTime.isNegative) elapsedTime = Duration.zero;
      if (elapsedTime > totalDurationForCurrentPhase)
        elapsedTime = totalDurationForCurrentPhase;
      newProgress =
          elapsedTime.inSeconds.toDouble() /
          totalDurationForCurrentPhase.inSeconds.toDouble();
    } else if (_remainingTime.inSeconds <= 0 &&
        _pomodoroState != PomodoroState.stopped)
      newProgress = 1.0;

    newProgress = newProgress.clamp(0.0, 1.0);
    if (mounted)
      setState(() {
        _progressPercent = newProgress;
      });
  }

  void _updateTimerText() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    if (mounted)
      setState(() {
        _timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';
      });
  }

  void _changeSpeedToPreset(int presetValue) {
    if (_isLoadingSong) return;
    double newSpeed;
    if (presetValue == slowBpm)
      newSpeed = 0.5;
    else if (presetValue == normalBpm)
      newSpeed = 1.0;
    else if (presetValue == fastBpm)
      newSpeed = 1.5;
    else
      newSpeed = 1.0;
    setState(() {
      _currentPlaybackSpeed = newSpeed;
    });
    if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying)
      _youtubeController!.setPlaybackRate(newSpeed);
    else if (!_isYoutubeMode && _audioService.isPlaying)
      _audioService.setSpeed(newSpeed);
  }

  void _changeSpeed(int delta) {
    if (_isLoadingSong) return;
    double newSpeed = (_currentPlaybackSpeed + (delta * 0.1)).clamp(0.5, 2.0);
    newSpeed = (newSpeed * 10).round() / 10;
    setState(() {
      _currentPlaybackSpeed = newSpeed;
    });
    if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying)
      _youtubeController!.setPlaybackRate(newSpeed);
    else if (!_isYoutubeMode && _audioService.isPlaying)
      _audioService.setSpeed(newSpeed);
  }

  void _startSpeedAdjustTimer(int delta) {
    _speedAdjustTimer?.cancel();
    _speedAdjustTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      _changeSpeed(delta);
    });
  }

  void _changePlayMode(PlayMode mode) {
    setState(() {
      _playMode = mode;
      if (mode == PlayMode.shuffle) {
        _playedShuffleIndices.clear(); // 셔플 모드로 변경 시 재생 기록 초기화
        if (_currentPlaylist.isNotEmpty) {
          // 현재 재생 중인 곡은 유지하고, 다음 곡부터 셔플 적용 또는 즉시 다른 곡 셔플
          // 여기서는 다음 곡부터 적용되도록 _playedShuffleIndices만 초기화
          // 만약 현재 곡도 셔플 대상에 포함시키고 싶다면, 여기서 _playNextSong() 호출 고려
          // 현재 곡을 playedIndices에 먼저 추가
          if (!_playedShuffleIndices.contains(_currentSongIndex)) {
            _playedShuffleIndices.add(_currentSongIndex);
          }
        }
      }
    });
    if (!_isYoutubeMode) {
      _audioService.setLoopMode(
        mode == PlayMode.repeat
            ? just_audio.LoopMode.one
            : just_audio.LoopMode.off,
      );
    } else {
      // YouTube의 경우, PlayMode.repeat는 _handleYouTubeVideoEnded에서 이미 처리 중.
      // PlayMode.allSongs나 PlayMode.shuffle은 _playNextSong 로직에 따름.
    }
    // 현재 재생 중인 곡에 새 모드를 바로 적용할지 여부 (예: allSongs로 바꾸면 바로 다음 곡 준비?)
    // 여기서는 다음 곡 재생 시점에 새 모드가 적용되도록 함.
  }
}

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPlaylistPressed;

  const AppBarWidget({Key? key, required this.title, this.onPlaylistPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      title: Text(
        title.isNotEmpty ? title : '리듬농부 메이트',
        style: theme.textTheme.h4.copyWith(
          color: theme.colorScheme.primaryForeground,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (onPlaylistPressed != null)
          ShadButton.ghost(
            icon: Icon(
              Icons.queue_music_rounded,
              color: theme.colorScheme.primaryForeground,
            ),
            onPressed: onPlaylistPressed,
          ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, currentMode, child) {
            return ShadButton.ghost(
              icon: Icon(
                currentMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: theme.colorScheme.primaryForeground,
              ),
              onPressed: () {
                themeModeNotifier.value =
                    currentMode == ThemeMode.light
                        ? ThemeMode.dark
                        : currentMode == ThemeMode.dark
                        ? ThemeMode.system
                        : ThemeMode.light;
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
