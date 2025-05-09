import 'package:flutter/material.dart'
    hide BorderStyle; // BoxDecoration, Border, BorderRadius는 사용
import 'package:hive_flutter/hive_flutter.dart'; // hive_flutter import
import 'package:path_provider/path_provider.dart'; // path_provider import
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb import
import 'package:rhythm_farmer_mate/my_app.dart'; // MyApp import
import './models/song.dart'; // SongAdapter를 위해 import
import './models/song_category.dart'; // SongCategoryTypeAdapter를 위해 import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 바인딩 초기화

  // Hive 초기화
  if (!kIsWeb) {
    // 웹이 아닐 경우에만 path_provider 사용
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  } else {
    await Hive.initFlutter(); // 웹에서는 경로 지정 없이 초기화
  }

  // Adapter 등록
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(SongCategoryTypeAdapter());

  // 필요한 Box들 열기 (예: 사용자 노래 목록을 위한 Box)
  await Hive.openBox<Song>('userSongsBox');
  // 다른 Box들도 필요하다면 여기서 열어줍니다.

  runApp(const MyApp());
}
