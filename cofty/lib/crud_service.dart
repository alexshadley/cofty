import 'package:http/http.dart' as http;

class CrudService {
  final _httpClient;

  CrudService(http.BaseClient httpClient) : _httpClient = httpClient;
}
