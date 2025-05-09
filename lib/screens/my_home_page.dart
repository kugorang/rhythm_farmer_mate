import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide BorderStyle;
import 'package:just_audio/just_audio.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
  final SongCategoryType? selectedCategoryType; // 선택된 카테고리 타입 추가

  const MyHomePage({super.key, this.selectedCategoryType}); // 생성자 수정

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioService _audioService; // AudioPlayer 대신 AudioService 사용
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

  @override
  void initState() {
    super.initState();

    // 선택된 카테고리에 따라 곡 목록 필터링
    if (widget.selectedCategoryType != null) {
      _filteredSongList =
          _fullSongList
              .where((song) => song.categoryType == widget.selectedCategoryType)
              .toList();
    } else {
      // 카테고리가 선택되지 않은 경우 (예: 직접 MyHomePage로 접근 시) 모든 곡을 보여주거나 기본 카테고리 설정
      _filteredSongList = List.from(_fullSongList);
    }

    _currentSongIndex = 0;
    _selectedSong =
        _filteredSongList.isNotEmpty
            ? _filteredSongList[_currentSongIndex]
            : const Song(
              filePath: '',
              title: '노래 없음',
              bpm: 0,
              categoryType: SongCategoryType.modernLaborSong, // 기본값
            );
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : normalBpm;

    // AudioService 초기화 및 콜백 설정
    _audioService = AudioService();
    _setupAudioServiceCallbacks();

    if (_selectedSong.filePath.isNotEmpty) {
      _initAudioService();
    } else {
      if (mounted) setState(() => _isLoadingSong = false);
    }
    _updateTimerText();
  }

  void _setupAudioServiceCallbacks() {
    // 콜백 설정
    _audioService.onPlayingStateChanged = (isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
      if (!_isChallengeRunning) {
        if (isPlaying) {
          _restartBpmTimer();
        } else {
          if (mounted) setState(() => _beatHighlighter = false);
        }
      }
    };

    _audioService.onDurationChanged = (duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
          if (!_isChallengeRunning && _audioDuration != null) {
            _remainingTime = Duration(
              seconds:
                  (_audioDuration!.inSeconds /
                          (_currentPlaybackSpeed > 0
                              ? _currentPlaybackSpeed
                              : 1.0))
                      .round(),
            );
            _updateTimerText();
            _progressPercent = 0.0;
            _updateProgress();
          }
        });
      }
    };

    _audioService.onError = (errorMessage) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(title: const Text('오류'), description: Text(errorMessage)),
        );
      }
    };

    _audioService.onMetronomeTick = (beatOn) {
      if (mounted) {
        setState(() {
          _beatHighlighter = beatOn;
        });
      }
    };

    _audioService.onCompletion = () {
      if (!_isChallengeRunning) {
        _handlePlaybackCompletion();
      }
    };
  }

  @override
  void dispose() {
    _audioService.dispose();
    _timer?.cancel();
    _tapTempoResetTimer?.cancel();
    _bpmAdjustTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAudioService() async {
    if (mounted) {
      setState(() {
        _isLoadingSong = true;
      });
    }

    try {
      // 현재 선택된 곡 로드
      await _audioService.loadSong(_selectedSong, context);

      // 약간의 딜레이 후 duration을 다시 확인 (웹 플랫폼에서 초기 로드 시 duration이 null일 수 있음)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        if (_audioService.duration != null) {
          _audioDuration = _audioService.duration;
        }

        // 챌린지 중이 아니고, duration이 정상적으로 로드되었을 때 타이머와 진행도 업데이트
        if (!_isChallengeRunning && _audioDuration != null) {
          _remainingTime = Duration(
            seconds:
                (_audioDuration!.inSeconds /
                        (_currentPlaybackSpeed > 0
                            ? _currentPlaybackSpeed
                            : 1.0))
                    .round(),
          );
          _updateTimerText();
          _progressPercent = 0.0;
          _updateProgress();
        }

        setState(() {
          _isLoadingSong = false;
        });
      });

      await _audioService.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
    } catch (e) {
      print("Error in _initAudioService: $e");
      if (mounted) {
        setState(() => _isLoadingSong = false);
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text('음악 파일을 불러오는 데 실패했습니다.'),
          ),
        );
      }
    }
  }

  void _updateTimerText() {
    final minutes = _remainingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remainingTime.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (mounted) {
      setState(() {
        _timerText = '$minutes:$seconds';
      });
    }
  }

  void _updateProgress() {
    if (!mounted) return;
    double newProgress = 0.0;

    if (_isChallengeRunning &&
        _audioDuration != null &&
        _audioDuration!.inSeconds > 0 &&
        _currentPlaybackSpeed > 0) {
      // 챌린지 실행 중 - 진행도 계산
      final totalDurationAdjustedInSeconds =
          _audioDuration!.inSeconds / _currentPlaybackSpeed;

      if (totalDurationAdjustedInSeconds > 0) {
        final double elapsedTimeInSeconds =
            totalDurationAdjustedInSeconds -
            _remainingTime.inSeconds.toDouble();
        newProgress = (elapsedTimeInSeconds / totalDurationAdjustedInSeconds);

        // 값 범위 보정
        newProgress = newProgress.clamp(0.0, 1.0);

        // 아주 작은 값 처리 (정밀도 이슈)
        if (newProgress < 0.000001) newProgress = 0.0;
        if (newProgress > 0.999999) newProgress = 1.0;
      } else {
        newProgress = _remainingTime.inSeconds == 0 ? 1.0 : 0.0;
      }
    } else if (!_isChallengeRunning && _progressPercent != 0) {
      // 챌린지 실행 중이 아니고 이미 진행된 상태 - 현재 진행도 유지
      newProgress = _progressPercent;
    }

    setState(() {
      _progressPercent = newProgress;
    });
  }

  void _startChallenge() {
    // 이미 챌린지 실행 중이거나 오디오가 로드되지 않았으면 무시
    if (_isChallengeRunning) return;
    if (_audioDuration == null) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('알림'),
            description: const Text('음악을 불러오는 중입니다.'),
          ),
        );
      }
      return;
    }

    // 챌린지 시작 준비
    _remainingTime = Duration(
      seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
    );
    _updateTimerText();

    setState(() {
      _isChallengeRunning = true;
      _beatHighlighter = false;
      _progressPercent = 0.0;
    });

    _updateProgress();

    // 재생 시작 및 타이머 설정
    _audioService.setSpeed(_currentPlaybackSpeed);
    _audioService.play();

    // 1초마다 타이머 갱신
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingTime.inSeconds <= 0) {
        _stopChallenge(completed: true);
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
        _updateTimerText();
        _updateProgress();
      }
    });

    // BPM 타이머 시작
    _restartBpmTimer();
  }

  void _stopChallenge({bool completed = false}) {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _isChallengeRunning = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        }
      });

      _updateProgress();
      _audioService.pause();

      // 메트로놈 정지
      _audioService.stopBpmTicker();

      if (completed) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('작업 완료!'),
            description: const Text('오늘도 수고 많으셨습니다! 🎉'),
          ),
        );
      }

      _updateTimerText();
    }
  }

  void _restartBpmTimer() {
    if (!mounted) return;
    if (_isChallengeRunning || _isPlaying) {
      final songBpm =
          _currentManualBpm > 0 ? _currentManualBpm : normalBpm; // 기본 BPM 사용

      // AudioService의 startBpmTicker 호출
      _audioService.startBpmTicker(songBpm);
      _audioService.setMetronomeSoundEnabled(_isMetronomeSoundEnabled);
    } else {
      _audioService.stopBpmTicker();
      if (mounted) setState(() => _beatHighlighter = false);
    }
  }

  void _updateBpmAndPlaybackSpeed(int newBpm) {
    if (!mounted) return;

    final clampedBpm = newBpm.clamp(30, 240);
    final songOriginalBpm =
        _selectedSong.bpm > 0 ? _selectedSong.bpm : normalBpm;
    final newPlaybackSpeed =
        songOriginalBpm > 0
            ? (clampedBpm / songOriginalBpm).clamp(0.5, 2.0)
            : 1.0;

    setState(() {
      _currentManualBpm = clampedBpm;
      _currentPlaybackSpeed = newPlaybackSpeed;
    });

    // 오디오 재생 속도 변경
    _audioService.setSpeed(_currentPlaybackSpeed);

    // 재생 중이면 BPM 타이머 재시작
    if ((_isPlaying && !_isChallengeRunning) || _isChallengeRunning) {
      _restartBpmTimer();
    }

    // 챌린지 중이 아니면 타이머 시간 업데이트
    if (!_isChallengeRunning && _audioDuration != null) {
      setState(() {
        _remainingTime = Duration(
          seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
        );
        _progressPercent = 0.0;
      });

      _updateTimerText();
      _updateProgress();
    }
  }

  void _changeBpmToPreset(int presetBpm) {
    // 챌린지 중에는 변경 금지
    if (_isChallengeRunning) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      }
      return;
    }

    _updateBpmAndPlaybackSpeed(presetBpm);
  }

  void _changeBpm(int delta) {
    // 챌린지 중에는 변경 금지
    if (_isChallengeRunning) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      }
      return;
    }

    _updateBpmAndPlaybackSpeed(_currentManualBpm + delta);
  }

  void _handleTapForBpm() {
    // 챌린지 중에는 변경 금지
    if (_isChallengeRunning) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      }
      return;
    }

    // 현재 시간 기록
    final now = DateTime.now();

    // 탭 시간 저장 (최대 _minTapsForBpm 개만 유지)
    if (_tapTimestamps.length >= _minTapsForBpm) {
      _tapTimestamps.removeAt(0);
    }

    setState(() {
      _tapTimestamps.add(now);
    });

    // 기존 타이머 취소
    _tapTempoResetTimer?.cancel();

    // 충분한 탭이 기록되었으면 BPM 계산
    if (_tapTimestamps.length >= _minTapsForBpm) {
      final intervalMs =
          _tapTimestamps[1].difference(_tapTimestamps[0]).inMilliseconds;

      // 적절한 간격 범위인지 확인 (30~240 BPM)
      if (intervalMs > 250 && intervalMs < 2000) {
        final newBpm = (60000 / intervalMs).round();
        _updateBpmAndPlaybackSpeed(newBpm);

        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: Text('현재 박자가 $_currentManualBpm (으)로 설정되었어요.'),
            ),
          );

          // 탭 하이라이트 효과
          setState(() {
            _bpmChangedByTap = true;
          });

          // 하이라이트 효과 해제 타이머
          Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _bpmChangedByTap = false;
              });
            }
          });
        }
      } else {
        // 유효하지 않은 BPM 범위
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: const Text('엇, 박자가 너무 빠르거나 느리네요. 다시 탭해주세요.'),
            ),
          );
        }
      }
    } else {
      // 시간 초과 후 탭 기록 초기화 타이머
      _tapTempoResetTimer = Timer(_tapTempoTimeout, () {
        if (_tapTimestamps.isNotEmpty &&
            _tapTimestamps.length < _minTapsForBpm &&
            mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: Text('박자 계산에 필요한 탭 횟수가 부족해요. (최소 $_minTapsForBpm번)'),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _tapTimestamps.clear();
          });
        }
      });
    }
  }

  void _handlePlaybackCompletion() async {
    if (!mounted) return;

    switch (_playMode) {
      case PlayMode.normal:
        // 일반 재생 모드 - 한 곡 재생 후 정지
        setState(() {
          _isPlaying = false;
          _progressPercent = 1.0; // 재생 완료 시 진행도 100%로 설정
        });
        _updateProgress();
        break;

      case PlayMode.repeat:
        // 반복 재생 모드 - 현재 곡 다시 재생
        _audioService.seek(Duration.zero);
        _audioService.play();
        break;

      case PlayMode.allSongs:
        _currentSongIndex = (_currentSongIndex + 1) % _filteredSongList.length;
        await _onSongChanged(_filteredSongList[_currentSongIndex]);
        if (mounted && _filteredSongList.isNotEmpty) {
          _audioService.play();
        }
        break;

      case PlayMode.shuffle:
        if (_filteredSongList.length > 1) {
          int nextIndex;
          do {
            nextIndex = _random.nextInt(_filteredSongList.length);
          } while (nextIndex == _currentSongIndex);
          _currentSongIndex = nextIndex;
        } else {
          _currentSongIndex = 0;
        }
        await _onSongChanged(_filteredSongList[_currentSongIndex]);
        if (mounted && _filteredSongList.isNotEmpty) {
          _audioService.play();
        }
        break;
    }
  }

  Future<void> _onSongChanged(Song newSong) async {
    // 챌린지 중에는 변경 불가
    if (_isChallengeRunning) {
      if (mounted) {
        ShadToaster.of(
          context,
        ).show(ShadToast(description: const Text('지금은 작업 중이라 노래를 바꿀 수 없어요.')));
      }
      return;
    }

    // 진행 중인 챌린지가 있으면 중지
    if (_isChallengeRunning) _stopChallenge();

    // 로딩 상태로 변경
    if (mounted) {
      setState(() {
        _isLoadingSong = true;
        _isChallengeRunning = false;
        _progressPercent = 0.0;
      });
      _updateProgress();
    }

    // 현재 곡의 인덱스 찾기
    final int newIndex = _filteredSongList.indexWhere(
      (song) => song.filePath == newSong.filePath,
    );

    if (newIndex != -1) {
      _currentSongIndex = newIndex;
      print("곡 변경: $_currentSongIndex, ${newSong.title}");
    } else {
      print("곡 인덱스를 찾을 수 없음: ${newSong.title}");
      // 만약 filteredSongList에 없다면, _fullSongList에서 찾아보고, 카테고리를 변경해야 할 수도 있음
      // 여기서는 일단 현재 카테고리 내에서만 찾는다고 가정
    }

    // 현재 재생 중인 오디오 중지
    await _audioService.stop();
    _audioService.stopBpmTicker();

    // 새 곡 정보로 상태 변경
    setState(() {
      _selectedSong = newSong;
      _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : normalBpm;
      _currentPlaybackSpeed = 1.0;
      _isPlaying = false;
      _remainingTime = Duration.zero;
      _timerText = '00:00';
      _audioDuration = null;
      _beatHighlighter = false;
    });

    // 새 곡 로드
    await _initAudioService();
  }

  void _changePlayMode(PlayMode newMode) {
    setState(() {
      _playMode = newMode;
    });

    // 모드 변경 메시지 설정
    final modeMessages = {
      PlayMode.normal: '일반 재생 모드로 변경되었습니다.',
      PlayMode.repeat: '한 곡 반복 모드로 변경되었습니다.',
      PlayMode.allSongs: '전체 곡 순차 재생 모드로 변경되었습니다.',
      PlayMode.shuffle: '랜덤 재생 모드로 변경되었습니다.',
    };

    if (mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: Text(modeMessages[newMode]!)));
    }
  }

  void _startBpmAdjustTimer(int delta) {
    _bpmAdjustTimer?.cancel();
    _changeBpm(delta); // 첫 번째 변경 즉시 반영

    // 버튼 계속 누르고 있을 때 일정 간격으로 BPM 조정
    _bpmAdjustTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (_) => _changeBpm(delta),
    );
  }

  void _stopBpmAdjustTimer() {
    _bpmAdjustTimer?.cancel();
  }

  // 음악 제어 로직을 위한 콜백 함수들
  void _handlePlayPause() {
    if (_isLoadingSong || _audioDuration == null || _isChallengeRunning) {
      return;
    }

    if (_isPlaying) {
      _audioService.pause();
    } else {
      _audioService.setSpeed(_currentPlaybackSpeed);
      _audioService.play();

      // 챌린지 중이 아닐 때만 BPM 타이머 시작
      if (!_isChallengeRunning) {
        _restartBpmTimer();
      }
    }
  }

  void _handleStop() {
    if (_isLoadingSong || _audioDuration == null || _isChallengeRunning) {
      return;
    }

    _audioService.stop();

    // 챌린지 중이 아닐 때만 BPM 타이머 중지
    if (!_isChallengeRunning) {
      _audioService.stopBpmTicker();
    }
  }

  Future<void> _showPlaylistDialog() async {
    if (_isLoadingSong || _isChallengeRunning) return;

    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PlaylistDialogWidget(
          songList: _filteredSongList,
          selectedSong: _selectedSong,
          currentPlayMode: _playMode,
          onPlayModeChanged: _changePlayMode,
          onSongSelected: _onSongChanged,
        );
      },
    );
  }

  Future<void> _showMetronomeSettingsDialog() async {
    if (_isLoadingSong || _isChallengeRunning) return;

    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return MetronomeSettingsDialogWidget(
          initialMetronomeSoundEnabled: _isMetronomeSoundEnabled,
          onMetronomeSoundChanged: (value) {
            if (mounted) {
              setState(() {
                _isMetronomeSoundEnabled = value;
              });
              _audioService.setMetronomeSoundEnabled(value);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;

    // BPM 표시기 스타일 계산
    final bpmIndicatorScale = _beatHighlighter ? 1.1 : 1.0;
    final bpmDisplayCardColor =
        _bpmChangedByTap
            ? theme.colorScheme.primary.withOpacity(0.1)
            : (_isLoadingSong
                ? theme.colorScheme.muted
                : theme.colorScheme.card);
    final bpmIndicatorColor =
        _isLoadingSong
            ? theme.colorScheme.muted
            : (_beatHighlighter
                ? theme.colorScheme.primary.withOpacity(0.35)
                : bpmDisplayCardColor);
    final bpmTextColor =
        _isLoadingSong
            ? theme.colorScheme.mutedForeground
            : (_bpmChangedByTap
                ? theme.colorScheme.primary
                : (_beatHighlighter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.foreground));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          '리듬농부 메이트',
          style: theme.textTheme.h4.copyWith(
            color: theme.colorScheme.primaryForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 재생목록 버튼
          ShadButton.ghost(
            icon: Icon(
              Icons.queue_music,
              color: theme.colorScheme.primaryForeground,
            ),
            onPressed: _showPlaylistDialog,
          ),
          // 메트로놈 설정 버튼
          ShadButton.ghost(
            icon: Icon(
              Icons.music_note_outlined,
              color: theme.colorScheme.primaryForeground,
            ),
            onPressed: _showMetronomeSettingsDialog,
          ),
          // 테마 모드 전환 버튼
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
                  // 라이트 모드 <-> 다크 모드 <-> 시스템 모드 순환
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 화면 크기에 따른 패딩 조정
              final horizontalPadding =
                  constraints.maxWidth < 600 ? 16.0 : 24.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: HomeContentWidget(
                  isLoadingSong: _isLoadingSong,
                  isChallengeRunning: _isChallengeRunning,
                  selectedSong: _selectedSong,
                  songList: _filteredSongList,
                  onSongChanged: (Song? value) {
                    if (value != null) _onSongChanged(value);
                  },
                  timerText: _timerText,
                  defaultBorderRadius: defaultBorderRadius,
                  beatHighlighter: _beatHighlighter,
                  bpmChangedByTap: _bpmChangedByTap,
                  bpmIndicatorScale: bpmIndicatorScale,
                  bpmIndicatorColor: bpmIndicatorColor,
                  bpmTextColor: bpmTextColor,
                  tapTimestamps: _tapTimestamps,
                  currentManualBpm: _currentManualBpm,
                  onChangeBpmToPreset: _changeBpmToPreset,
                  onChangeBpm: _changeBpm,
                  onStartBpmAdjustTimer: _startBpmAdjustTimer,
                  onStopBpmAdjustTimer: () => _bpmAdjustTimer?.cancel(),
                  onHandleTapForBpm: _handleTapForBpm,
                  progressPercent: _progressPercent,
                  isPlaying: _isPlaying,
                  audioDuration: _audioDuration,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
