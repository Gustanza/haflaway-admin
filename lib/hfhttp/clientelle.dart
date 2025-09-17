import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class HttpService extends http.BaseClient {
  final String token = FirebaseAuth.instance.currentUser?.uid ?? "_id";
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = "Bearer $token";
    return _client.send(request);
  }
}
