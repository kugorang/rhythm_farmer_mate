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
    if (_selectedSong.youtubeVideoId != null) {
      _initializeYoutubePlayer();
      _isLoadingSong = false;
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

    // 기존 컨트롤러가 있다면 해제
    _youtubeController?.close();

    // 새 컨트롤러 생성 (최신 API 패턴 사용)
    _youtubeController = YoutubePlayerController();

    // 비디오 로드
    _youtubeController!.loadVideoById(videoId: _selectedSong.youtubeVideoId!);

    // 일정 시간 후에 상태 확인
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isPlaying = false;
        _audioDuration = const Duration(minutes: 5); // 예상 시간

        if (!_isChallengeRunning) {
          _remainingTime = _audioDuration!;
          _updateTimerText();
          _progressPercent = 0.0;
          _updateProgress();
        }

        _isLoadingSong = false;
      });
    });
  }

  // YouTube 비디오 재생 (새 API)
  Future<void> _startYoutubeVideo() async {
    if (_youtubeController == null) return;

    await _youtubeController!.playVideo();

    if (mounted) {
      setState(() {
        _isPlaying = true;
      });
    }
  }

  // YouTube 비디오 일시정지 (새 API)
  Future<void> _pauseYoutubeVideo() async {
    if (_youtubeController == null) return;

    await _youtubeController!.pauseVideo();

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  // YouTube 비디오 정지 (새 API)
  Future<void> _stopYoutubeVideo() async {
    if (_youtubeController == null) return;

    await _youtubeController!.stopVideo();

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  // 재생 상태 토글 수정
  Future<void> _togglePlayback() async {
    if (_selectedSong.youtubeVideoId != null) {
      if (_isPlaying) {
        await _pauseYoutubeVideo();
      } else {
        await _startYoutubeVideo();
      }
    } else {
      if (_isPlaying) {
        _audioService.pause();
      } else {
        _audioService.play();
      }
    }
  }

  void _updateProgress() {
    if (!mounted) return;
    double newProgress = 0.0;
    Duration? currentAudioDuration =
        _selectedSong.youtubeVideoId != null
            ? _youtubeDuration
            : _audioService.duration;

    if (_isChallengeRunning) {
      if (_selectedSong.youtubeVideoId != null && _youtubeController != null) {
        // 타이머 기반으로 진행도를 계산
        final totalTimeInSeconds = _youtubeDuration.inSeconds;
        final elapsedTimeInSeconds =
            totalTimeInSeconds - _remainingTime.inSeconds;

        if (totalTimeInSeconds > 0) {
          newProgress = elapsedTimeInSeconds / totalTimeInSeconds;
        }
      } else if (_selectedSong.filePath != null &&
          currentAudioDuration != null &&
          currentAudioDuration.inSeconds > 0 &&
          _currentPlaybackSpeed > 0) {
        final totalDurationAdjustedInSeconds =
            currentAudioDuration.inSeconds / _currentPlaybackSpeed;
        if (totalDurationAdjustedInSeconds > 0) {
          final double elapsedTimeInSeconds =
              totalDurationAdjustedInSeconds -
              _remainingTime.inSeconds.toDouble();
          newProgress = (elapsedTimeInSeconds / totalDurationAdjustedInSeconds);
        }
      } else {
        newProgress = _remainingTime.inSeconds == 0 ? 1.0 : 0.0;
      }
      // 값 범위 보정 및 정밀도 처리
      newProgress = newProgress.clamp(0.0, 1.0);
      if (newProgress < 0.000001) newProgress = 0.0;
      if (newProgress > 0.999999) newProgress = 1.0;
    } else if (!_isChallengeRunning && _progressPercent != 0) {
      newProgress = _progressPercent;
    }

    setState(() {
      _progressPercent = newProgress;
    });
  }

  // 비디오 플레이어 값이 준비되었는지 확인
  bool _isYoutubePlayerReady() {
    return _youtubeController != null;
  }

  Future<void> _startChallenge() async {
    if (_isChallengeRunning) return;
    Duration? currentChallengeDuration;

    if (_selectedSong.youtubeVideoId != null) {
      if (_youtubeController == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('YouTube 플레이어 준비 중...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      currentChallengeDuration = _youtubeDuration;
      if (currentChallengeDuration == Duration.zero) {
        currentChallengeDuration = const Duration(minutes: 5); // 기본값
      }

      // 최신 API로 재생
      await _youtubeController!.playVideo();
    } else {
      // 로컬 오디오
      if (_audioService.duration == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('음악을 불러오는 중입니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      currentChallengeDuration = Duration(
        seconds:
            (_audioService.duration!.inSeconds / _currentPlaybackSpeed).round(),
      );
      _audioService.setSpeed(_currentPlaybackSpeed);
      _audioService.play();
    }

    _remainingTime = currentChallengeDuration;
    _updateTimerText();

    setState(() {
      _isChallengeRunning = true;
      _beatHighlighter = false; // BPM 시각화 초기화
      _progressPercent = 0.0;
    });
    _updateProgress();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.inSeconds <= 0) {
        _stopChallenge(
          completed: true,
          stopAudioManually: _selectedSong.filePath != null,
        );
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
        _updateTimerText();
        _updateProgress(); // 진행도 업데이트는 타이머 기반으로 계속
      }
    });

    if (_selectedSong.filePath != null) _restartBpmTimer();
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
    if (_selectedSong.filePath == null || _selectedSong.filePath!.isEmpty)
      return;

    setState(() {
      _isLoadingSong = true;
    });

    try {
      await _audioService.loadSong(_selectedSong, context);
      _updateTimerText();
      setState(() {
        _isLoadingSong = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSong = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오디오 로드 오류: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
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
    setState(() {
      _currentManualBpm = bpm;
      _bpmChangedByTap = false;
    });

    if (_selectedSong.filePath != null && _isPlaying && !_isChallengeRunning) {
      _restartBpmTimer();
    }
  }

  void _changeBpm(int delta) {
    if (_isLoadingSong) return;
    setState(() {
      _currentManualBpm = (_currentManualBpm + delta).clamp(20, 240);
      _bpmChangedByTap = false;
    });

    if (_selectedSong.filePath != null && _isPlaying && !_isChallengeRunning) {
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
          _startYoutubeVideo();
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

  @override
  void dispose() {
    _audioService.dispose();
    _youtubeController?.close();
    _timer?.cancel();
    _tapTempoResetTimer?.cancel();
    _bpmAdjustTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;

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
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child:
                    _selectedSong.youtubeVideoId != null &&
                            _youtubeController != null
                        ? YouTubePlayerWidget(
                          controller: _youtubeController!,
                          timerText: _timerText,
                          progressPercent: _progressPercent,
                          isChallengeRunning: _isChallengeRunning,
                          onChallengeButtonPressed: () {
                            if (_isChallengeRunning) {
                              _stopChallenge(stopAudioManually: true);
                            } else {
                              _startChallenge();
                            }
                          },
                          onPlayerStateChanged: (state, position, duration) {
                            if (!mounted) return;
                            setState(() {
                              _isYoutubePlaying = state == PlayerState.playing;
                              if (duration.inSeconds > 0) {
                                _youtubeDuration = duration;
                                if (!_isChallengeRunning) {
                                  _remainingTime = duration;
                                  _updateTimerText();
                                }
                              }
                            });

                            // YouTube 재생 종료 처리
                            if (state == PlayerState.ended &&
                                !_isChallengeRunning) {
                              _handleYouTubeVideoEnded();
                            }
                          },
                        )
                        : HomeContentWidget(
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
                          bpmIndicatorColor: _getBpmIndicatorColor(theme),
                          bpmTextColor: _getBpmTextColor(theme),
                          tapTimestamps: _tapTimestamps,
                          currentManualBpm: _currentManualBpm,
                          onChangeBpmToPreset: (bpm) => _changeBpmToPreset(bpm),
                          onChangeBpm: (delta) => _changeBpm(delta),
                          onStartBpmAdjustTimer: (_) => _startBpmAdjustTimer(),
                          onStopBpmAdjustTimer: () => _bpmAdjustTimer?.cancel(),
                          onHandleTapForBpm: _handleTapForBpm,
                          progressPercent: _progressPercent,
                          isPlaying:
                              _selectedSong.filePath != null
                                  ? _audioService.isPlaying
                                  : _isYoutubePlaying,
                          audioDuration:
                              _selectedSong.filePath != null
                                  ? _audioService.duration
                                  : _youtubeDuration,
                          currentPlaybackSpeed: _currentPlaybackSpeed,
                          onPlayPause: _handlePlayPause,
                          onStop: _handleStop,
                          onChallengeButtonPressed: () {
                            if (_isChallengeRunning) {
                              _stopChallenge(stopAudioManually: true);
                            } else {
                              _startChallenge();
                            }
                          },
                          slowBpm: slowBpm,
                          normalBpm: normalBpm,
                          fastBpm: fastBpm,
                          playMode: _playMode,
                          onPlayModeChanged: _changePlayMode,
                        ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getBpmIndicatorColor(ShadThemeData theme) {
    return _isLoadingSong
        ? theme.colorScheme.muted
        : (_beatHighlighter
            ? theme.colorScheme.primary.withOpacity(0.35)
            : (_bpmChangedByTap
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.card));
  }

  Color _getBpmTextColor(ShadThemeData theme) {
    return _isLoadingSong
        ? theme.colorScheme.mutedForeground
        : (_bpmChangedByTap
            ? theme.colorScheme.primary
            : (_beatHighlighter
                ? theme.colorScheme.primary
                : theme.colorScheme.foreground));
  }

  Future<void> _handlePlayPause() async {
    if (_isLoadingSong || _isChallengeRunning) return;

    if (_selectedSong.youtubeVideoId != null && _youtubeController != null) {
      if (_isYoutubePlaying) {
        await _youtubeController!.pauseVideo();
      } else {
        await _youtubeController!.playVideo();
      }
    } else if (_selectedSong.filePath != null) {
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
      _audioService.setSpeed(_currentPlaybackSpeed);
      _audioService.play();
      if (!_isChallengeRunning) _restartBpmTimer();
    }
  }

  void _handleStopLocal() {
    if (_isLoadingSong || _isChallengeRunning) return;

    _audioService.stop();
    _audioService.stopBpmTicker();
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
            builder: (context, player) {
              return YoutubeValueBuilder(
                controller: controller,
                builder: (context, value) {
                  // 현재 상태와 영상 정보를 부모에게 전달
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onPlayerStateChanged(
                      value.playerState,
                      Duration.zero,
                      value.metaData.duration,
                    );
                  });

                  return Column(children: [player]);
                },
              );
            },
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
