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
    debugPrint("Current Package Name: ${packageInfo.packageName}");
    _isSuperAdmin =
        packageInfo.packageName.contains("com.haflaway.super_admin_app") ||
        packageInfo.packageName.contains("com.haflaway.admin");
    _appVersion = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;
    notifyListeners();
  }
}
