import 'package:hive/hive.dart';
import '../models/song.dart';

class UserSongService {
  static const String _boxName = 'userSongsBox';

  // Box<Song> get _userSongsBox => Hive.box<Song>(_boxName);
  // Box가 열려있음을 보장하기 위해 Future<Box<Song>> 형태로 변경
  Future<Box<Song>> get _userSongsBox async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Song>(_boxName);
    }
    return Hive.box<Song>(_boxName);
  }

  Future<void> addUserSong(Song song) async {
    final box = await _userSongsBox;
    // Hive에 객체를 추가할 때는 add() 또는 put()을 사용합니다.
    // add()는 자동 증가하는 정수 키를 사용하고, put()은 지정된 키를 사용합니다.
    // 여기서는 간단히 add()를 사용하겠습니다. 중복 관리가 필요하면 put()과 고유 ID를 고려해야 합니다.
    await box.add(song);
  }

  Future<List<Song>> getUserSongs() async {
    final box = await _userSongsBox;
    return box.values.toList();
  }

  Future<void> deleteUserSong(Song songToDelete) async {
    final box = await _userSongsBox;
    // HiveObject를 직접 삭제하려면 해당 객체의 key를 알아야 합니다.
    // Song 객체가 HiveObject를 상속했으므로, songToDelete.key를 사용할 수 있습니다.
    if (songToDelete.isInBox) {
      // 객체가 Box에 있는지 확인 (key가 할당되었는지)
      await box.delete(songToDelete.key);
    }
  }

  Future<void> updateUserSong(Song oldSong, Song newSong) async {
    final box = await _userSongsBox;
    if (oldSong.isInBox) {
      await box.put(oldSong.key, newSong);
    }
  }

  // 모든 사용자 노래 삭제 (테스트 또는 초기화용)
  Future<void> deleteAllUserSongs() async {
    final box = await _userSongsBox;
    await box.clear();
  }
}
