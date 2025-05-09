import 'package:hive/hive.dart';

part 'song_category.g.dart'; // Hive generator가 생성할 파일

// ignore_for_file: public_member_api_docs, sort_constructors_first
@HiveType(typeId: 1) // HiveType 어노테이션 추가 및 고유 typeId 지정 (Song과 다른 ID)
enum SongCategoryType {
  @HiveField(0)
  traditionalNongyo1, // 농요[1] - 논고르기 / 모찌기 / 모심기 / 기타 농요
  @HiveField(1)
  traditionalNongyo2, // 농요[2] - 논매기(1)
  @HiveField(2)
  traditionalNongyo3, // 농요[3] - 논매기(2) / 벼베기 / 벼타작 / 물푸기 / 기타
  @HiveField(3)
  traditionalNongyo4, // 농요[4] - 밭갈이 / 밭매기 / 보리타작 / 풀베기 / 말몰이 / 기타
  @HiveField(4)
  modernLaborSong, // 현대 노동요
  @HiveField(5)
  userRegistered, // 내가 등록한 노래
}

class SongCategory {
  final SongCategoryType type;
  final String title;
  final String description; // 각 카테고리 설명 (예: 포함된 농요 종류)
  final List<String> subCategories; // 하위 카테고리명 (선택적)

  SongCategory({
    required this.type,
    required this.title,
    required this.description,
    this.subCategories = const [],
  });

  static List<SongCategory> getCategories() {
    return [
      SongCategory(
        type: SongCategoryType.traditionalNongyo1,
        title: '농요 [1]',
        description: '논고르기 / 모찌기 / 모심기 / 기타 농요',
      ),
      SongCategory(
        type: SongCategoryType.traditionalNongyo2,
        title: '농요 [2]',
        description: '논매기 (1)',
      ),
      SongCategory(
        type: SongCategoryType.traditionalNongyo3,
        title: '농요 [3]',
        description: '논매기 (2) / 벼베기 / 벼타작 / 물푸기 / 기타',
      ),
      SongCategory(
        type: SongCategoryType.traditionalNongyo4,
        title: '농요 [4]',
        description: '밭갈이 / 밭매기 / 보리타작 / 풀베기 / 말몰이 / 기타',
      ),
      SongCategory(
        type: SongCategoryType.modernLaborSong,
        title: '현대 노동요',
        description: '현대적인 작업에 어울리는 노동요',
      ),
      SongCategory(
        type: SongCategoryType.userRegistered,
        title: '내가 등록한 노래',
        description: '내가 직접 추가한 노래 (로컬 파일 또는 향후 유튜브 링크)',
      ),
    ];
  }
}
