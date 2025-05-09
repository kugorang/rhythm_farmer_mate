import './song_category.dart';

// Song 데이터 클래스
class Song {
  final String? filePath; // Nullable String
  final String title;
  final int bpm;
  final SongCategoryType categoryType; // 곡의 주 카테고리
  final String? subCategory; // 하위 카테고리 (선택적)
  final String? youtubeVideoId; // Nullable String, 이 필드명이 정확해야 함

  const Song({
    this.filePath, // 생성자에서도 nullable로 받음
    required this.title,
    required this.bpm,
    required this.categoryType,
    this.subCategory,
    this.youtubeVideoId, // 생성자 파라미터명도 정확해야 함
  }) : assert(
         filePath != null || youtubeVideoId != null,
         'filePath 또는 youtubeVideoId 둘 중 하나는 반드시 있어야 합니다.',
       );
}
