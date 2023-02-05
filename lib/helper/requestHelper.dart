import 'dart:convert';

import 'package:http/http.dart' as http;

class RequewstHelper {
  static Future<dynamic> getRequset(String url) async {
    http.Response response = await http.get(url);
    try {
      if (response.statusCode == 200) {
        String data = response.body;
        var decodedData = jsonDecode(data);
        print(decodedData.toString());
        return decodedData;
      } else {
        print("failed");
        return 'failed';
      }
    } catch (e) {
      print(e.toString());
      print("failed");
      return 'failed';
    }
  }
}
