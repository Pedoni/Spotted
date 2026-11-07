import 'package:http/http.dart' as http;

/// Client HTTP che interrompe le richieste che non rispondono entro [timeout]
/// (lancia `TimeoutException`), così la UI non resta in attesa all'infinito.
class TimeoutClient extends http.BaseClient {
  TimeoutClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 15),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeout);
  }

  @override
  void close() => _inner.close();
}
