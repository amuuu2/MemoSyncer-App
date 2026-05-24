import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地数据库
  final db = DatabaseService();
  await db.init();

  runApp(
    const ProviderScope(
      child: MemoSyncerApp(),
    ),
  );
}
