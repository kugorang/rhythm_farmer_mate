import 'dart:async';
import 'package:flutter/material.dart' hide BorderStyle;
import 'package:just_audio/just_audio.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart'; // 상대 경로 또는 package:rhythm_farmer_mate/models/song.dart
import '../widgets/timer_display_widget.dart'; // 상대 경로
import '../widgets/bpm_control_section_widget.dart'; // 상대 경로
import '../widgets/music_control_widget.dart'; // 상대 경로
import '../widgets/progress_display_widget.dart'; // ProgressDisplayWidget import 추가
import '../widgets/challenge_control_button_widget.dart'; // ChallengeControlButtonWidget import 추가

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  late AudioPlayer _metronomePlayer;
  bool _isPlaying = false; // _audioPlayer.playing 상태 반영
  Duration? _audioDuration;
  bool _isLoadingSong = true;
  Timer? _timer; // 작업(챌린지) 타이머
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isChallengeRunning = false; // << 핵심 상태 변수: 작업(챌린지) 실행 여부
  double _progressPercent = 0.0;
  Timer? _bpmTimer;
  bool _beatHighlighter = false;

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  final List<DateTime> _tapTimestamps = [];
  Timer? _tapTempoResetTimer;
  static const int _minTapsForBpm = 2;
  static const Duration _tapTempoTimeout = Duration(seconds: 2);
  bool _bpmChangedByTap = false;
  Timer? _bpmAdjustTimer;

  final List<Song> _songList = const [
    Song(
      filePath: 'assets/audio/emart_original.mp3',
      title: '이마트 로고송',
      bpm: 100,
    ),
    Song(
      filePath: 'assets/audio/CD01-01.mp3',
      title: '논삶는소리 (강원 홍천군)',
      bpm: 69,
    ),
    Song(
      filePath: 'assets/audio/CD01-02.mp3',
      title: '논고르는소리 (제주 서귀포시)',
      bpm: 93,
    ),
    Song(
      filePath: 'assets/audio/CD01-03.mp3',
      title: '모찌는소리-"얼른 하더니 한 춤" (강원 양양군)',
      bpm: 70,
    ),
    Song(
      filePath: 'assets/audio/CD01-04.mp3',
      title: '모찌는소리-"뭉치세 제치세" (충북 진천군)',
      bpm: 76,
    ),
    Song(
      filePath: 'assets/audio/CD02-01.mp3',
      title: '논매는소리-"헤헤 곯었네" (경기 안성군)',
      bpm: 52,
    ),
    Song(
      filePath: 'assets/audio/CD02-02.mp3',
      title: '논매는소리-대허리 (경기 이천군)',
      bpm: 115,
    ),
    Song(
      filePath: 'assets/audio/CD02-03.mp3',
      title: '논매는소리-오독떼기 (강원 양양군)',
      bpm: 107,
    ),
    Song(
      filePath: 'assets/audio/CD02-04.mp3',
      title: '논매는소리-"얼카 덩어리" (충남 홍성군)',
      bpm: 62,
    ),
    Song(
      filePath: 'assets/audio/CD03-01.mp3',
      title: '논매는소리-긴소리/들래기소리 (전남 무안군)',
      bpm: 66,
    ),
    Song(
      filePath: 'assets/audio/CD03-02.mp3',
      title: '논매는소리-소오니소리 (경북 구미시)',
      bpm: 55,
    ),
    Song(
      filePath: 'assets/audio/CD03-03.mp3',
      title: '논매는소리 (경북 예천군)',
      bpm: 78,
    ),
    Song(
      filePath: 'assets/audio/CD03-04.mp3',
      title: '농사장원례소리-애롱대롱 (전남 나주군)',
      bpm: 91,
    ),
    Song(
      filePath: 'assets/audio/CD04-01.mp3',
      title: '밭가는소리 (강원 홍천군)',
      bpm: 132,
    ),
    Song(
      filePath: 'assets/audio/CD04-02.mp3',
      title: '밭일구는소리(따비질) (제주 북제주군)',
      bpm: 72,
    ),
    Song(
      filePath: 'assets/audio/CD04-03.mp3',
      title: '밭고르는소리(곰방메질) (제주 북제주군)',
      bpm: 64,
    ),
    Song(
      filePath: 'assets/audio/CD04-04.mp3',
      title: '밭밟는소리 (제주 북제주군)',
      bpm: 69,
    ),
  ];
  late Song _selectedSong;
  late int _currentManualBpm;
  double _currentPlaybackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedSong =
        _songList.isNotEmpty
            ? _songList.first
            : const Song(filePath: '', title: '노래 없음', bpm: 0);
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();
    if (_selectedSong.filePath.isNotEmpty) {
      _initAudioPlayers();
    } else {
      if (mounted) setState(() => _isLoadingSong = false);
    }
    _updateTimerText();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _metronomePlayer.dispose();
    _timer?.cancel();
    _bpmTimer?.cancel();
    _tapTempoResetTimer?.cancel();
    _bpmAdjustTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAudioPlayers() async {
    if (mounted) {
      setState(() {
        _isLoadingSong = true;
      });
    }
    try {
      await _audioPlayer.setAsset(_selectedSong.filePath);
      if (_metronomePlayer.processingState == ProcessingState.idle) {
        try {
          await _metronomePlayer.setAsset('assets/audio/tick.mp3');
        } catch (e) {
          print("Metronome tick load error: $e");
          if (mounted) {
            ShadToaster.of(context).show(
              ShadToast(
                title: const Text('오류'),
                description: const Text('메트로놈 효과음 로드 실패!'),
              ),
            );
          }
        }
      }
      _audioPlayer.durationStream.listen((duration) {
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
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          if (_audioPlayer.duration != null) {
            _audioDuration = _audioPlayer.duration;
          }
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
        }
      });
      _audioPlayer.playingStream.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
        // 챌린지 중이 아닐 때만, 음악 재생 상태에 따라 BPM 타이머(시각화) 제어
        if (!_isChallengeRunning) {
          if (playing) {
            _restartBpmTimer();
          } else {
            _bpmTimer?.cancel();
            if (mounted) setState(() => _beatHighlighter = false);
          }
        }
      });
      await _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
    } catch (e) {
      print("Error in _initAudioPlayers: $e");
      if (mounted) setState(() => _isLoadingSong = false);
      if (mounted) {
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
      final totalDurationAdjustedInSeconds =
          _audioDuration!.inSeconds / _currentPlaybackSpeed;
      if (totalDurationAdjustedInSeconds > 0) {
        final double elapsedTimeInSeconds =
            totalDurationAdjustedInSeconds -
            _remainingTime.inSeconds.toDouble();
        newProgress = (elapsedTimeInSeconds / totalDurationAdjustedInSeconds);

        if (newProgress < 0) newProgress = 0.0;
        if (newProgress > 1) newProgress = 1.0;
        if (newProgress < 0.000001) newProgress = 0.0;
        if (newProgress > 0.999999) newProgress = 1.0;
      } else {
        newProgress = _remainingTime.inSeconds == 0 ? 1.0 : 0.0;
      }
    }
    // _isChallengeRunning이 false이면 newProgress는 초기값 0.0 유지됨
    // 또는 명시적으로 설정: else { newProgress = 0.0; }
    setState(() {
      _progressPercent = newProgress;
    });
  }

  void _startChallenge() {
    if (_isChallengeRunning) return;
    if (_audioDuration == null) {
      if (mounted)
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('알림'),
            description: const Text('음악을 불러오는 중입니다.'),
          ),
        );
      return;
    }
    _remainingTime = Duration(
      seconds:
          (_audioDuration!.inSeconds /
                  (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
              .round(),
    );
    _updateTimerText();
    if (mounted) {
      setState(() {
        _progressPercent = 0.0;
      });
      // _updateProgress(); // 여기서 호출하지 않음
    }

    setState(() {
      _isChallengeRunning = true;
      _beatHighlighter = false;
    });
    _audioPlayer.setSpeed(
      _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
    );
    _audioPlayer.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.inSeconds <= 0) {
        _stopChallenge(completed: true);
      } else {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
        _updateTimerText();
        _updateProgress(); // 매초 진행도 업데이트
      }
    });
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
        } else {
          _updateProgress();
        } // 중지 시 현재 진행도 반영
      });
    }
    _audioPlayer.pause(); // 챌린지 중지/완료 시 음악도 일시정지
    _bpmTimer?.cancel(); // BPM 타이머도 중지
    if (mounted) setState(() => _beatHighlighter = false);
    if (completed && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('작업 완료!'),
          description: const Text('오늘도 수고 많으셨습니다! 🎉'),
        ),
      );
    }
    _updateTimerText(); // 남은 시간 00:00 또는 현재 시간으로 업데이트
  }

  void _restartBpmTimer() {
    _bpmTimer?.cancel();
    if (!mounted) return;
    // 챌린지 중이거나, (챌린지 중이 아니면서) 음악만 재생 중일 때 BPM 타이머(시각화) 활성화
    if (_isChallengeRunning || (_isPlaying && !_isChallengeRunning)) {
      final songBpm = _currentManualBpm > 0 ? _currentManualBpm : 60;
      final beatInterval = (60000 / songBpm).round();
      if (beatInterval <= 0) {
        if (mounted) setState(() => _beatHighlighter = false);
        return;
      }
      _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _beatHighlighter = !_beatHighlighter;
        });
        // 메트로놈 오디오 재생 로직 (계속 주석 처리)
        /* if ((_isChallengeRunning || _isPlaying) && mounted && _metronomePlayer.processingState != ProcessingState.loading) { ... } */
      });
    } else {
      if (mounted) setState(() => _beatHighlighter = false);
    }
  }

  void _updateBpmAndPlaybackSpeed(int newBpm) {
    if (!mounted) return;
    setState(() {
      _currentManualBpm = newBpm.clamp(30, 240);
      final songBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
      _currentPlaybackSpeed =
          (songBpm == 0) ? 1.0 : (_currentManualBpm / songBpm).clamp(0.5, 2.0);
      _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
      if ((_isPlaying && !_isChallengeRunning) || _isChallengeRunning)
        _restartBpmTimer();
      if (!_isChallengeRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds:
              (_audioDuration!.inSeconds /
                      (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
                  .round(),
        );
        if (mounted) {
          setState(() {
            _progressPercent = 0.0;
          }); // 진행도 0으로 설정
        }
        _updateTimerText();
        // _updateProgress(); // 이미 위에서 0으로 설정 후 UI 업데이트됨
      }
    });
  }

  void _changeBpmToPreset(int presetBpm) {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    _updateBpmAndPlaybackSpeed(presetBpm);
  }

  void _changeBpm(int delta) {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    _updateBpmAndPlaybackSpeed(_currentManualBpm + delta);
  }

  void _handleTapForBpm() {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    final now = DateTime.now();
    if (mounted) {
      if (_tapTimestamps.length >= _minTapsForBpm) _tapTimestamps.removeAt(0);
      setState(() {
        _tapTimestamps.add(now);
      });
    }
    _tapTempoResetTimer?.cancel();
    if (_tapTimestamps.length >= _minTapsForBpm) {
      final intervalMs =
          _tapTimestamps[1].difference(_tapTimestamps[0]).inMilliseconds;
      if (intervalMs > 250 && intervalMs < 2000) {
        final newBpm = (60000 / intervalMs).round();
        _updateBpmAndPlaybackSpeed(newBpm);
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: Text('현재 박자가 $_currentManualBpm (으)로 설정되었어요.'),
            ),
          );
        }
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _bpmChangedByTap = false;
            });
          }
        });
      } else {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: const Text('엇, 박자가 너무 빠르거나 느리네요. 다시 탭해주세요.'),
            ),
          );
        }
      }
    } else {
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
    if (mounted) setState(() {});
  }

  Future<void> _onSongChanged(Song newSong) async {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 노래를 바꿀 수 없어요.')));
      return;
    }
    if (_isChallengeRunning) _stopChallenge(); // 곡 변경 시 진행 중이던 챌린지 중지

    if (mounted) {
      setState(() {
        _isLoadingSong = true;
        _isChallengeRunning = false;
        _progressPercent = 0.0;
      });
    }
    setState(() {
      _selectedSong = newSong;
      _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
      _currentPlaybackSpeed = 1.0;
      _isPlaying = false;
      _remainingTime = Duration.zero;
      _timerText = '00:00';
      _audioDuration = null;
      _beatHighlighter = false;
    });
    await _audioPlayer.stop();
    _bpmTimer?.cancel();
    if (mounted) setState(() => _beatHighlighter = false);
    await _initAudioPlayers();
  }

  void _startBpmAdjustTimer(int delta) {
    _bpmAdjustTimer?.cancel();
    _changeBpm(delta); // 세부 BPM 변경 함수 호출
    _bpmAdjustTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _changeBpm(delta);
    });
  }

  void _stopBpmAdjustTimer() {
    _bpmAdjustTimer?.cancel();
  }

  // 음악 제어 로직을 위한 콜백 함수들
  void _handlePlayPause() {
    if (_isLoadingSong || _audioDuration == null) return;
    if (_isChallengeRunning) return; // 챌린지 중에는 독립 제어 불가

    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
      _audioPlayer.play();
      // _isChallengeRunning이 false일 때만 _restartBpmTimer 호출 (음악만 독립 재생 시)
      if (!_isChallengeRunning) _restartBpmTimer();
    }
    // _isPlaying 상태는 _audioPlayer.playingStream.listen 에 의해 업데이트됨
  }

  void _handleStop() {
    if (_isLoadingSong || _audioDuration == null) return;
    if (_isChallengeRunning) return; // 챌린지 중에는 독립 제어 불가

    _audioPlayer.stop();
    _audioPlayer.seek(Duration.zero); // 정지 시 처음으로
    // 음악 정지 시 BPM 타이머도 중지 (챌린지 중이 아닐 때)
    if (!_isChallengeRunning) {
      _bpmTimer?.cancel();
      if (mounted) setState(() => _beatHighlighter = false);
    }
    // _isPlaying 상태는 _audioPlayer.playingStream.listen 에 의해 업데이트됨
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;
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

    final canInteractWithSettings = !_isChallengeRunning && !_isLoadingSong;
    // final canControlMusicIndependent = !_isChallengeRunning && !_isLoadingSong && _audioDuration != null; // MusicControlWidget 내부에서 계산하도록 변경

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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_isLoadingSong)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_isChallengeRunning && !_isLoadingSong)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ShadSelect<Song>(
                          placeholder: Text(
                            '노동요를 선택하세요',
                            style: theme.textTheme.p.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          options:
                              _songList
                                  .map(
                                    (song) => ShadOption(
                                      value: song,
                                      child: Text(
                                        song.title,
                                        style: theme.textTheme.p,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          selectedOptionBuilder:
                              (context, value) =>
                                  Text(value.title, style: theme.textTheme.p),
                          onChanged:
                              canInteractWithSettings
                                  ? (Song? value) {
                                    if (value != null) _onSongChanged(value);
                                  }
                                  : null,
                          initialValue: _selectedSong,
                        ),
                      ),
                    TimerDisplayWidget(
                      isLoadingSong: _isLoadingSong,
                      timerText: _timerText,
                      borderRadius: defaultBorderRadius,
                    ),
                    const SizedBox(height: 12),
                    Visibility(
                      visible: canInteractWithSettings,
                      child: BpmControlSectionWidget(
                        isLoadingSong: _isLoadingSong,
                        isChallengeRunning: _isChallengeRunning,
                        currentManualBpm: _currentManualBpm,
                        beatHighlighter: _beatHighlighter,
                        bpmChangedByTap: _bpmChangedByTap,
                        bpmIndicatorScale: bpmIndicatorScale,
                        bpmIndicatorColor: bpmIndicatorColor,
                        bpmTextColor: bpmTextColor,
                        defaultBorderRadius: defaultBorderRadius,
                        tapTimestamps: _tapTimestamps,
                        onChangeBpmToPreset: _changeBpmToPreset,
                        onChangeBpm: _changeBpm,
                        onStartBpmAdjustTimer: _startBpmAdjustTimer,
                        onStopBpmAdjustTimer: _stopBpmAdjustTimer,
                        onHandleTapForBpm: _handleTapForBpm,
                        slowBpm: slowBpm,
                        normalBpm: normalBpm,
                        fastBpm: fastBpm,
                      ),
                    ),
                    if (canInteractWithSettings)
                      const SizedBox(height: 24)
                    else
                      const SizedBox(height: 12),
                    ProgressDisplayWidget(
                      isLoadingSong: _isLoadingSong,
                      isChallengeRunning: _isChallengeRunning,
                      progressPercent: _progressPercent,
                    ),
                    const SizedBox(height: 30),
                    MusicControlWidget(
                      isLoadingSong: _isLoadingSong,
                      isChallengeRunning: _isChallengeRunning,
                      isPlaying: _isPlaying,
                      selectedSong: _selectedSong,
                      audioDuration: _audioDuration,
                      currentPlaybackSpeed: _currentPlaybackSpeed,
                      currentManualBpm: _currentManualBpm,
                      defaultBorderRadius: defaultBorderRadius,
                      onPlayPause: _handlePlayPause,
                      onStop: _handleStop,
                    ),
                    const SizedBox(height: 30),
                    ChallengeControlButtonWidget(
                      isLoadingSong: _isLoadingSong,
                      isChallengeRunning: _isChallengeRunning,
                      onPressed: () {
                        if (_isChallengeRunning) {
                          _stopChallenge();
                        } else {
                          if (_audioDuration == null) {
                            if (mounted) {
                              ShadToaster.of(context).show(
                                ShadToast(
                                  title: const Text('오류'),
                                  description: const Text('음악 정보를 로드 중입니다.'),
                                ),
                              );
                            }
                            return;
                          }
                          _startChallenge();
                        }
                      },
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
}
