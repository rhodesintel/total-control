import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyBlockerEnabled = 'blocker_enabled';
  static const String _keyPasswordHash = 'password_hash';
  static const String _keyScheduleEnabled = 'schedule_enabled';
  static const String _keyWeeklySchedule = 'weekly_schedule';
  static const String _keySyllabusFilms = 'syllabus_films';
  static const String _keyBlockedSites = 'blocked_sites';
  static const String _keyBlockedApps = 'blocked_apps';
  static const String _keyVpnEnabled = 'vpn_enabled';

  // Standard browser packages to monitor
  static const List<String> browserPackages = [
    'com.android.chrome',
    'org.mozilla.firefox',
    'org.mozilla.firefox_beta',
    'com.microsoft.emmx',
    'com.opera.browser',
    'com.opera.mini.native',
    'com.brave.browser',
    'com.duckduckgo.mobile.android',
    'com.vivaldi.browser',
    'com.kiwibrowser.browser',
    'com.sec.android.app.sbrowser',
    'com.huawei.browser',
    'com.mi.globalbrowser',
    'com.UCMobile.intl',
    'com.android.browser',
    'mark.via.gp',
    'org.bromite.bromite',
    'com.ecosia.android',
  ];

  // Default blocked sites
  static const List<String> _defaultBlockedSites = [
    'netflix.com',
    'youtube.com',
    'primevideo.com',
    'disneyplus.com',
    'hulu.com',
    'max.com',
    'hbomax.com',
    'twitch.tv',
    'tiktok.com',
    'crunchyroll.com',
    'peacocktv.com',
    'paramountplus.com',
    'appletv.apple.com',
  ];

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    if (!_prefs!.containsKey(_keyBlockedSites)) {
      await _prefs!.setStringList(_keyBlockedSites, _defaultBlockedSites);
    }
  }

  bool get isBlockerEnabled => _prefs?.getBool(_keyBlockerEnabled) ?? true;
  Future<void> setBlockerEnabled(bool value) async => await _prefs?.setBool(_keyBlockerEnabled, value);

  // VPN state persistence for boot receiver
  bool get isVpnEnabled => _prefs?.getBool(_keyVpnEnabled) ?? true;
  Future<void> setVpnEnabled(bool value) async => await _prefs?.setBool(_keyVpnEnabled, value);

  bool get hasPassword {
    final hash = _prefs?.getString(_keyPasswordHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPassword(String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    await _prefs?.setString(_keyPasswordHash, hash);
  }

  bool verifyPassword(String password) {
    final storedHash = _prefs?.getString(_keyPasswordHash);
    if (storedHash == null) return true;
    return storedHash == sha256.convert(utf8.encode(password)).toString();
  }

  bool get isScheduleEnabled => _prefs?.getBool(_keyScheduleEnabled) ?? false;
  Future<void> setScheduleEnabled(bool value) async => await _prefs?.setBool(_keyScheduleEnabled, value);

  Map<int, Set<int>> get weeklySchedule {
    final json = _prefs?.getString(_keyWeeklySchedule);
    if (json == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      final result = <int, Set<int>>{};
      for (var entry in decoded.entries) {
        result[int.parse(entry.key)] = (entry.value as List).map((e) => e as int).toSet();
      }
      return result;
    } catch (e) {
      debugPrint('Error parsing schedule: $e');
      return {};
    }
  }

  Future<void> setWeeklySchedule(Map<int, Set<int>> schedule) async {
    final Map<String, List<int>> encoded = {};
    for (var entry in schedule.entries) {
      encoded[entry.key.toString()] = entry.value.toList();
    }
    await _prefs?.setString(_keyWeeklySchedule, jsonEncode(encoded));
  }

  List<String> get syllabusFilms => _prefs?.getStringList(_keySyllabusFilms) ?? [];
  Future<void> setSyllabusFilms(List<String> films) async => await _prefs?.setStringList(_keySyllabusFilms, films);

  List<String> get blockedSites => _prefs?.getStringList(_keyBlockedSites) ?? _defaultBlockedSites;
  Future<void> setBlockedSites(List<String> sites) async => await _prefs?.setStringList(_keyBlockedSites, sites);

  List<String> get blockedApps => _prefs?.getStringList(_keyBlockedApps) ?? [];
  Future<void> setBlockedApps(List<String> apps) async => await _prefs?.setStringList(_keyBlockedApps, apps);

  bool shouldBlockUrl(String url) {
    if (!isBlockerEnabled) return false;
    if (isScheduleEnabled) {
      final now = DateTime.now();
      final day = (now.weekday - 1) % 7;
      final blockedHours = weeklySchedule[day] ?? {};
      if (!blockedHours.contains(now.hour)) return false;
    }
    final lowerUrl = url.toLowerCase();
    for (final site in blockedSites) {
      if (lowerUrl.contains(site.toLowerCase())) {
        for (final film in syllabusFilms) {
          if (lowerUrl.contains(film.toLowerCase().replaceAll(' ', ''))) return false;
        }
        return true;
      }
    }
    return false;
  }
}
