import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/session.dart';
import '../services/session_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store);

  final SessionStore _store;

  List<Session> sessions = [];
  AppSettings settings = const AppSettings();
  bool ready = false;

  Future<void> load() async {
    await _store.init();
    sessions = _store.sessions;
    settings = _store.settings;
    ready = true;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    notifyListeners();
    await _store.saveSettings(value);
  }

  Future<void> completeOnboarding() async {
    await updateSettings(settings.copyWith(onboarded: true));
  }

  Future<void> addSession(Session session) async {
    sessions = [session, ...sessions];
    notifyListeners();
    await _store.saveSession(session);
  }

  Future<void> deleteSession(String id) async {
    sessions = sessions.where((session) => session.id != id).toList();
    notifyListeners();
    await _store.deleteSession(id);
  }

  Future<void> clearSessions() async {
    sessions = [];
    notifyListeners();
    await _store.clearSessions();
  }

  double get averageScore {
    if (sessions.isEmpty) return 0;
    final total = sessions.fold<double>(0, (sum, s) => sum + s.score);
    return total / sessions.length;
  }

  Session? get lastSession => sessions.isEmpty ? null : sessions.first;

  int get coherentCount =>
      sessions.where((session) => session.score >= 72).length;

  int get inconsistentCount =>
      sessions.where((session) => session.score < 45).length;

  double get averageConfidence {
    if (sessions.isEmpty) return 0;
    return sessions.fold<double>(0, (sum, s) => sum + s.confidence) /
        sessions.length;
  }

  double get averageBlinkRate {
    final valid = sessions.where((session) => session.blinkRate > 0);
    if (valid.isEmpty) return 0;
    return valid.fold<double>(0, (sum, s) => sum + s.blinkRate) / valid.length;
  }
}
