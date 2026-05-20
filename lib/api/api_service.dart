import 'dart:convert';
import 'dart:io';
import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billcare/admin/clients/model.dart';
import 'package:path_provider/path_provider.dart';

class AppColors {
  static const primary = Color(0xFF1E3A8A);
}

class ApiService {
  static const String baseUrl = "https://gst.billcare.in/api";
  static Future<dynamic> postRequest({
    required String endpoint,
    Map<String, dynamic>? body,
    bool isJson = false,
  }) async {
    try {
      final url = Uri.parse(baseUrl + endpoint);

      final headers = await authHeaders(
        contentType: isJson
            ? 'application/json'
            : 'application/x-www-form-urlencoded',
      );

      /// 🔥 DEBUG PRINT (IMPORTANT)
      debugPrint("🌐 API URL: $url");
      debugPrint("📤 BODY: $body");
      debugPrint("🔑 HEADERS: $headers");

      final response = await http.post(
        url,
        headers: headers,
        body: isJson ? jsonEncode(body ?? {}) : body ?? {},
      );

      /// 🔥 RESPONSE DEBUG
      debugPrint("📥 STATUS: ${response.statusCode}");
      debugPrint("📥 RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await AuthStorage.logout(); // 🔐 token expire
        return null;
      } else {
        debugPrint("❌ API ERROR ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ EXCEPTION: $e");
      return null;
    }
  }

  static Future<Map<String, String>> authHeaders({String? contentType}) async {
    final token = await AuthStorage.getToken();
    return {
      if (contentType != null) 'Content-Type': contentType,
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> multipartRequest({
    required String endpoint,
    required Map<String, dynamic> fields,
    File? file,
    fileField = "Photo",
  }) async {
    try {
      final url = Uri.parse(baseUrl + endpoint);

      final headers = await authHeaders();

      var request = http.MultipartRequest("POST", url);

      request.headers.addAll(headers);

      request.fields.addAll(fields.map((k, v) => MapEntry(k, v.toString())));

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, file.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📤 MULTIPART BODY: $fields");
      print("📥 RESPONSE: $responseBody");

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else if (response.statusCode == 401) {
        await AuthStorage.logout();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print("❌ MULTIPART ERROR: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final res = await http
          .post(
            url,
            headers: const {'Accept': 'application/json'},
            body: {"username": username, "password": password},
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("STATUS CODE: ${res.statusCode}");
      debugPrint("BODY: ${res.body}");

      final data = json.decode(res.body);

      return {
        "status": data["status"] ?? false,
        "message": data["message"] ?? "Login failed",
        "token": data["token"],
        "profile": data["profile"],
        "type": data["type"],
      };
    } catch (e) {
      return {"status": false, "message": "Network error"};
    }
  }

  // Save Token API
  static Future<Map<String, dynamic>> saveToken(String fcmToken) async {
    final url = Uri.parse("$baseUrl/save_token");

    try {
      final res = await http
          .post(
            url,
            headers: await authHeaders(contentType: 'application/json'),
            body: json.encode({"fcm_token": fcmToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.body.isEmpty) {
        return {"status": false, "message": "Empty response from server"};
      }

      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {"status": false, "message": "Token save error: $e"};
    }
  }

  static Future<List<StateModel>> getStates() async {
    final url = Uri.parse("$baseUrl/get_state");
    print("Calling API for states: $url");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );
      print("States API Response Status Code: ${res.statusCode}");
      print("States API Response Body: ${res.body}");
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          return data
              .map<StateModel>((json) => StateModel.fromJson(json))
              .toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map<StateModel>((json) => StateModel.fromJson(json))
              .toList();
        }
        print("States API: Received data is not in expected format.");
        return [];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching states: $e");
      return [];
    }
  }

  static Future<List<BankModel>> getBank() async {
    final url = Uri.parse("$baseUrl/get_bank");
    print("Calling API for banks: $url");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );
      print("Banks API Response Status Code: ${res.statusCode}");
      print("Banks API Response Body: ${res.body}");
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          return data
              .map<BankModel>((json) => BankModel.fromJson(json))
              .toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map<BankModel>((json) => BankModel.fromJson(json))
              .toList();
        }
        print("Banks API: Received data is not in expected format.");
        return [];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching banks: $e");
      return [];
    }
  }

  // Get Client List API
  static Future<List<dynamic>> getClientList() async {
    final url = Uri.parse("$baseUrl/client/list");
    print("Fetching client list...");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );
      print("Client List API Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          return data;
        } else if (data is Map && data['data'] is List) {
          print("Client List data found.");
          return data['data'] as List;
        }
        print("Client List API: Received data is not in expected format.");
        return [];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching clients: $e");
      return [];
    }
  }

  // Get Client Details for Edit API
  static Future<Map<String, dynamic>?> getClientDetails(String clientId) async {
    final url = Uri.parse('$baseUrl/client/edit');
    print("Fetching client details for ID: $clientId");
    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: jsonEncode({"ClientId": clientId}),
      );
      print("Client Details API Status: ${response.statusCode}");
      print("Client Details API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          print("Client Details API: Received data is not in expected format.");
          return null;
        }
      } else {
        print('Error fetching client details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in getClientDetails: $e');
      return null;
    }
  }

  static Future<bool> updateItem(Map<String, dynamic> data, File? image) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.baseUrl}/item/update"),
      );

      request.fields.addAll(
        data.map((key, value) => MapEntry(key, value.toString())),
      );

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath("Image", image.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      print("Update Item Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchSaleForEdit(int saleId) async {
    final url = Uri.parse("$baseUrl/sale/edit");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: jsonEncode({'SaleId': saleId}),
      );

      debugPrint('Edit Sale API Status: ${response.statusCode}');
      debugPrint('Edit Sale API Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // optional but recommended
        await AuthStorage.logout();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ fetchSaleForEdit error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchPurchaseForEdit(
    int purchaseId,
  ) async {
    final url = Uri.parse("$baseUrl/purchase/edit");

    final res = await http.post(
      url,
      headers: await authHeaders(), // 🔥 token inside
      body: jsonEncode({"PurchaseId": purchaseId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    if (res.statusCode == 401) {
      await AuthStorage.logout();
    }

    throw Exception("Failed to fetch purchase");
  }

  static Future<Map<String, dynamic>?> fetchSaleDetails(int saleId) async {
    final url = Uri.parse('$baseUrl/sale/edit');

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: jsonEncode({'SaleId': saleId}),
      );

      debugPrint("📥 Sale Details Status: ${response.statusCode}");
      debugPrint("📥 Sale Details Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired / invalid
        await AuthStorage.logout();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("❌ fetchSaleDetails error: $e");
      return null;
    }
  }

  // Store Client API (Multipart)
  static Future<bool> storeClient(
    Map<String, String> clientData,
    File? clientImage,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/client/store"),
      );

      // ✅ Auth header from SecureStorage
      final headers = await authHeaders();
      request.headers.addAll(headers);

      // ✅ Add fields
      request.fields.addAll(clientData);

      // ✅ Add image if exists
      if (clientImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Photo', clientImage.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Store Client API Status: ${response.statusCode}');
      debugPrint('Store Client API Response: $responseBody');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error saving client: $e');
      return false;
    }
  }

  // Update Client API (Multipart)
  static Future<bool> updateClient(
    String clientId,
    Map<String, String> clientData,
    File? clientImage,
  ) async {
    final url = Uri.parse("$baseUrl/client/update");

    if (clientId.isEmpty || clientId == "0") {
      debugPrint("❌ Invalid ClientId provided! Update aborted.");
      return false;
    }

    try {
      final request = http.MultipartRequest('POST', url);

      // ✅ Auth header from SecureStorage
      final headers = await ApiService.authHeaders();
      request.headers.addAll(headers);

      request.fields['ClientId'] = clientId;
      request.fields.addAll(clientData);

      if (clientImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Image', clientImage.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint("Update Client API status: ${response.statusCode}");
      debugPrint("Update Client API response: $responseBody");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("⚠️ Exception while updating client: $e");
      return false;
    }
  }

  // Items Section
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final url = Uri.parse("$baseUrl/get_category");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['categories'] is List) {
          return List<Map<String, dynamic>>.from(data['categories']);
        }
        return [];
      } else {
        throw Exception(
          "Failed to fetch categories. Status: ${res.statusCode}",
        );
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
      return [];
    }
  }

  static Future<List<dynamic>> fetchCategoryList() async {
    final url = Uri.parse('$baseUrl/category/list');

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
      );

      print("🟢 Category List API Status: ${response.statusCode}");
      print("🟢 Category List API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data['data'] is List) {
          return data['data'] as List;
        } else if (data is List) {
          return data;
        } else {
          print("❌ Unexpected format: $data");
          return [];
        }
      } else {
        print("❌ Failed to load categories: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
      return [];
    }
  }

  static Future<void> storeCategory(String name) async {
    final url = Uri.parse('$baseUrl/category/store');
    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({'Name': name}),
      );

      print('Store Category API Status: ${response.statusCode}');
      print('Store Category API Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to add category: ${response.body}');
      }
      // Handle success, maybe return a success message or the created object
    } catch (e) {
      print('❌ Error adding category: $e');
      rethrow;
    }
  }

  // New method for updating a category
  static Future<void> updateCategory(int categoryId, String newName) async {
    final url = Uri.parse('$baseUrl/category/update');

    if (categoryId <= 0) {
      throw ArgumentError('Invalid CategoryId provided for update.');
    }

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({'CategoryId': categoryId, 'Name': newName}),
      );

      print('Update Category API Status: ${response.statusCode}');
      print('Update Category API Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update category: ${response.body}');
      }
      // Handle success
    } catch (e) {
      print('❌ Error updating category: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getClients() async {
    final url = Uri.parse("$baseUrl/get_client");

    try {
      final res = await http
          .post(
            url,
            headers: await authHeaders(contentType: 'application/json'),

            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching clients: $e");
      return [];
    }
  }

  //for adding addnewsaleitem in sales

  static Future<List<dynamic>> fetchItems() async {
    final url = Uri.parse("$baseUrl/get_item");

    debugPrint("📡 Fetching items from $url");

    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: json.encode({}),
      );

      debugPrint("📥 Status Code: ${res.statusCode}");
      debugPrint("📥 Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data is List) {
          return data;
        } else if (data is Map && data['data'] is List) {
          return data['data'] as List;
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Failed to fetch items (${res.statusCode})");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } catch (e) {
      debugPrint("❌ fetchItems error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> postSaleData(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/sale/store');

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: jsonEncode(data),
      );

      debugPrint("📤 Sale Store Status: ${response.statusCode}");
      debugPrint("📤 Sale Store Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired / invalid
        await AuthStorage.logout();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("❌ postSaleData error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> fetchSales(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/sale/list');

    final headers = await authHeaders(contentType: 'application/json');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      final errorResponse = json.decode(response.body);
      throw Exception(errorResponse['message'] ?? 'Failed to load sales data');
    }
  }

  static Future<List<dynamic>> fetchPurchases(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/purchase/list');

    final headers = await authHeaders(contentType: 'application/json');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    debugPrint("API Response - Status Code: ${response.statusCode}");
    debugPrint("API Response - Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      final errorResponse = json.decode(response.body);
      throw Exception(
        errorResponse['message'] ?? 'Failed to load purchase data',
      );
    }
  }

  // Unit Section
  static Future<List<Map<String, dynamic>>> getUnit() async {
    final url = Uri.parse("$baseUrl/get_unit");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['unit'] is List) {
          return List<Map<String, dynamic>>.from(data['unit']);
        }
        return [];
      } else {
        throw Exception("Failed to fetch units. Status: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching units: $e");
      return [];
    }
  }

  // Fetch all items
  static Future<List<dynamic>> fetchItemList() async {
    final url = Uri.parse("$baseUrl/item/list");
    final response = await http.post(
      url,
      headers: await authHeaders(contentType: 'application/json'),

      body: json.encode({}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map && data['data'] is List) {
        return data['data'] as List;
      }
      return [];
    } else {
      throw Exception("Failed to load items");
    }
  }

  static Future<List<dynamic>> fetchClients() async {
    final url = Uri.parse("$baseUrl/get_client");
    print("🟡 Attempting to fetch clients from URL: $url");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),

        body: json.encode({}),
      );

      print("🟢 API response received with status code: ${res.statusCode}");
      print("📄 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        print("🔍 Decoding JSON data.");
        if (data is List) {
          print("✅ Data is a List. Returning list of clients.");
          return data;
        } else if (data is Map && data['data'] is List) {
          print("✅ Data is a Map with a 'data' key. Returning the list.");
          return data['data'] as List;
        }
        print(
          "❌ Error: Invalid client data format from API. Expected a List or a Map with a 'data' key.",
        );
        throw Exception("Invalid client data format from API.");
      }
      print(
        "❌ Error: Failed to fetch clients with status code: ${res.statusCode}",
      );
      throw Exception(
        "Failed to fetch clients with status code: ${res.statusCode}",
      );
    } on http.ClientException catch (e) {
      print("❌ Network error: $e");
      throw Exception("Network error while fetching clients: $e");
    } on SocketException catch (e) {
      print("❌ No internet connection: $e");
      throw Exception("No internet connection while fetching clients: $e");
    } on Exception catch (e) {
      print("❌ Unknown error fetching clients: $e");
      rethrow;
    }
  }

  static Future<bool> updateItemWithImage({
    required Map<String, String> itemData,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/item/update'),
    );

    try {
      // ✅ Auth headers from SecureStorage
      final headers = await authHeaders();
      request.headers.addAll(headers);

      // ✅ Add text fields
      request.fields.addAll(itemData);

      // ✅ Add image if exists
      if (imageFile != null) {
        debugPrint("🖼️ Attaching image: ${imageFile.path}");
        request.files.add(
          await http.MultipartFile.fromPath('Image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("✅ Update Item Status: ${response.statusCode}");
      debugPrint("✅ Update Item Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ updateItemWithImage error: $e");
      return false;
    }
  }

  static Future<bool> storeData(
    Map<String, dynamic> userInput,
    File? imageFile,
  ) async {
    final Map<String, String> itemData = userInput.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/item/store'),
    );

    try {
      // ✅ Auth headers from SecureStorage
      final headers = await authHeaders();
      request.headers.addAll(headers);

      // ✅ Add form fields
      request.fields.addAll(itemData);

      // ✅ Add image if exists
      if (imageFile != null) {
        debugPrint("🖼️ Attaching image: ${imageFile.path}");
        request.files.add(
          await http.MultipartFile.fromPath('Image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("✅ Store Item Status: ${response.statusCode}");
      debugPrint("✅ Store Item Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ storeData error: $e");
      return false;
    }
  }

  static Future<bool> updateSale(Map<String, dynamic> saleData) async {
    final url = Uri.parse("$baseUrl/sale/update");

    final request = http.MultipartRequest('POST', url);

    try {
      // ✅ Auth headers from SecureStorage
      final headers = await authHeaders();
      request.headers.addAll(headers);

      // ✅ Add form fields
      saleData.forEach((key, value) {
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            request.fields['$key[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      });

      debugPrint("🟡 Update Sale Fields: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🟢 Update Sale Status: ${response.statusCode}");
      debugPrint("🟢 Update Sale Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 401) {
        await AuthStorage.logout(); // 🔐 token expired
      }

      return false;
    } catch (e) {
      debugPrint("❌ updateSale error: $e");
      return false;
    }
  }

  static Future<bool> updatePurchase(Map<String, dynamic> purchaseData) async {
    final url = Uri.parse("$baseUrl/purchase/update");

    final request = http.MultipartRequest('POST', url);

    try {
      // ✅ Auth headers from SecureStorage
      final headers = await authHeaders();
      request.headers.addAll(headers);

      // ✅ Add form fields
      purchaseData.forEach((key, value) {
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            request.fields['$key[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      });

      debugPrint("🟡 Update Purchase Fields: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🟢 Update Purchase Status: ${response.statusCode}");
      debugPrint("🟢 Update Purchase Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 401) {
        await AuthStorage.logout(); // 🔐 token expired
      }

      return false;
    } catch (e) {
      debugPrint("❌ updatePurchase error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchItemForEdit(String itemId) async {
    final url = Uri.parse("$baseUrl/item/edit");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: jsonEncode({"ItemId": itemId}),
      );

      debugPrint("📡 Item Edit Status: ${response.statusCode}");
      debugPrint("📡 Item Edit Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        // 🔐 token expired
        await AuthStorage.logout();
        return null;
      }

      return null;
    } catch (e) {
      debugPrint("❌ fetchItemForEdit error: $e");
      return null;
    }
  }

  static Future<bool> storeIncomeExpenseItem(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/inc_exp/item/store");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: data.map((k, v) => MapEntry(k, v.toString())),
      );

      debugPrint("🟢 Inc/Exp Store Status: ${response.statusCode}");
      debugPrint("🟢 Inc/Exp Store Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 401) {
        await AuthStorage.logout();
      }

      return false;
    } catch (e) {
      debugPrint("❌ storeIncomeExpenseItem error: $e");
      return false;
    }
  }

  static Future<bool> updateIncomeExpenseItem(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/inc_exp/item/update");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: data.map((k, v) => MapEntry(k, v.toString())),
      );

      debugPrint("🟢 Inc/Exp Update Status: ${response.statusCode}");
      debugPrint("🟢 Inc/Exp Update Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 401) {
        await AuthStorage.logout();
      }

      return false;
    } catch (e) {
      debugPrint("❌ updateIncomeExpenseItem error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> postPurchaseData(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/purchase/store');

    try {
      final request = http.MultipartRequest('POST', url);

      // ✅ Auth headers from SecureStorage (SAFE)
      final headers = await authHeaders();
      request.headers.addAll(headers);

      request.headers['Accept'] = 'application/json';

      debugPrint("🟢 Preparing Purchase FormData...");

      // ✅ Simple fields
      final nonListKeys = [
        'Date',
        'ClientId',
        'GrandTotalAmt',
        'IsPaid',
        'PaymentAmt',
        'PaymentMode',
        'Remark',
      ];

      for (final key in nonListKeys) {
        final value = data[key];
        if (value != null) {
          request.fields[key] = value.toString();
        }
      }

      // ✅ Array fields (Laravel format: key[0], key[1])
      void addArrayField(String key, List<dynamic>? list) {
        if (list == null) return;
        for (int i = 0; i < list.length; i++) {
          request.fields['$key[$i]'] = list[i].toString();
        }
      }

      addArrayField('ItemId', data['ItemId']);
      addArrayField('Quantity', data['Quantity']);
      addArrayField('PurchasePrice', data['PurchasePrice']);
      addArrayField('Discount', data['Discount']);
      addArrayField('GSTAmt', data['GSTAmt']);
      addArrayField('TotalAmt', data['TotalAmt']);

      debugPrint("🧾 Purchase FormData:");
      request.fields.forEach((k, v) => debugPrint("$k => $v"));

      // ✅ Send request
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      debugPrint("🟢 Purchase Response [${response.statusCode}] => $resBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(resBody) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired → logout
        await AuthStorage.logout();
        return null;
      } else {
        debugPrint("🔴 Purchase failed");
        return null;
      }
    } catch (e) {
      debugPrint("❌ postPurchaseData error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchPrintPurchaseDetails(
    int purchaseId,
  ) async {
    final url = Uri.parse('$baseUrl/purchase/print');

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: json.encode({'PurchaseId': purchaseId}),
      );

      debugPrint("🧾 Print Purchase Status: ${response.statusCode}");
      debugPrint("🧾 Print Purchase Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired / invalid
        await AuthStorage.logout();
        return null;
      } else {
        debugPrint("❌ Failed to fetch purchase print data");
        return null;
      }
    } catch (e) {
      debugPrint("❌ fetchPrintPurchaseDetails error: $e");
      return null;
    }
  }

  //printing
  static Future<Map<String, dynamic>?> fetchPrintSaleDetails(int saleId) async {
    final url = Uri.parse('$baseUrl/sale/print');

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: json.encode({'SaleId': saleId}),
      );

      debugPrint("🧾 Print Sale Status: ${response.statusCode}");
      debugPrint("🧾 Print Sale Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired → force logout
        await AuthStorage.logout();
        return null;
      } else {
        debugPrint("❌ Failed to fetch sale print data");
        return null;
      }
    } catch (e) {
      debugPrint("❌ fetchPrintSaleDetails error: $e");
      return null;
    }
  }

  //
  static Future<List<dynamic>> getNames(String type) async {
    final url = Uri.parse("$baseUrl/get_name");
    print("Fetching client name list for type: $type...");
    try {
      final res = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: {'Type': type}, // ✅ Pass data as a Map
      );
      print("Client Name List API Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          return data;
        } else if (data is Map && data['data'] is List) {
          return data['data'] as List;
        }
        return [];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching clients: $e");
      return []; // Return empty list on error
    }
  }

  //print
  static Future<Map<String, dynamic>?> getReceiptData(
    String type,
    int receiptId,
  ) async {
    final url = Uri.parse("$baseUrl/receipt/print");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: {'ReceiptId': receiptId.toString(), 'type': type},
      );

      debugPrint("📥 Receipt API Status: ${response.statusCode}");
      debugPrint("📥 Receipt API Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint("❌ Receipt API failed");
        return null;
      }
    } catch (e) {
      debugPrint("❌ getReceiptData error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPaymentData(
    String type,
    int paymentId,
  ) async {
    final url = Uri.parse("$baseUrl/payment/print");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: {'PaymentId': paymentId.toString(), 'type': type},
      );

      debugPrint("📥 Payment API Status: ${response.statusCode}");
      debugPrint("📥 Payment API Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("❌ getPaymentData error: $e");
      return null;
    }
  }

  //get balance
  static Future<double> getBalance(String type, int id) async {
    final url = Uri.parse("$baseUrl/get_balance");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        // ✅ Use a map and URI encode the body instead of jsonEncode
        body: {'Type': type, 'id': id.toString()},
      );

      if (response.statusCode == 200) {
        final balance = double.tryParse(response.body) ?? 0.0;
        print('Balance fetched successfully: $balance');
        return balance;
      } else {
        print('Failed to get balance. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('Error during getBalance API call: $e');
      rethrow;
    }
  }

  static Future<dynamic> getReceiptForEdit(int receiptId, String type) async {
    final url = Uri.parse('$baseUrl/receipt/edit');
    try {
      final response = await http.post(
        url,
        headers: await authHeaders(contentType: 'application/json'),
        body: jsonEncode({'ReceiptId': receiptId, 'type': type}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> &&
            data.containsKey('status') &&
            data['status'] == 'true') {
          if (data.containsKey('data')) {
            return data['data'];
          } else {
            throw Exception('API response is missing the "data" key.');
          }
        } else {
          final errorMessage = data['message'] ?? 'Unknown error';
          throw Exception('Failed to load receipt details: $errorMessage');
        }
      } else {
        throw Exception(
          'Failed to load receipt details. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the API: $e');
    }
  }

  static Future<bool> storeReceipt(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/receipt/store");
    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        // ✅ Convert all values to String for form data
        body: data.map((key, value) => MapEntry(key, value.toString())),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody['message'] == 'Data Stored Successfully';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateReceipt(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/receipt/update');
    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        // Convert the map to a URL-encoded string
        body: data.entries
            .map(
              (e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}',
            )
            .join('&'),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['status'] == 'true';
      } else {
        print('Failed to update receipt. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('An error occurred while updating receipt: $e');
      return false;
    }
  }

  static Future<String?> generateAndSavePdf({
    required int saleId,
    required String fileName,
  }) async {
    final url = Uri.parse('$baseUrl/sales/generate-pdf/$saleId');

    try {
      final response = await http.get(
        url,
        headers: await authHeaders(), // ✅ SecureStorage se token
      );

      debugPrint("📄 PDF Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else if (response.statusCode == 401) {
        // 🔐 Token expired → logout
        await AuthStorage.logout();
        return null;
      } else {
        debugPrint("❌ PDF API failed");
        return null;
      }
    } catch (e) {
      debugPrint("❌ generateAndSavePdf error: $e");
      return null;
    }
  }

  static Future<bool> storeIncomeExpenseCategory({
    required String type,
    required String category,
  }) async {
    final url = Uri.parse("$baseUrl/inc_exp/category/store");

    try {
      final response = await http.post(
        url,
        headers: await authHeaders(
          contentType: 'application/x-www-form-urlencoded',
        ),
        body: {"Type": type, "Category": category},
      );

      debugPrint("🟢 Category Store Status: ${response.statusCode}");
      debugPrint("🟢 Category Store Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 401) {
        await AuthStorage.logout();
      }

      return false;
    } catch (e) {
      debugPrint("❌ storeIncomeExpenseCategory error: $e");
      return false;
    }
  }
}
