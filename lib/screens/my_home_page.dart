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
import '../widgets/playlist_dialog_widget.dart'; // 새로 추가된 위젯
import '../widgets/metronome_settings_dialog_widget.dart'; // 새로 추가된 위젯
import '../services/audio_service.dart'; // AudioService 추가
import '../services/bpm_service.dart';
import '../services/challenge_service.dart';

// 재생 모드 정의
enum PlayMode {
  normal, // 기본 재생 (한 곡 재생 후 정지)
  repeat, // 한 곡 반복 재생
  allSongs, // 전체 목록 순차 재생
  shuffle, // 랜덤 재생
}

class MyHomePage extends StatefulWidget {
  final SongCategoryType? selectedCategoryType;
  final List<Song>? userSongs; // 사용자가 추가한 곡 목록 파라미터

  const MyHomePage({
    super.key,
    this.selectedCategoryType,
    this.userSongs, // 생성자에 추가
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
  Timer? _timer; // 작업(챌린지) 타이머
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isChallengeRunning = false; // << 핵심 상태 변수: 작업(챌린지) 실행 여부
  double _progressPercent = 0.0;
  bool _beatHighlighter = false;
  bool _isMetronomeSoundEnabled = true; // 메트로놈 소리 활성화 여부 상태

  // 재생 모드 상태 변수
  PlayMode _playMode = PlayMode.normal;
  final Random _random = Random();
  int _currentSongIndex = 0;

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  final List<DateTime> _tapTimestamps = [];
  Timer? _tapTempoResetTimer;
  static const int _minTapsForBpm = 2;
  static const Duration _tapTempoTimeout = Duration(seconds: 2);
  bool _bpmChangedByTap = false;
  Timer? _bpmAdjustTimer;

  List<Song> _filteredSongList = []; // 현재 카테고리에 맞는 곡 목록

  final List<Song> _fullSongList = const [
    Song(
      filePath: 'assets/audio/emart_original.mp3',
      title: '이마트 로고송',
      bpm: 100,
      categoryType: SongCategoryType.modernLaborSong,
    ),
    Song(
      filePath: 'assets/audio/se0101.mp3',
      title: '논삶는소리 (강원 홍천군)',
      bpm: 69,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '논고르기', // 예시 하위 카테고리
    ),
    Song(
      filePath: 'assets/audio/se0102.mp3',
      title: '논고르는소리 (제주 서귀포시)',
      bpm: 93,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '논고르기',
    ),
    Song(
      filePath: 'assets/audio/se0103.mp3',
      title: '모찌는소리-"얼른 하더니 한 춤" (강원 양양군)',
      bpm: 70,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '모찌기',
    ),
    Song(
      filePath: 'assets/audio/se0104.mp3',
      title: '모찌는소리-"뭉치세 제치세" (충북 진천군)',
      bpm: 76,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '모찌기',
    ),
    Song(
      filePath: 'assets/audio/se0201.mp3',
      title: '논매는소리-"헤헤 곯었네" (경기 안성군)',
      bpm: 52,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0202.mp3',
      title: '논매는소리-대허리 (경기 이천군)',
      bpm: 115,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0203.mp3',
      title: '논매는소리-오독떼기 (강원 양양군)',
      bpm: 107,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0204.mp3',
      title: '논매는소리-"얼카 덩어리" (충남 홍성군)',
      bpm: 62,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0301.mp3',
      title: '논매는소리-긴소리/들래기소리 (전남 무안군)',
      bpm: 66,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0302.mp3',
      title: '논매는소리-소오니소리 (경북 구미시)',
      bpm: 55,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0303.mp3',
      title: '논매는소리 (경북 예천군)',
      bpm: 78,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0304.mp3',
      title: '농사장원례소리-애롱대롱 (전남 나주군)',
      bpm: 91,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '기타',
    ),
    Song(
      filePath: 'assets/audio/se0401.mp3',
      title: '밭가는소리 (강원 홍천군)',
      bpm: 132,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0402.mp3',
      title: '밭일구는소리(따비질) (제주 북제주군)',
      bpm: 72,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0403.mp3',
      title: '밭고르는소리(곰방메질) (제주 북제주군)',
      bpm: 64,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0404.mp3',
      title: '밭밟는소리 (제주 북제주군)',
      bpm: 69,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
  ];
  late Song _selectedSong;
  late int _currentManualBpm;
  double _currentPlaybackSpeed = 1.0;
  bool _isYoutubePlaying = false; // 유튜브 재생 상태 관찰용 (YoutubeValueBuilder에서 업데이트)
  Duration _youtubeDuration =
      Duration.zero; // 유튜브 영상 길이 (YoutubeValueBuilder에서 업데이트)

  static const double slowSpeed = 0.5;
  static const double normalSpeed = 1.0;
  static const double fastSpeed = 1.5;

  bool get _isYoutubeMode => _selectedSong.youtubeVideoId != null;

  @override
  void initState() {
    super.initState();

    _initSongList();
    _initAudio();
  }

  void _initSongList() {
    // 선택된 카테고리에 따라 곡 목록 필터링 또는 사용자 곡 로드
    if (widget.selectedCategoryType == SongCategoryType.userRegistered &&
        widget.userSongs != null &&
        widget.userSongs!.isNotEmpty) {
      _filteredSongList = List.from(widget.userSongs!);
    } else if (widget.selectedCategoryType != null) {
      _filteredSongList =
          _fullSongList
              .where((song) => song.categoryType == widget.selectedCategoryType)
              .toList();
    } else {
      _filteredSongList = List.from(_fullSongList);
    }

    _currentSongIndex = 0;
    _selectedSong =
        _filteredSongList.isNotEmpty
            ? _filteredSongList[_currentSongIndex]
            : Song(
              filePath: '',
              title: '노래 없음',
              bpm: 0,
              categoryType:
                  widget.selectedCategoryType ??
                  SongCategoryType.modernLaborSong,
            );
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : normalBpm;
  }

  void _initAudio() {
    if (_isYoutubeMode) {
      Future.microtask(() {
        _initializeYoutubePlayer();
      });
      if (mounted) setState(() => _isLoadingSong = false);
    } else if (_selectedSong.filePath != null &&
        _selectedSong.filePath!.isNotEmpty) {
      _audioService = AudioService();
      _setupAudioServiceCallbacks();
      _initAudioService();
    } else {
      if (mounted) setState(() => _isLoadingSong = false);
    }
    _updateTimerText();
  }

  void _initializeYoutubePlayer() {
    if (_selectedSong.youtubeVideoId == null) return;
    try {
      _youtubeController?.close(); // 이전 컨트롤러 정리
      if (mounted) setState(() => _isLoadingSong = true);

      final params = YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        enableCaption: false,
        color: 'red',
        interfaceLanguage: 'ko',
      );

      _youtubeController = YoutubePlayerController(params: params);
      _youtubeController!.loadVideoById(videoId: _selectedSong.youtubeVideoId!);

      // 비디오가 로드될 시간을 약간 줌 (메타데이터 로드 등)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoadingSong = false;
            // 초기 _youtubeDuration 설정은 YoutubeValueBuilder에서 처리.
            // 만약 여기서 기본값을 설정해야 한다면,
            if (_youtubeDuration == Duration.zero) {
              _youtubeDuration = const Duration(minutes: 3); // 임시 기본값
            }
            if (!_isChallengeRunning) {
              _remainingTime = _youtubeDuration;
              _updateTimerText();
              _updateProgress();
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSong = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('유튜브 플레이어 초기화 오류: $e')));
      }
    }
  }

  // _youtubePlayerListener 메서드는 삭제 (YoutubeValueBuilder로 대체)
  // void _youtubePlayerListener() async { ... }

  @override
  void dispose() {
    // _youtubeController?.removeListener(_youtubePlayerListener); // Listener가 없으므로 제거할 필요 없음
    _youtubeController?.close();
    _audioService.dispose();
    _timer?.cancel();
    _tapTempoResetTimer?.cancel();
    _bpmAdjustTimer?.cancel();
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

    Widget playerWidget = const SizedBox.shrink();
    if (_isYoutubeMode && _youtubeController != null) {
      playerWidget = YouTubePlayerWidget(
        controller: _youtubeController!,
        timerText: _timerText,
        progressPercent: _progressPercent,
        isChallengeRunning: _isChallengeRunning,
        onChallengeButtonPressed: () {
          if (_isChallengeRunning) {
            _stopChallenge();
          } else {
            _startChallenge();
          }
        },
        onPlayerStateChanged: (state, position, duration) {
          // 유튜브 플레이어 상태 변경 처리
          if (!mounted) return;

          bool shouldSetState = false;

          // 재생 상태 변경
          if (_isYoutubePlaying != (state == PlayerState.playing)) {
            _isYoutubePlaying = state == PlayerState.playing;
            shouldSetState = true;
          }

          // 영상 정보 변경
          if (duration.inSeconds > 0 && _youtubeDuration != duration) {
            _youtubeDuration = duration;
            if (!_isChallengeRunning) {
              _remainingTime = duration - position;
              if (_remainingTime.isNegative) _remainingTime = Duration.zero;
              _updateTimerText();
            }
            shouldSetState = true;
          }

          // 챌린지 중이 아닐 때 남은 시간 업데이트
          if (!_isChallengeRunning && _youtubeDuration.inSeconds > 0) {
            final newRemainingTime = _youtubeDuration - position;
            if (_remainingTime != newRemainingTime &&
                !newRemainingTime.isNegative) {
              _remainingTime = newRemainingTime;
              _updateTimerText();
              shouldSetState = true;
            }
          }

          if (shouldSetState) {
            setState(() {
              _updateProgress();
            });
          }

          // 영상 종료 처리
          if (state == PlayerState.ended && !_isChallengeRunning) {
            _handleYouTubeVideoEnded();
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: _selectedSong.title,
        onPlaylistPressed: _showPlaylistDialog,
        onMetronomeSettingsPressed: _showMetronomeSettingsDialog,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 600 ? 16.0 : 24.0;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isYoutubeMode) Expanded(child: playerWidget),
                    if (_isYoutubeMode) const SizedBox(height: 16),
                    Expanded(
                      child: HomeContentWidget(
                        isLoadingSong: _isLoadingSong,
                        isChallengeRunning: _isChallengeRunning,
                        selectedSong: _selectedSong,
                        songList: _filteredSongList,
                        onSongChanged: (song) {
                          if (song != null) _onSongChanged(song);
                        },
                        timerText: _timerText,
                        defaultBorderRadius: defaultBorderRadius,
                        beatHighlighter: _beatHighlighter,
                        bpmChangedByTap: _bpmChangedByTap,
                        bpmIndicatorScale: _beatHighlighter ? 1.1 : 1.0,
                        bpmIndicatorColor: bpmIndicatorColor,
                        bpmTextColor: bpmTextColor,
                        tapTimestamps: _tapTimestamps,
                        currentManualBpm: _currentManualBpm,
                        onChangeBpmToPreset: _changeBpmToPreset,
                        onChangeBpm: _changeBpm,
                        onStartBpmAdjustTimer:
                            (int _) => _startBpmAdjustTimer(),
                        onStopBpmAdjustTimer: () => _bpmAdjustTimer?.cancel(),
                        onHandleTapForBpm: _handleTapForBpm,
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
                        onChallengeButtonPressed: () {
                          if (_isChallengeRunning) {
                            _stopChallenge();
                          } else {
                            _startChallenge();
                          }
                        },
                        slowBpm: slowBpm,
                        normalBpm: normalBpm,
                        fastBpm: fastBpm,
                        playMode: _playMode,
                        onPlayModeChanged: _changePlayMode,
                        isYoutubeMode: _isYoutubeMode,
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

  Future<void> _handlePlayPause() async {
    if (_isLoadingSong || _isChallengeRunning) return;

    if (_isYoutubeMode && _youtubeController != null) {
      if (_isYoutubePlaying) {
        await _youtubeController!.pauseVideo();
      } else {
        await _youtubeController!.setPlaybackRate(
          _currentPlaybackSpeed,
        ); // 재생 시작 전 속도 설정
        await _youtubeController!.playVideo();
      }
    } else if (!_isYoutubeMode) {
      // _selectedSong.filePath != null 조건 대신 사용
      _handlePlayPauseLocal();
    }
  }

  Future<void> _handleStop() async {
    if (_selectedSong.youtubeVideoId != null && _youtubeController != null) {
      await _youtubeController!.stopVideo();
    } else if (_selectedSong.filePath != null) {
      _handleStopLocal();
    }
  }

  // YouTube 재생 종료 처리
  void _handleYouTubeVideoEnded() {
    switch (_playMode) {
      case PlayMode.normal:
        break;
      case PlayMode.repeat:
        _youtubeController?.seekTo(seconds: 0);
        _youtubeController?.playVideo();
        break;
      case PlayMode.allSongs:
      case PlayMode.shuffle:
        int nextIndex = _currentSongIndex;
        if (_playMode == PlayMode.allSongs) {
          nextIndex = (_currentSongIndex + 1) % _filteredSongList.length;
        } else if (_filteredSongList.length > 1) {
          do {
            nextIndex = _random.nextInt(_filteredSongList.length);
          } while (nextIndex == _currentSongIndex &&
              _filteredSongList.length > 1);
        }
        _currentSongIndex = nextIndex;
        _onSongChanged(_filteredSongList[_currentSongIndex]);
        break;
    }
  }

  void _handlePlayPauseLocal() {
    if (_isLoadingSong || _isChallengeRunning) return;

    if (_audioService.isPlaying) {
      _audioService.pause();
    } else {
      if (_audioService.duration == null) return;
      _audioService.setSpeed(_currentPlaybackSpeed); // 재생 시작 시 현재 속도 적용
      _audioService.play();
      if (!_isChallengeRunning) _restartBpmTimer();
    }
  }

  void _handleStopLocal() {
    if (_isLoadingSong || _isChallengeRunning) return;

    _audioService.stop();
    _audioService.stopBpmTicker();
  }

  void _startChallenge() async {
    if (_isChallengeRunning) return;
    Duration challengeTotalDuration;

    if (_isYoutubeMode) {
      if (_youtubeController == null || _youtubeDuration.inSeconds == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('YouTube 영상 정보를 가져오는 중입니다.')),
          );
        }
        return;
      }
      challengeTotalDuration = _youtubeDuration;
      await _youtubeController?.setPlaybackRate(
        _currentPlaybackSpeed,
      ); // 챌린지 시작 시 현재 설정된 속도 적용
      await _youtubeController?.playVideo();
      _restartBpmTimer(); // 시각적 BPM 타이머 시작
    } else {
      if (_audioService.duration == null ||
          _audioService.duration!.inSeconds == 0) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('음악 정보를 가져오는 중입니다.')));
        }
        return;
      }
      _audioService.setSpeed(_currentPlaybackSpeed);
      challengeTotalDuration = Duration(
        seconds:
            (_audioService.duration!.inSeconds / _currentPlaybackSpeed).round(),
      );
      _audioService.play();
      _restartBpmTimer(); // 오디오 BPM 타이머 시작
    }

    _remainingTime = challengeTotalDuration;
    _updateTimerText();
    setState(() {
      _isChallengeRunning = true;
      _beatHighlighter = false;
      _progressPercent = 0.0; // 챌린지 시작 시 진행도 0으로 초기화
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.inSeconds <= 0) {
        _stopChallenge(completed: true);
      } else {
        if (mounted) {
          setState(() {
            _remainingTime -= const Duration(seconds: 1);
          });
          _updateTimerText();
          await _updateProgress(); // 매초 진행도 업데이트
        }
      }
    });
  }

  Future<void> _stopChallenge({
    bool completed = false,
    bool stopAudioManually = true,
  }) async {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isChallengeRunning = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        }
      });

      if (stopAudioManually) {
        // 수동 오디오 정지가 필요한 경우 (로컬 파일)
        if (_selectedSong.youtubeVideoId != null) {
          await _youtubeController?.pauseVideo(); // 최신 API
        } else {
          _audioService.pause();
        }
      }

      if (_selectedSong.filePath != null) _audioService.stopBpmTicker();

      if (completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업 완료! 오늘도 수고 많으셨습니다! 🎉'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _updateTimerText();
    }
  }

  void _setupAudioServiceCallbacks() {
    _audioService.onPlayingStateChanged = (playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    };

    _audioService.onDurationChanged = (duration) {
      if (!mounted) return;
      setState(() {
        _audioDuration = duration;
        if (!_isChallengeRunning && duration != null) {
          _remainingTime = duration;
          _updateTimerText();
        }
      });
    };

    _audioService.onError = (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingSong = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오디오 로드 오류: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    };

    _audioService.onMetronomeTick = (beatOn) {
      if (!mounted) return;
      setState(() {
        _beatHighlighter = beatOn;
      });

      if (!beatOn) return;

      // BPM 깜빡임 효과를 위한 지연 처리
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _beatHighlighter = false;
          });
        }
      });
    };

    _audioService.onCompletion = () {
      if (_selectedSong.filePath != null && !_isChallengeRunning) {
        _handleLocalAudioCompletion();
      }
    };
  }

  void _handleLocalAudioCompletion() {
    if (!mounted) return;

    switch (_playMode) {
      case PlayMode.normal:
        break;
      case PlayMode.repeat:
        _audioService.seek(Duration.zero);
        _audioService.play();
        break;
      case PlayMode.allSongs:
      case PlayMode.shuffle:
        int nextIndex = _currentSongIndex;
        if (_playMode == PlayMode.allSongs) {
          nextIndex = (_currentSongIndex + 1) % _filteredSongList.length;
        } else if (_filteredSongList.length > 1) {
          do {
            nextIndex = _random.nextInt(_filteredSongList.length);
          } while (nextIndex == _currentSongIndex &&
              _filteredSongList.length > 1);
        }
        _currentSongIndex = nextIndex;
        _onSongChanged(_filteredSongList[_currentSongIndex]);
        break;
    }
  }

  void _initAudioService() async {
    if (_selectedSong.filePath == null || _selectedSong.filePath!.isEmpty) {
      setState(() {
        _isLoadingSong = false;
      });
      return;
    }

    setState(() {
      _isLoadingSong = true;
    });

    try {
      await _audioService.loadSong(_selectedSong, context);
      if (mounted) {
        _updateTimerText();
        setState(() {
          _isLoadingSong = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSong = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오디오 로드 오류: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _initAudioService(),
            ),
          ),
        );
      }
    }
  }

  void _restartBpmTimer() {
    if (_selectedSong.filePath == null) return;
    final bpm = _currentManualBpm;
    _audioService.startBpmTicker(bpm);
    _audioService.setMetronomeSoundEnabled(_isMetronomeSoundEnabled);
  }

  void _updateTimerText() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;

    setState(() {
      _timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    });
  }

  void _changeBpmToPreset(int bpm) {
    if (_isLoadingSong) return;
    double newSpeed;
    int originalBpm = _selectedSong.bpm;

    // 원래 노래 BPM에 상대적으로 계산
    if (bpm == slowBpm) {
      newSpeed = slowSpeed; // 0.5
      _currentManualBpm = (originalBpm * 0.5).round();
    } else if (bpm == normalBpm) {
      newSpeed = normalSpeed; // 1.0
      _currentManualBpm = originalBpm;
    } else if (bpm == fastBpm) {
      newSpeed = fastSpeed; // 1.5
      _currentManualBpm = (originalBpm * 1.5).round();
    } else {
      newSpeed = normalSpeed;
      _currentManualBpm = originalBpm;
    }

    setState(() {
      _currentPlaybackSpeed = newSpeed;
      _bpmChangedByTap = false;
    });

    if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying) {
      _youtubeController!.setPlaybackRate(newSpeed);
      _restartBpmTimer(); // 시각적 BPM은 계속 현재 BPM 기준으로
    } else if (!_isYoutubeMode &&
        _audioService.isPlaying &&
        !_isChallengeRunning) {
      _audioService.setSpeed(newSpeed);
      _restartBpmTimer();
    }
  }

  void _changeBpm(int delta) {
    if (_isLoadingSong) return;
    int newBpm = (_currentManualBpm + delta).clamp(20, 240);
    // BPM 변경 시 재생 속도는 직접적으로 바꾸지 않고, _changeBpmToPreset을 통해서만 변경되도록 함.
    // 또는, 현재 재생 속도에 비례하여 BPM 변경 시 미세 조정 로직 추가 가능 (여기서는 생략)

    setState(() {
      _currentManualBpm = newBpm;
      _bpmChangedByTap = false;
    });

    if (_isYoutubeMode && _youtubeController != null && _isYoutubePlaying) {
      // 유튜브 모드에서 BPM 직접 변경 시에는 시각적 티커만 업데이트 (재생속도 변경 X)
      _restartBpmTimer();
    } else if (!_isYoutubeMode &&
        _audioService.isPlaying &&
        !_isChallengeRunning) {
      _restartBpmTimer();
    }
  }

  void _startBpmAdjustTimer() {
    _bpmAdjustTimer?.cancel();
    _bpmAdjustTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      // 비어있음, UI 이벤트에서 호출됨
    });
  }

  void _handleTapForBpm() {
    if (_isLoadingSong) return;

    final now = DateTime.now();

    if (_tapTimestamps.isEmpty ||
        now.difference(_tapTimestamps.last) > _tapTempoTimeout) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    _tapTempoResetTimer?.cancel();
    _tapTempoResetTimer = Timer(_tapTempoTimeout, () {
      if (mounted) {
        setState(() {
          _bpmChangedByTap = false;
        });
      }
    });

    if (_tapTimestamps.length >= _minTapsForBpm) {
      final intervals = <int>[];

      for (int i = 1; i < _tapTimestamps.length; i++) {
        intervals.add(
          _tapTimestamps[i].difference(_tapTimestamps[i - 1]).inMilliseconds,
        );
      }

      if (intervals.isNotEmpty) {
        final avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        final calculatedBpm = (60000 / avgInterval).round();

        setState(() {
          _currentManualBpm = calculatedBpm.clamp(20, 240);
          _bpmChangedByTap = true;
        });

        if (_selectedSong.filePath != null &&
            _isPlaying &&
            !_isChallengeRunning) {
          _restartBpmTimer();
        }
      }
    }
  }

  void _onSongChanged(Song song) async {
    if (_isChallengeRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('챌린지 진행 중에는 노래를 변경할 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final wasPlaying = _isPlaying;

    // 기존 재생 중지
    if (_selectedSong.youtubeVideoId != null) {
      await _youtubeController?.pauseVideo();
    } else if (_selectedSong.filePath != null) {
      _audioService.stop();
      _audioService.stopBpmTicker();
    }

    setState(() {
      _selectedSong = song;
      _isPlaying = false;
      _progressPercent = 0.0;
      _audioDuration = null;
      _remainingTime = Duration.zero;
      _currentManualBpm = song.bpm > 0 ? song.bpm : normalBpm;
      _isLoadingSong = true;
    });

    if (song.youtubeVideoId != null) {
      _initializeYoutubePlayer();

      // 이전에 재생 중이었으면 자동 재생
      if (wasPlaying) {
        Future.delayed(const Duration(seconds: 2), () {
          _youtubeController?.playVideo();
        });
      }
    } else if (song.filePath != null) {
      await _audioService.loadSong(song, context);

      setState(() {
        _isLoadingSong = false;
      });

      // 이전에 재생 중이었으면 자동 재생
      if (wasPlaying) {
        _audioService.play();
        _restartBpmTimer();
      }
    } else {
      setState(() {
        _isLoadingSong = false;
      });
    }

    _updateTimerText();
  }

  void _showPlaylistDialog() {
    showDialog(
      context: context,
      builder:
          (context) => PlaylistDialogWidget(
            songList: _filteredSongList,
            currentSelectedSong: _selectedSong,
            onSongSelected: (song) {
              Navigator.of(context).pop();
              _onSongChanged(song);
            },
            playMode: _playMode,
            onPlayModeChanged: (mode) {
              setState(() {
                _playMode = mode;
              });
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _showMetronomeSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => MetronomeSettingsDialogWidget(
            isMetronomeSoundEnabled: _isMetronomeSoundEnabled,
            onMetronomeSoundToggled: (enabled) {
              setState(() {
                _isMetronomeSoundEnabled = enabled;
              });
              if (_selectedSong.filePath != null &&
                  _isPlaying &&
                  !_isChallengeRunning) {
                _restartBpmTimer();
              }
            },
          ),
    );
  }

  void _changePlayMode(PlayMode mode) {
    setState(() {
      _playMode = mode;
    });
  }

  Future<void> _updateYoutubeProgress() async {
    if (!_isYoutubeMode || _youtubeController == null || !_isChallengeRunning)
      return;

    final currentPositionSeconds = await _youtubeController!.currentTime;
    final currentPosition = Duration(
      milliseconds: (currentPositionSeconds * 1000).round(),
    );

    if (mounted && _youtubeDuration.inSeconds > 0) {
      setState(() {
        _remainingTime = _youtubeDuration - currentPosition;
        if (_remainingTime.isNegative) _remainingTime = Duration.zero;
        _updateTimerText();
        // _progressPercent는 _updateProgress에서 공통으로 계산됨
      });
    }
  }

  Future<void> _updateProgress() async {
    if (!mounted) return;
    double newProgress = 0.0;

    if (_isChallengeRunning) {
      Duration totalDurationForChallenge;
      Duration elapsedTimeForChallenge;

      if (_isYoutubeMode) {
        totalDurationForChallenge = _youtubeDuration;
      } else {
        if (_audioService.duration != null &&
            _audioService.duration!.inSeconds > 0 &&
            _currentPlaybackSpeed > 0) {
          totalDurationForChallenge = Duration(
            seconds:
                (_audioService.duration!.inSeconds / _currentPlaybackSpeed)
                    .round(),
          );
        } else {
          totalDurationForChallenge = _remainingTime; // fallback
        }
      }

      if (totalDurationForChallenge.inSeconds > 0) {
        elapsedTimeForChallenge = totalDurationForChallenge - _remainingTime;
        newProgress =
            elapsedTimeForChallenge.inSeconds /
            totalDurationForChallenge.inSeconds;
      } else if (_remainingTime.inSeconds == 0) {
        newProgress = 1.0; // 전체 시간이 0이고 남은 시간도 0이면 완료로 간주
      }
    } else {
      // 챌린지 실행 중이 아닐 때 (일반 재생 시)
      Duration? currentAudioDuration;
      Duration currentPosition = Duration.zero;

      if (_isYoutubeMode) {
        currentAudioDuration = _youtubeDuration;
        if (_youtubeController != null && currentAudioDuration.inSeconds > 0) {
          try {
            final currentPositionSeconds =
                await _youtubeController!.currentTime;
            currentPosition = Duration(
              milliseconds: (currentPositionSeconds * 1000).round(),
            );
          } catch (e) {
            // currentTime 호출 중 오류 발생 시 (예: 플레이어 준비 안됨) 위치를 0으로 간주
            currentPosition = Duration.zero;
          }
        }
      } else {
        currentAudioDuration = _audioService.duration;
        if (_audioService.position != null) {
          currentPosition = _audioService.position!;
        }
      }

      if (currentAudioDuration != null && currentAudioDuration.inSeconds > 0) {
        newProgress =
            currentPosition.inSeconds / currentAudioDuration.inSeconds;
      }
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    if (newProgress.isNaN) newProgress = 0.0;

    if (mounted) {
      setState(() {
        _progressPercent = newProgress;
      });
    }
  }
}

// 상단 앱바 위젯
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onPlaylistPressed;
  final VoidCallback onMetronomeSettingsPressed;

  const AppBarWidget({
    Key? key,
    required this.title,
    required this.onPlaylistPressed,
    required this.onMetronomeSettingsPressed,
  }) : super(key: key);

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
        ShadButton.ghost(
          icon: Icon(
            Icons.queue_music,
            color: theme.colorScheme.primaryForeground,
          ),
          onPressed: onPlaylistPressed,
        ),
        ShadButton.ghost(
          icon: Icon(
            Icons.music_note_outlined,
            color: theme.colorScheme.primaryForeground,
          ),
          onPressed: onMetronomeSettingsPressed,
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

// 유튜브 플레이어 위젯
class YouTubePlayerWidget extends StatelessWidget {
  final YoutubePlayerController controller;
  final String timerText;
  final double progressPercent;
  final bool isChallengeRunning;
  final VoidCallback onChallengeButtonPressed;
  final Function(PlayerState state, Duration position, Duration duration)
  onPlayerStateChanged;

  const YouTubePlayerWidget({
    Key? key,
    required this.controller,
    required this.timerText,
    required this.progressPercent,
    required this.isChallengeRunning,
    required this.onChallengeButtonPressed,
    required this.onPlayerStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Expanded(
          child: YoutubePlayerScaffold(
            controller: controller,
            aspectRatio: 16 / 9,
            builder: (context, player) => player,
          ),
        ),
        const SizedBox(height: 16),
        Text(timerText, style: theme.textTheme.h1),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: progressPercent, minHeight: 10),
        const SizedBox(height: 20),
        ShadButton(
          width: double.infinity,
          onPressed: onChallengeButtonPressed,
          child: Text(isChallengeRunning ? '챌린지 중단' : '챌린지 시작'),
        ),
        const SizedBox(height: 16),
        // 유튜브 컨트롤 버튼 추가
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShadButton.outline(
              onPressed: () => controller.seekTo(seconds: 0),
              icon: const Icon(Icons.restart_alt),
              child: const Text('처음으로'),
            ),
            const SizedBox(width: 8),
            YoutubeValueBuilder(
              controller: controller,
              buildWhen: (previous, current) {
                return previous.playerState != current.playerState;
              },
              builder: (context, value) {
                final isPlaying = value.playerState == PlayerState.playing;
                return ShadButton.outline(
                  onPressed:
                      () =>
                          isPlaying
                              ? controller.pauseVideo()
                              : controller.playVideo(),
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  child: Text(isPlaying ? '일시정지' : '재생'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// 위젯에서 사용할 재생목록 다이얼로그
class PlaylistDialogWidget extends StatelessWidget {
  final List<Song> songList;
  final Song currentSelectedSong;
  final Function(Song) onSongSelected;
  final PlayMode playMode;
  final Function(PlayMode) onPlayModeChanged;

  const PlaylistDialogWidget({
    Key? key,
    required this.songList,
    required this.currentSelectedSong,
    required this.onSongSelected,
    required this.playMode,
    required this.onPlayModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('재생 목록'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<PlayMode>(
              value: playMode,
              onChanged: (value) {
                if (value != null) {
                  onPlayModeChanged(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: PlayMode.normal,
                  child: Text('기본 재생 (한 곡 재생 후 정지)'),
                ),
                DropdownMenuItem(
                  value: PlayMode.repeat,
                  child: Text('한 곡 반복 재생'),
                ),
                DropdownMenuItem(
                  value: PlayMode.allSongs,
                  child: Text('전체 목록 순차 재생'),
                ),
                DropdownMenuItem(value: PlayMode.shuffle, child: Text('랜덤 재생')),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: songList.length,
                itemBuilder: (context, index) {
                  final song = songList[index];
                  return ListTile(
                    title: Text(song.title),
                    subtitle: Text(
                      song.youtubeVideoId != null ? 'YouTube' : 'Assets',
                    ),
                    selected: song.title == currentSelectedSong.title,
                    onTap: () => onSongSelected(song),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

// 메트로놈 설정 다이얼로그
class MetronomeSettingsDialogWidget extends StatelessWidget {
  final bool isMetronomeSoundEnabled;
  final Function(bool) onMetronomeSoundToggled;

  const MetronomeSettingsDialogWidget({
    Key? key,
    required this.isMetronomeSoundEnabled,
    required this.onMetronomeSoundToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메트로놈 설정'),
      content: SwitchListTile(
        title: const Text('메트로놈 소리'),
        subtitle: const Text('BPM 표시할 때 소리 출력'),
        value: isMetronomeSoundEnabled,
        onChanged: onMetronomeSoundToggled,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
