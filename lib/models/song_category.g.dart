// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongCategoryTypeAdapter extends TypeAdapter<SongCategoryType> {
  @override
  final int typeId = 1;

  @override
  SongCategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SongCategoryType.traditionalNongyo1;
      case 1:
        return SongCategoryType.traditionalNongyo2;
      case 2:
        return SongCategoryType.traditionalNongyo3;
      case 3:
        return SongCategoryType.traditionalNongyo4;
      case 4:
        return SongCategoryType.modernLaborSong;
      case 5:
        return SongCategoryType.userRegistered;
      default:
        return SongCategoryType.traditionalNongyo1;
    }
  }

  @override
  void write(BinaryWriter writer, SongCategoryType obj) {
    switch (obj) {
      case SongCategoryType.traditionalNongyo1:
        writer.writeByte(0);
        break;
      case SongCategoryType.traditionalNongyo2:
        writer.writeByte(1);
        break;
      case SongCategoryType.traditionalNongyo3:
        writer.writeByte(2);
        break;
      case SongCategoryType.traditionalNongyo4:
        writer.writeByte(3);
        break;
      case SongCategoryType.modernLaborSong:
        writer.writeByte(4);
        break;
      case SongCategoryType.userRegistered:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongCategoryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
