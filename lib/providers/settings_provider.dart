import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { none, owner, client }

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _shopName = 'My Boutique';
  String _shopDescription = '';
  String _supabaseUrl = '';
  String _supabaseAnonKey = '';
  UserRole _userRole = UserRole.none;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  String get shopName => _shopName;
  String get shopDescription => _shopDescription;
  String get supabaseUrl => _supabaseUrl;
  String get supabaseAnonKey => _supabaseAnonKey;
  UserRole get userRole => _userRole;
  bool get isInitialized => _isInitialized;
  bool get isOwner => _userRole == UserRole.owner;
  bool get isClient => _userRole == UserRole.client;
  bool get hasRole => _userRole != UserRole.none;
  bool get isCloudConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _shopName = prefs.getString('shopName') ?? 'My Boutique';
    _shopDescription = prefs.getString('shopDescription') ?? '';
    _supabaseUrl = prefs.getString('supabaseUrl') ?? '';
    _supabaseAnonKey = prefs.getString('supabaseAnonKey') ?? '';
    final roleIndex = prefs.getInt('userRole') ?? 0;
    _userRole = UserRole.values[roleIndex];
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setUserRole(UserRole role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userRole', role.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setShopName(String name) async {
    _shopName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', name);
    notifyListeners();
  }

  Future<void> setShopDescription(String description) async {
    _shopDescription = description;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopDescription', description);
    notifyListeners();
  }

  Future<void> setSupabaseConfig(String url, String anonKey) async {
    _supabaseUrl = url;
    _supabaseAnonKey = anonKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabaseUrl', url);
    await prefs.setString('supabaseAnonKey', anonKey);
    notifyListeners();
  }
}
