import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkMonitor {
  static const String _pingUrl = 'https://www.google.com';
  static const int _pingTimeoutMs = 3000;

  Future<bool> isConnected() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<int> measurePing() async {
    try {
      final start = DateTime.now();
      final response = await http
          .head(Uri.parse(_pingUrl))
          .timeout(const Duration(milliseconds: _pingTimeoutMs));
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      return response.statusCode == 200 ? elapsed : 9999;
    } catch (_) {
      return 9999;
    }
  }

  Future<bool> isCloudViable() async {
    if (!await isConnected()) return false;
    final ping = await measurePing();
    return ping <= 500;
  }
}
