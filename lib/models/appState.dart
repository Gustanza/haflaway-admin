String hAppStateCol = 'hAppStates';

class HAppState {
  String versionName;
  int buildNumber;
  String downloadUrl;

  HAppState({
    required this.versionName,
    required this.buildNumber,
    required this.downloadUrl,
  });

  factory HAppState.fromMap({id, map}) {
    return HAppState(
      versionName: map['versionName'] ?? "",
      downloadUrl: map['downloadUrl'] ?? "",
      buildNumber:
          map['buildNumber'] != null ? (map['buildNumber'] as num).toInt() : 0,
    );
  }
}
