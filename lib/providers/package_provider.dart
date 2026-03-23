import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageProvider extends ChangeNotifier {
  bool _isSuperAdmin = false;
  String _appVersion = "1.0.0";
  String _buildNumber = "0";

  bool get isSuperAdmin => _isSuperAdmin;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;

  Future getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _isSuperAdmin = packageInfo.packageName == "com.haflaway.super_admin_app";
    _appVersion = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;
    notifyListeners();
  }
}
