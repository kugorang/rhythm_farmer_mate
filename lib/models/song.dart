import 'package:hive/hive.dart';
import './song_category.dart';

part 'song.g.dart'; // Hive generator가 생성할 파일

// Song 데이터 클래스
@HiveType(typeId: 0) // HiveType 어노테이션 추가 및 고유 typeId 지정
class Song extends HiveObject {
  // HiveObject를 확장
  @HiveField(0) // 각 필드에 HiveField 어노테이션 및 고유 인덱스 지정
  final String? filePath;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int bpm;

  @HiveField(3)
  final SongCategoryType categoryType;

  @HiveField(4)
  final String? subCategory;

  @HiveField(5)
  final String? youtubeVideoId;

  // Hive는 기본 생성자가 필요할 수 있음
  Song({
    this.filePath,
    required this.title,
    required this.bpm,
    required this.categoryType,
    this.subCategory,
    this.youtubeVideoId,
  }) : assert(
         filePath != null || youtubeVideoId != null,
         'filePath 또는 youtubeVideoId 둘 중 하나는 반드시 있어야 합니다.',
       );
}
