import 'package:flutter/material.dart'
    hide BorderStyle; // BoxDecoration, Border, BorderRadius는 사용
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shadcn_ui/shadcn_ui.dart'; // shadcn_ui import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      title: '리듬농부 메이트',
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(), // 구체적인 색상 스킴 명시
        // radius: ShadRadius.md, // 테마 radius 설정 제거 또는 고정값 사용
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(), // 구체적인 색상 스킴 명시
        // radius: ShadRadius.md,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ShadToaster(child: child!),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

// Splash Screen 위젯 (Shadcn UI 스타일로 일부 변경)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () => Navigator.of(context).pushReplacementNamed('/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Shadcn 테마 배경색 사용
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              '리듬농부 메이트',
              style: theme.textTheme.h2.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Song 데이터 클래스
class Song {
  final String filePath;
  final String title;
  final int bpm;

  const Song({required this.filePath, required this.title, required this.bpm});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  late AudioPlayer _metronomePlayer; // 메트로놈용 오디오 플레이어
  bool _isPlaying = false;
  Duration? _audioDuration;
  bool _isLoadingSong = true; // 로딩 상태 변수 추가

  Timer? _timer;
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isTimerRunning = false;
  double _progressPercent = 0.0;

  Timer? _bpmTimer;
  bool _beatHighlighter = false;

  final List<Song> _songList = const [
    Song(filePath: 'assets/audio/se0101.mp3', title: '논삶는소리 (강원 홍천군)', bpm: 60),
    Song(
      filePath: 'assets/audio/se0102.mp3',
      title: '논고르는소리 (제주 서귀포시)',
      bpm: 90,
    ),
    Song(
      filePath: 'assets/audio/se0103.mp3',
      title: '모찌는소리 - 얼른 하더니 한 춤 (강원 양양군)',
      bpm: 120,
    ),
  ];
  late Song _selectedSong;
  late int _currentManualBpm; // 사용자가 조절하는 BPM
  double _currentPlaybackSpeed = 1.0; // 현재 재생 속도

  @override
  void initState() {
    super.initState();
    _selectedSong = _songList.first;
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();
    _initAudioPlayers(); // 내부에서 _isLoadingSong = false 처리
    _updateTimerText();
  }

  Future<void> _initAudioPlayers() async {
    if (mounted) {
      setState(() {
        _isLoadingSong = true;
      });
    }
    try {
      await _audioPlayer.setAsset(_selectedSong.filePath);
      await _metronomePlayer.setAsset('assets/audio/tick.mp3');

      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDuration = duration;
            if (!_isTimerRunning && _audioDuration != null) {
              _remainingTime = Duration(
                seconds:
                    (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
              );
              _updateTimerText();
              _updateProgress();
            }
          });
        }
      });

      // durationStream이 안정적으로 첫 값을 받을 때까지 기다리거나, 최초 로드 완료 시점으로 이동
      // 또는 setAsset 완료 후 바로 로딩 완료로 간주 (duration은 나중에 업데이트)
      // 여기서는 setAsset 완료 후 로딩 완료로 처리하고, duration은 비동기 업데이트되도록 함.
      if (mounted) {
        // 약간의 딜레이를 주어 durationStream이 첫 값을 받을 기회를 줌 (이상적인 방법은 아님)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingSong = false;
              // 만약 이때 _audioDuration이 아직 null이면, 기본값이나 초기화 필요
              if (_audioDuration == null && _audioPlayer.duration != null) {
                _audioDuration = _audioPlayer.duration; // 직접 가져오기 시도
                if (!_isTimerRunning && _audioDuration != null) {
                  _remainingTime = Duration(
                    seconds:
                        (_audioDuration!.inSeconds / _currentPlaybackSpeed)
                            .round(),
                  );
                  _updateTimerText();
                  _updateProgress();
                }
              }
            });
          }
        });
      }

      _audioPlayer.playingStream.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
      // 재생 속도 초기화
      await _audioPlayer.setSpeed(_currentPlaybackSpeed);
    } catch (e) {
      print("Error loading audio source: $e");
      if (e.toString().contains('assets/audio/tick.mp3')) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text(
              '메트로놈 사운드(tick.mp3) 로드 실패! assets/audio 폴더를 확인하세요.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _metronomePlayer.dispose(); // 메트로놈 플레이어 리소스 해제
    _timer?.cancel();
    _bpmTimer?.cancel();
    super.dispose();
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
    if (_audioDuration != null &&
        _audioDuration!.inSeconds > 0 &&
        _currentPlaybackSpeed > 0) {
      final totalDurationAdjusted =
          _audioDuration!.inSeconds / _currentPlaybackSpeed;
      if (totalDurationAdjusted > 0) {
        final elapsedTimeAdjusted =
            totalDurationAdjusted - _remainingTime.inSeconds;
        setState(() {
          _progressPercent = (elapsedTimeAdjusted / totalDurationAdjusted)
              .clamp(0.0, 1.0);
        });
      } else {
        setState(() {
          _progressPercent = 0.0;
        });
      }
    } else {
      setState(() {
        _progressPercent = 0.0;
      });
    }
  }

  void _startTimers() {
    if (_isTimerRunning) return;
    if (_audioDuration == null) {
      if (mounted)
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text('음악 파일 정보를 로드 중입니다.'),
          ),
        );
      return;
    }
    _remainingTime = Duration(
      seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
    );
    _updateTimerText();
    // _updateProgress(); // 타이머 시작 시점에서 진행도는 0이 되어야 함
    if (mounted)
      setState(() {
        _progressPercent = 0.0;
      });

    setState(() {
      _isTimerRunning = true;
      _beatHighlighter = false;
    });
    _audioPlayer.setSpeed(_currentPlaybackSpeed);
    _audioPlayer.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopTimers(completed: true);
      } else {
        if (mounted) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
          _updateTimerText();
          _updateProgress(); // 매초 진행도 업데이트
        }
      }
    });
    _restartBpmTimer();
  }

  void _stopTimers({bool completed = false}) {
    _timer?.cancel();
    _bpmTimer?.cancel();
    if (mounted)
      setState(() {
        _isTimerRunning = false;
        _beatHighlighter = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else {
          _updateProgress();
        }
      });
    _audioPlayer.pause();
    if (completed && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('챌린지 성공!'),
          description: const Text('잘 하셨어요! 🎉'),
        ),
      );
    }
    _updateTimerText();
  }

  void _restartBpmTimer() {
    _bpmTimer?.cancel();
    if (!_isTimerRunning && !_isPlaying) {}
    final beatInterval = (60000 / _currentManualBpm).round();
    if (beatInterval <= 0)
      return; // Prevent negative or zero duration for Timer
    _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      if (mounted)
        setState(() {
          _beatHighlighter = !_beatHighlighter;
        });
      if (_isTimerRunning || _isPlaying) {
        _metronomePlayer.seek(Duration.zero);
        _metronomePlayer.play();
      }
    });
  }

  void _changeBpm(int delta) {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('작업 중 BPM 변경 불가')));
      return;
    }
    setState(() {
      int newBpm = (_currentManualBpm + delta).clamp(30, 240);
      _currentManualBpm = newBpm;
      if (_selectedSong.bpm == 0) {
        // Prevent division by zero
        _currentPlaybackSpeed = 1.0;
      } else {
        _currentPlaybackSpeed = (_currentManualBpm / _selectedSong.bpm).clamp(
          0.5,
          2.0,
        );
      }
      _audioPlayer.setSpeed(_currentPlaybackSpeed);
      if (_isTimerRunning || _isPlaying || (_bpmTimer?.isActive ?? false))
        _restartBpmTimer();
      if (!_isTimerRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
        );
        _updateTimerText();
        _updateProgress();
      }
    });
  }

  Future<void> _onSongChanged(Song newSong) async {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('작업 중 곡 변경 불가')));
      return;
    }
    if (mounted)
      setState(() {
        _isLoadingSong = true;
      });
    setState(() {
      _selectedSong = newSong;
      _currentManualBpm =
          _selectedSong.bpm == 0 ? 60 : _selectedSong.bpm; // 기본 BPM 설정
      _currentPlaybackSpeed = 1.0;
      _isPlaying = false;
      _progressPercent = 0.0;
      _remainingTime = Duration.zero;
      _timerText = '00:00';
      _audioDuration = null;
      _beatHighlighter = false;
    });
    await _audioPlayer.stop();
    _bpmTimer?.cancel();
    await _initAudioPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = BorderRadius.circular(6.0); // 고정값 사용

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          '리듬농부 메이트',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primaryForeground,
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
                    if (!_isTimerRunning && !_isLoadingSong)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ShadSelect<Song>(
                          placeholder: Text(
                            '노동요를 선택하세요',
                            style: TextStyle(
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
                              _isLoadingSong
                                  ? null
                                  : (Song? value) {
                                    if (value != null) _onSongChanged(value);
                                  },
                          initialValue: _selectedSong,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            _isLoadingSong
                                ? theme.colorScheme.muted
                                : theme.colorScheme.card,
                        borderRadius: defaultBorderRadius,
                        border: Border.all(color: theme.colorScheme.border),
                      ),
                      child: Center(
                        child:
                            _isLoadingSong
                                ? Text(
                                  "노래 로딩 중...",
                                  style: theme.textTheme.h4.copyWith(
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                )
                                : Text(
                                  _timerText,
                                  style: theme.textTheme.h1.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.foreground,
                                    fontSize: 60,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShadButton.outline(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          onPressed:
                              _isTimerRunning ||
                                      _isLoadingSong ||
                                      _currentManualBpm <= 30
                                  ? null
                                  : () => _changeBpm(-5),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  _isLoadingSong
                                      ? theme.colorScheme.muted
                                      : (_beatHighlighter
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.2)
                                          : theme.colorScheme.card),
                              borderRadius: defaultBorderRadius,
                              border: Border.all(
                                color: theme.colorScheme.border,
                              ),
                            ),
                            child: Center(
                              child:
                                  _isLoadingSong
                                      ? Text(
                                        "--",
                                        style: theme.textTheme.p.copyWith(
                                          color:
                                              theme.colorScheme.mutedForeground,
                                        ),
                                      )
                                      : Text(
                                        'BPM: $_currentManualBpm',
                                        style: theme.textTheme.p.copyWith(
                                          color:
                                              _beatHighlighter
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .colorScheme
                                                      .foreground,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        ShadButton.outline(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed:
                              _isTimerRunning ||
                                      _isLoadingSong ||
                                      _currentManualBpm >= 240
                                  ? null
                                  : () => _changeBpm(5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ShadProgress(
                      value: _isLoadingSong ? 0 : _progressPercent * 100,
                      minHeight: 12,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.muted,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _isLoadingSong
                            ? '로딩 중...'
                            : '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _isLoadingSong
                                ? theme.colorScheme.muted
                                : theme.colorScheme.card,
                        borderRadius: defaultBorderRadius,
                        border: Border.all(color: theme.colorScheme.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isLoadingSong
                                ? '로딩 중...'
                                : '현재 재생 중: ${_selectedSong.title}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isLoadingSong && _audioDuration != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _currentPlaybackSpeed == 1.0
                                    ? "(원곡 속도, BPM: ${_selectedSong.bpm})"
                                    : '재생 속도: ${_currentPlaybackSpeed.toStringAsFixed(1)}x (BPM: ${_selectedSong.bpm} -> $_currentManualBpm)',
                                style: theme.textTheme.small.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ShadButton.ghost(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle_outline,
                                  color: theme.colorScheme.primary,
                                  size: 48,
                                ),
                                onPressed:
                                    _isLoadingSong || _audioDuration == null
                                        ? null
                                        : () {
                                          if (_isPlaying)
                                            _audioPlayer.pause();
                                          else {
                                            _audioPlayer.setSpeed(
                                              _currentPlaybackSpeed,
                                            );
                                            _audioPlayer.play();
                                            if (!_isTimerRunning)
                                              _restartBpmTimer();
                                          }
                                        },
                              ),
                              ShadButton.ghost(
                                icon: Icon(
                                  Icons.stop_circle_outlined,
                                  color: theme.colorScheme.destructive,
                                  size: 48,
                                ),
                                onPressed:
                                    _isLoadingSong || _audioDuration == null
                                        ? null
                                        : () {
                                          _audioPlayer.stop();
                                          _audioPlayer.seek(Duration.zero);
                                        },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ShadButton(
                      size: ShadButtonSize.lg,
                      child: Text(
                        _isLoadingSong
                            ? '노래 로딩 중...'
                            : (_isTimerRunning ? '작업 중지' : '작업 시작'),
                      ),
                      onPressed:
                          _isLoadingSong
                              ? null
                              : () {
                                if (_isTimerRunning) {
                                  _stopTimers();
                                } else {
                                  if (_audioDuration == null) {
                                    if (mounted)
                                      ShadToaster.of(context).show(
                                        ShadToast(
                                          title: const Text('오류'),
                                          description: const Text(
                                            '음악 정보를 로드 중입니다.',
                                          ),
                                        ),
                                      );
                                    return;
                                  }
                                  if (_remainingTime.inSeconds == 0 ||
                                      _remainingTime.inSeconds.toDouble() !=
                                          (_audioDuration!.inSeconds /
                                                  (_currentPlaybackSpeed > 0
                                                      ? _currentPlaybackSpeed
                                                      : 1.0))
                                              .round()) {
                                    if (mounted)
                                      setState(() {
                                        _remainingTime = Duration(
                                          seconds:
                                              (_audioDuration!.inSeconds /
                                                      (_currentPlaybackSpeed > 0
                                                          ? _currentPlaybackSpeed
                                                          : 1.0))
                                                  .round(),
                                        );
                                        _progressPercent = 0.0;
                                        _updateTimerText();
                                      });
                                  }
                                  _startTimers();
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
