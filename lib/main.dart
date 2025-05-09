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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  final String _currentSongTitle = '논삶는소리 (강원 홍천군)';
  Duration? _audioDuration;

  Timer? _timer;
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isTimerRunning = false;
  double _progressPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _updateTimerText();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setAsset('assets/audio/se0101.mp3');
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
    } catch (e) {
      print("Error loading audio source: $e");
    }

    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
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

  void _startTimer() {
    if (_isTimerRunning) return;

    if (_audioDuration != null) {
      _remainingTime = _audioDuration!;
    } else {
      if (_audioDuration == null) {
        print("오디오 정보가 아직 로드되지 않았습니다.");
      }
    }
    _updateTimerText();
    _updateProgress();

    setState(() {
      _isTimerRunning = true;
    });
    _audioPlayer.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopTimer(completed: true);
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
            _updateTimerText();
            _updateProgress();
          });
        }
      }
    });
  }

  void _stopTimer({bool completed = false}) {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerRunning = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else if (_audioDuration != null) {
          _updateProgress();
        }
      });
    }
    _audioPlayer.pause();
    if (completed) {
      print('작업 완료!');
      if (_audioDuration != null) {}
    }
    _updateTimerText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('리듬농부 메이트'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    _timerText,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(
                  child: Text(
                    'BPM 리듬 표시기 (예: 아이콘)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: _progressPercent,
                minHeight: 20,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      '현재 재생 중: $_currentSongTitle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          iconSize: 48,
                          onPressed: () {
                            if (_isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          iconSize: 48,
                          onPressed: () {
                            _audioPlayer.stop();
                            _audioPlayer.seek(Duration.zero);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor:
                      _isTimerRunning
                          ? Colors.redAccent
                          : Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  if (_isTimerRunning) {
                    _stopTimer();
                  } else {
                    if (_audioDuration != null &&
                        (_remainingTime.inSeconds == 0 ||
                            _remainingTime != _audioDuration)) {
                      setState(() {
                        _remainingTime = _audioDuration!;
                        _progressPercent = 0.0;
                        _updateTimerText();
                      });
                    }
                    _startTimer();
                  }
                },
                child: Text(
                  _isTimerRunning ? '작업 중지' : '작업 시작',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
