import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리듬농부 메이트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 20),
            const Text(
              '리듬농부 메이트',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.green.shade300),
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
    _currentManualBpm = _selectedSong.bpm; // 초기 BPM 설정
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer(); // 메트로놈 플레이어 초기화
    _initAudioPlayers();
    _updateTimerText();
  }

  Future<void> _initAudioPlayers() async {
    try {
      await _audioPlayer.setAsset(_selectedSong.filePath);
      await _metronomePlayer.setAsset('assets/audio/tick.mp3'); // 메트로놈 사운드 로드

      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDuration = duration;
            if (!_isTimerRunning && _audioDuration != null) {
              _remainingTime = _audioDuration!;
              _updateTimerText();
              _updateProgress();
            }
          });
        }
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메트로놈 사운드(tick.mp3) 로드 실패! assets/audio 폴더를 확인하세요.'),
            backgroundColor: Colors.red,
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
    if (_audioDuration != null && _audioDuration!.inSeconds > 0) {
      final elapsedTime = _audioDuration!.inSeconds - _remainingTime.inSeconds;
      if (mounted) {
        setState(() {
          _progressPercent = elapsedTime / _audioDuration!.inSeconds;
          if (_progressPercent < 0) _progressPercent = 0;
          if (_progressPercent > 1) _progressPercent = 1;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _progressPercent = 0.0;
        });
      }
    }
  }

  void _startTimers() {
    // 함수 이름 변경: _startTimer -> _startTimers
    if (_isTimerRunning) return;

    if (_audioDuration != null) {
      _remainingTime = Duration(
        seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
      );
    } else {
      if (_audioDuration == null) {
        print("오디오 정보가 아직 로드되지 않았습니다. 기본 길이로 타이머를 시작할 수 없습니다.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음악 파일 정보를 로드 중입니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    _updateTimerText();
    _updateProgress();

    setState(() {
      _isTimerRunning = true;
      _beatHighlighter = false;
    });

    _audioPlayer.setSpeed(_currentPlaybackSpeed); // 재생 시작 전 속도 설정
    _audioPlayer.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopTimers(completed: true);
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
            _updateTimerText();
            // 진행도는 실제 재생된 음악 길이를 기준으로 해야 하지만, 여기서는 타이머 시간 기준으로 단순화
            if (_audioDuration != null && _audioDuration!.inSeconds > 0) {
              final totalPlayTimeOriginal = _audioDuration!.inSeconds;
              final expectedTotalPlayTimeAdjusted =
                  (totalPlayTimeOriginal / _currentPlaybackSpeed).round();
              if (expectedTotalPlayTimeAdjusted > 0) {
                _progressPercent =
                    1.0 -
                    (_remainingTime.inSeconds / expectedTotalPlayTimeAdjusted);
                if (_progressPercent < 0) _progressPercent = 0;
                if (_progressPercent > 1) _progressPercent = 1;
              }
            } else {
              _progressPercent = 0.0;
            }
          });
        }
      }
    });

    _restartBpmTimer(); // BPM 타이머 시작/재시작
  }

  void _stopTimers({bool completed = false}) {
    // 함수 이름 변경: _stopTimer -> _stopTimers
    _timer?.cancel();
    _bpmTimer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerRunning = false;
        _beatHighlighter = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else if (_audioDuration != null) {
          // 중지 시 진행도 업데이트 (위 _startTimers와 유사한 로직으로 수정)
          if (_audioDuration!.inSeconds > 0) {
            final totalPlayTimeOriginal = _audioDuration!.inSeconds;
            final expectedTotalPlayTimeAdjusted =
                (totalPlayTimeOriginal / _currentPlaybackSpeed).round();
            if (expectedTotalPlayTimeAdjusted > 0) {
              _progressPercent =
                  1.0 -
                  (_remainingTime.inSeconds / expectedTotalPlayTimeAdjusted);
              if (_progressPercent < 0) _progressPercent = 0;
              if (_progressPercent > 1) _progressPercent = 1;
            }
          } else {
            _progressPercent = 0.0;
          }
        }
      });
    }
    _audioPlayer.pause();
    if (completed) {
      print('작업 완료!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('챌린지 성공! 잘 하셨어요! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
    _updateTimerText();
  }

  void _restartBpmTimer() {
    _bpmTimer?.cancel();
    if (!_isTimerRunning && !_isPlaying) {
      // 작업이나 음악 재생 중이 아닐 때는 BPM 시각화만 (소리는 X)
      // 또는 아예 BPM 타이머를 시작하지 않을 수도 있음. 현재는 시각화는 유지.
    }

    final beatInterval = (60000 / _currentManualBpm).round();
    _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      if (mounted) {
        setState(() {
          _beatHighlighter = !_beatHighlighter;
        });
        if (_isTimerRunning || _isPlaying) {
          // 작업(타이머) 실행 중이거나 노래만 재생 중일 때 메트로놈 소리 재생
          _metronomePlayer.seek(Duration.zero);
          _metronomePlayer.play();
        }
      }
    });
  }

  void _changeBpm(int delta) {
    if (_isTimerRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업 중에는 BPM을 변경할 수 없습니다. 먼저 작업을 중지해주세요.')),
      );
      return;
    }
    setState(() {
      int newBpm = _currentManualBpm + delta;
      if (newBpm < 30) newBpm = 30; // 최소 BPM
      if (newBpm > 240) newBpm = 240; // 최대 BPM
      _currentManualBpm = newBpm;

      _currentPlaybackSpeed = _currentManualBpm / _selectedSong.bpm;
      // 재생 속도 제한 (0.5x ~ 2.0x)
      if (_currentPlaybackSpeed < 0.5) _currentPlaybackSpeed = 0.5;
      if (_currentPlaybackSpeed > 2.0) _currentPlaybackSpeed = 2.0;

      _audioPlayer.setSpeed(_currentPlaybackSpeed);

      if (_isTimerRunning || _isPlaying) {
        // 타이머가 돌고 있거나, 음악만 재생 중일 때 BPM 타이머 즉시 재시작
        _restartBpmTimer();
      } else {
        // 정지 상태에서는 BPM 값만 업데이트 (시각화 타이머는 _startTimers 또는 play() 시 시작)
        // _bpmTimer가 이미 돌고 있다면 (예: 음악 정지 후 BPM 조정 시) 재시작 필요
        if (_bpmTimer?.isActive ?? false) {
          _restartBpmTimer(); // 시각적 표시 업데이트 위해
        }
      }
      // 타이머가 실행중이지 않고, 오디오 길이 정보가 있다면, 변경된 재생속도에 맞춰 남은 시간 텍스트 업데이트
      if (!_isTimerRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
        );
        _updateTimerText();
        _updateProgress(); // 진행도도 현재 상태에 맞게 업데이트 (주로 0이거나, 이전 정지 시점)
      }
    });
  }

  Future<void> _onSongChanged(Song newSong) async {
    if (_isTimerRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업 중에는 곡을 변경할 수 없습니다. 먼저 작업을 중지해주세요.')),
      );
      return;
    }

    setState(() {
      _selectedSong = newSong;
      _currentManualBpm = _selectedSong.bpm; // 새 곡의 BPM으로 수동 BPM 초기화
      _currentPlaybackSpeed = 1.0; // 재생 속도 1배로 초기화
      _isPlaying = false;
      _progressPercent = 0.0;
      _remainingTime = const Duration(seconds: 0);
      _timerText = '00:00';
      _audioDuration = null;
      _beatHighlighter = false; // 곡 변경 시 하이라이터 초기화
    });
    await _audioPlayer.stop();
    _bpmTimer?.cancel(); // 이전 곡의 BPM 타이머 중지
    await _initAudioPlayers(); // 내부에서 setAsset, setSpeed(1.0) 호출됨
    // _initAudioPlayers 후 _audioDuration 로드되면 _remainingTime 등 자동 업데이트됨
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          '리듬농부 메이트',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = screenWidth < 600 ? 24.0 : 48.0;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!_isTimerRunning)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<Song>(
                          decoration: InputDecoration(
                            labelText: '노동요 선택',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          value: _selectedSong,
                          items:
                              _songList.map((Song song) {
                                return DropdownMenuItem<Song>(
                                  value: song,
                                  child: Text(
                                    song.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (Song? newValue) {
                            if (newValue != null) {
                              _onSongChanged(newValue);
                            }
                          },
                          isExpanded: true,
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          _timerText,
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BPM Control UI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 30,
                          color: Colors.blueGrey,
                          onPressed:
                              _isTimerRunning
                                  ? null
                                  : () => _changeBpm(-5), // 작업 중에는 BPM 변경 불가
                        ),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color:
                                  _beatHighlighter
                                      ? Colors.amberAccent.shade100
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: Text(
                                'BPM: $_currentManualBpm', // _selectedSong.bpm -> _currentManualBpm
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 30,
                          color: Colors.blueGrey,
                          onPressed:
                              _isTimerRunning
                                  ? null
                                  : () => _changeBpm(5), // 작업 중에는 BPM 변경 불가
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    LinearProgressIndicator(
                      value: _progressPercent,
                      minHeight: 25,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600,
                      ),
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '현재 재생 중: ${_selectedSong.title}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_audioDuration != null) // 재생 속도 표시 추가
                            Text(
                              '재생 속도: ${_currentPlaybackSpeed.toStringAsFixed(1)}x (BPM: ${_selectedSong.bpm} -> $_currentManualBpm)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Theme.of(context).primaryColor,
                                ),
                                iconSize: 60,
                                onPressed: () {
                                  if (_audioDuration == null) return;
                                  if (_isPlaying) {
                                    _audioPlayer.pause();
                                    // _bpmTimer?.cancel(); // 음악만 일시정지 시 BPM 시각화/소리도 멈출지 결정
                                  } else {
                                    _audioPlayer.setSpeed(
                                      _currentPlaybackSpeed,
                                    ); // 재생 시 현재 속도 적용
                                    _audioPlayer.play();
                                    if (!_isTimerRunning)
                                      _restartBpmTimer(); // 작업 타이머가 안 돌고 있을 때만 BPM 타이머 별도 시작/재시작
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.stop_circle_outlined,
                                  color: Colors.red.shade700,
                                ),
                                iconSize: 60,
                                onPressed: () {
                                  if (_audioDuration == null) return;
                                  _audioPlayer.stop();
                                  _audioPlayer.seek(Duration.zero);
                                  // _bpmTimer?.cancel(); // 음악 정지 시 BPM 시각화/소리도 멈출지 결정
                                  // setState(() { _isPlaying = false; _beatHighlighter = false; }); // 수동으로 상태 반영 필요시
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        backgroundColor:
                            _isTimerRunning
                                ? Colors.red.shade400
                                : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        if (_isTimerRunning) {
                          _stopTimers();
                        } else {
                          if (_audioDuration != null &&
                              (_remainingTime.inSeconds == 0 ||
                                  _remainingTime.inSeconds.toDouble() !=
                                      (_audioDuration!.inSeconds /
                                              _currentPlaybackSpeed)
                                          .round())) {
                            setState(() {
                              // 작업 시작 시, 현재 재생속도에 맞춰 _remainingTime 다시 계산
                              _remainingTime = Duration(
                                seconds:
                                    (_audioDuration!.inSeconds /
                                            _currentPlaybackSpeed)
                                        .round(),
                              );
                              _progressPercent = 0.0;
                              _updateTimerText();
                            });
                          }
                          _startTimers();
                        }
                      },
                      child: Text(
                        _isTimerRunning ? '작업 중지' : '작업 시작',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
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
}
