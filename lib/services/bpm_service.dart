import 'dart:async';

class BpmService {
  static const double slowSpeed = 0.5;
  static const double normalSpeed = 1.0;
  static const double fastSpeed = 1.5;

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  // BPM 프리셋에 따른 재생 속도 및 BPM 값 계산
  static Map<String, dynamic> calculateBpmFromPreset({
    required int originalBpm,
    required int presetBpm,
  }) {
    double newSpeed;
    int calculatedBpm;

    if (presetBpm == slowBpm) {
      newSpeed = slowSpeed;
      calculatedBpm = (originalBpm * slowSpeed).round();
    } else if (presetBpm == normalBpm) {
      newSpeed = normalSpeed;
      calculatedBpm = originalBpm;
    } else if (presetBpm == fastBpm) {
      newSpeed = fastSpeed;
      calculatedBpm = (originalBpm * fastSpeed).round();
    } else {
      newSpeed = normalSpeed;
      calculatedBpm = originalBpm;
    }

    return {'bpm': calculatedBpm, 'speed': newSpeed};
  }

  // 탭 시간 간격을 기반으로 BPM 계산
  static int calculateBpmFromTaps(List<DateTime> tapTimestamps) {
    if (tapTimestamps.length < 2) return 0;

    final intervals = <int>[];
    for (int i = 1; i < tapTimestamps.length; i++) {
      intervals.add(
        tapTimestamps[i].difference(tapTimestamps[i - 1]).inMilliseconds,
      );
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final calculatedBpm = (60000 / avgInterval).round();

    return calculatedBpm.clamp(20, 240);
  }

  // BPM 값 변경 (증가/감소)
  static int changeBpm(int currentBpm, int delta) {
    return (currentBpm + delta).clamp(20, 240);
  }
}
