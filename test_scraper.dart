import 'package:http/http.dart' as http;

void main() async {
  final _ = await http.get(
    Uri.parse(
      'https://mostaql.com/project/1120867-%D9%85%D8%B7%D9%84%D9%88%D8%A8-%D8%AE%D8%A8%D9%8A%D8%B1-%D9%86%D8%B8%D8%A7%D9%85-odoo',
    ),
  );
  // print(response.body);
}
