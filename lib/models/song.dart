import './song_category.dart';

// Song 데이터 클래스
class Song {
  final String filePath;
  final String title;
  final int bpm;
  final SongCategoryType categoryType; // 곡의 주 카테고리
  final String? subCategory; // 하위 카테고리 (선택적)

  const Song({
    required this.filePath,
    required this.title,
    required this.bpm,
    required this.categoryType,
    this.subCategory,
  });
}
