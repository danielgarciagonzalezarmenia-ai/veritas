import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/session.dart';

class SessionStore {
  File? _file;
  List<Session> sessions = [];
  AppSettings settings = const AppSettings();

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File(
      '${directory.path}${Platform.pathSeparator}veritas_store.json',
    );
    await _load();
  }

  Future<void> _load() async {
    final file = _file;
    if (file == null || !await file.exists()) return;
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      settings = AppSettings.fromJson(
        Map<String, dynamic>.from(decoded['settings'] as Map? ?? const {}),
      );
      final list = decoded['sessions'] as List<dynamic>? ?? const [];
      sessions = list
          .whereType<Map>()
          .map((item) => Session.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      sessions = [];
    }
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    final payload = jsonEncode({
      'version': 1,
      'settings': settings.toJson(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
    });
    await file.writeAsString(payload, flush: true);
  }

  Future<void> saveSession(Session session) async {
    sessions = [session, ...sessions.where((item) => item.id != session.id)];
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    await _persist();
  }

  Future<void> deleteSession(String id) async {
    sessions = sessions.where((session) => session.id != id).toList();
    await _persist();
  }

  Future<void> clearSessions() async {
    sessions = [];
    await _persist();
  }

  Future<void> saveSettings(AppSettings value) async {
    settings = value;
    await _persist();
  }
}
