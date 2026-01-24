import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billcare/clients/model.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = "https://gst.billcare.in/api";

  static Map<String, String> _headers({String? token, String? contentType}) {
    return {
      if (contentType != null) 'Content-Type': contentType,
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
            headers: _headers(contentType: 'application/json'),
            body: json.encode({"username": username, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);
        return data;
      } else {
        return {"status": false, "message": "Login failed (${res.statusCode})"};
      }
    } catch (e) {
      return {"status": false, "message": "Network error: $e"};
    }
  }

  // Save Token API
  static Future<Map<String, dynamic>> saveToken(
    String token,
    String authToken,
  ) async {
    final url = Uri.parse("$baseUrl/save_token");

    try {
      final res = await http
          .post(
            url,
            headers: _headers(
              token: authToken,
              contentType: 'application/json',
            ),
            body: json.encode({"fcm_token": token}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.body.isEmpty) {
        return {"status": false, "message": "Empty response"};
      }

      return json.decode(res.body);
    } catch (e) {
      return {"status": false, "message": "Token save error: $e"};
    }
  }

  static Future<List<StateModel>> getStates(String token) async {
    final url = Uri.parse("$baseUrl/get_state");
    print("Calling API for states: $url");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<List<BankModel>> getBank(String token) async {
    final url = Uri.parse("$baseUrl/get_bank");
    print("Calling API for banks: $url");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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
  static Future<List<dynamic>> getClientList(String token) async {
    final url = Uri.parse("$baseUrl/client/list");
    print("Fetching client list...");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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
  static Future<Map<String, dynamic>?> getClientDetails(
    String clientId,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/client/edit');
    print("Fetching client details for ID: $clientId");
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<Map<String, dynamic>?> fetchSaleForEdit(
    String authToken,
    int saleId,
  ) async {
    final url = Uri.parse("$baseUrl/sale/edit");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'SaleId': saleId}),
      );

      print('Edit Sale API Response Status: ${response.statusCode}');
      print('Edit Sale API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        print(
          'Failed to load sale data for editing. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error during API call: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchPurchaseForEdit(
    String authToken,
    int purchaseId,
  ) async {
    final url = Uri.parse("$baseUrl/purchase/edit");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'PurchaseId': purchaseId}),
      );

      print('Edit Purchase API Response Status: ${response.statusCode}');
      print('Edit Purchase API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        print(
          'Failed to load sale data for editing. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error during API call: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchSaleDetails(
    String authToken,
    int saleId,
  ) async {
    final url = Uri.parse('$baseUrl/sale/edit');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
    final body = jsonEncode({'SaleId': saleId});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("API Error: $e");
      return null;
    }
  }

  // Store Client API (Multipart)
  static Future<bool> storeClient(
    Map<String, String> clientData,
    String token,
    File? clientImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/client/store"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      clientData.forEach((key, value) {
        request.fields[key] = value;
      });
      if (clientImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Photo', clientImage.path),
        );
      }
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Store Client API Response Status: ${response.statusCode}');
      print('Store Client API Response Body: $responseBody');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving client: $e');
      return false;
    }
  }

  // Update Client API (Multipart)
  static Future<bool> updateClient(
    String clientId,
    Map<String, String> clientData,
    String token,
    File? clientImage,
  ) async {
    final url = Uri.parse("$baseUrl/client/update");
    if (clientId.isEmpty || clientId == "0") {
      print("❌ Invalid ClientId provided! Update aborted.");
      return false;
    }
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_headers(token: token));
      request.fields['ClientId'] = clientId;
      request.fields.addAll(clientData);
      if (clientImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Image', clientImage.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Update Client API status: ${response.statusCode}");
      print("Update Client API response: $responseBody");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("⚠️ Exception while updating client: $e");
      return false;
    }
  }

  // Items Section
  static Future<List<Map<String, dynamic>>> fetchCategories(
    String token,
  ) async {
    final url = Uri.parse("$baseUrl/get_category");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<List<dynamic>> fetchCategoryList(String token) async {
    final url = Uri.parse('$baseUrl/category/list');

    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<void> storeCategory(String token, String name) async {
    final url = Uri.parse('$baseUrl/category/store');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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
  static Future<void> updateCategory(
    String token,
    int categoryId,
    String newName,
  ) async {
    final url = Uri.parse('$baseUrl/category/update');

    if (categoryId <= 0) {
      throw ArgumentError('Invalid CategoryId provided for update.');
    }

    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<List<Map<String, dynamic>>> getClients(String token) async {
    final url = Uri.parse("$baseUrl/get_client");

    try {
      final res = await http
          .post(
            url,
            headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<List<dynamic>> fetchItems(String token) async {
    final url = Uri.parse("$baseUrl/get_item");
    print("API Request: Attempting to POST to $url");
    print(
      "Headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}",
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}),
      );

      print("API Response: Status Code ${res.statusCode}");
      print("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          print("Response format is a List.");
          return data;
        } else if (data is Map && data['data'] is List) {
          print("Response format is a Map with a 'data' key.");
          return data['data'] as List;
        }
        print("❌ Error: Invalid data format from API.");
        throw Exception("Invalid data format from API.");
      }
      print("❌ Error: API returned a non-200 status code.");
      throw Exception(
        "Failed to fetch items with status code: ${res.statusCode}",
      );
    } on http.ClientException catch (e) {
      print("❌ Network Error (ClientException): $e");
      throw Exception("Network error while fetching items: $e");
    } on SocketException catch (e) {
      print("❌ Network Error (SocketException): $e");
      throw Exception("No internet connection while fetching items: $e");
    } on Exception catch (e) {
      print("❌ General Error: $e");
      rethrow;
    }
  }

  // In your api_service.dart file
  static Future<Map<String, dynamic>?> postSaleData(
    Map<String, dynamic> data,
    String authToken,
  ) async {
    final url = Uri.parse('$baseUrl/sale/store');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      print("🚀 **Sending Data (JSON Payload):** ${json.encode(data)}");
      print("🚀 Data being sent to /sale/store: ${json.encode(data)}");
      print(
        "🔑 Authorization Token (Bearer part only): ${authToken.substring(0, 5)}...",
      );
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Sale saved successfully! Response: ${response.body}");
        // Decode and return the response body, which should contain the SaleId
        return json.decode(response.body);
      } else {
        print("❌ Failed to save sale. Status: ${response.statusCode}");
        print("Response Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error during API call: $e");
      return null;
    }
  }

  //manage page ki sale list
  // Remove the try-catch block
  static Future<List<dynamic>> fetchSales(
    String authToken,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/sale/list');
    final headers = _headers(token: authToken, contentType: 'application/json');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    print("API Response - Status Code: ${response.statusCode}");
    print("API Response - Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> sales = json.decode(response.body);
      return sales;
    } else {
      // Handle the error based on the API response
      final errorResponse = json.decode(response.body);
      throw Exception(errorResponse['message'] ?? 'Failed to load sales data');
    }
  }

  static Future<List<dynamic>> fetchPurchases(
    String authToken,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/purchase/list');
    final headers = _headers(token: authToken, contentType: 'application/json');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    print("API Response - Status Code: ${response.statusCode}");
    print("API Response - Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> sales = json.decode(response.body);
      return sales;
    } else {
      // Handle the error based on the API response
      final errorResponse = json.decode(response.body);
      throw Exception(errorResponse['message'] ?? 'Failed to load sales data');
    }
  }

  // Unit Section
  static Future<List<Map<String, dynamic>>> getUnit(String token) async {
    final url = Uri.parse("$baseUrl/get_unit");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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
  static Future<List<dynamic>> fetchItemList(String token) async {
    final url = Uri.parse("$baseUrl/item/list");
    final response = await http.post(
      url,
      headers: _headers(token: token, contentType: 'application/json'),
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

  static Future<List<dynamic>> fetchClients(String token) async {
    final url = Uri.parse("$baseUrl/get_client");
    print("🟡 Attempting to fetch clients from URL: $url");
    try {
      final res = await http.post(
        url,
        headers: _headers(token: token, contentType: 'application/json'),
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
    required String token,
  }) async {
    // 💡 NOTE: The URL in the Multi-part request must be correct.
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://gst.billcare.in/api/item/update',
      ), // <--- Your Update URL
    );

    try {
      // 1. Add Authorization Header
      request.headers['Authorization'] = 'Bearer $token';

      // 2. Add all text fields (Item Data)
      request.fields.addAll(itemData);

      if (imageFile != null) {
        print("🖼️ Attaching NEW image: ${imageFile.path}");

        request.files.add(
          await http.MultipartFile.fromPath('Image', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("✅ API Update Status: ${response.statusCode}");
      print("✅ API Update Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error updating item with image: $e");
      return false;
    }
  }

  static Future<bool> storeData(
    Map<String, dynamic> userInput,

    File? imageFile,
    String token,
  ) async {
    final Map<String, String> itemData = userInput.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/item/store'),
    );

    try {
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(itemData);

      // 5. Add the Image File (if available)
      if (imageFile != null) {
        print("🖼️ Attaching image: ${imageFile.path}");

        // CRITICAL: 'Image' is the field name your backend must be expecting for the file.
        request.files.add(
          await http.MultipartFile.fromPath('Image', imageFile.path),
        );
      }

      // 6. Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Debugging logs
      print("✅ API Response Status: ${response.statusCode}");
      print("✅ API Response Body: ${response.body}");

      // 7. Check the status code
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error storing data with image: $e");
      return false;
    }
  }

  static Future<bool> updateSale(
    String authToken,
    Map<String, dynamic> saleData,
  ) async {
    final url = Uri.parse("$baseUrl/sale/update");

    var request = http.MultipartRequest('POST', url);

    // Add Authorization header
    request.headers['Authorization'] = 'Bearer $authToken';

    // Loop through the data map to build the form fields
    saleData.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          request.fields['$key[$i]'] = value[i].toString();
        }
      } else {
        // If it's a simple value, add it directly.
        request.fields[key] = value.toString();
      }
    });

    try {
      print("Sending Update Sale Request...");
      // You can print the fields to debug and see how they are formatted
      print("Request Fields: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Sale API Response Status: ${response.statusCode}');
      print('Update Sale API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update sale.');
        return false;
      }
    } catch (e) {
      print('Error during updateSale API call: $e');
      return false;
    }
  }
  //purchase api code here..

  static Future<bool> updatePurchase(
    String authToken,
    Map<String, dynamic> purchaseData,
  ) async {
    final url = Uri.parse("$baseUrl/purchase/update");

    var request = http.MultipartRequest('POST', url);

    // Add Authorization header
    request.headers['Authorization'] = 'Bearer $authToken';

    // Loop through the data map to build the form fields
    purchaseData.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          request.fields['$key[$i]'] = value[i].toString();
        }
      } else {
        // If it's a simple value, add it directly.
        request.fields[key] = value.toString();
      }
    });

    try {
      print("Sending Update Sale Request...");
      // You can print the fields to debug and see how they are formatted
      print("Request Fields: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Purchase API Response Status: ${response.statusCode}');
      print('Update Purchase API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update purchase.');
        return false;
      }
    } catch (e) {
      print('Error during updatePurchase API call: $e');
      return false;
    }
  }

  // static Future<Map<String, dynamic>?> postPurchaseData(
  //   Map<String, dynamic> data,
  //   String authToken,
  // ) async {
  //   final url = Uri.parse('$baseUrl/purchase/store');
  //   final headers = {'Authorization': 'Bearer $authToken'};

  //   try {
  //     print("🟢 DEBUG: Purchase Request Body => $data");

  //     final response = await http.post(
  //       url,
  //       headers: headers,
  //       body: data.map((key, value) {
  //         if (value is List) {
  //           return MapEntry(key, value.map((v) => v.toString()).toList());
  //         } else {
  //           return MapEntry(key, value.toString());
  //         }
  //       }),
  //     );

  //     print(
  //       "🟢 DEBUG: Purchase Response [${response.statusCode}] => ${response.body}",
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return jsonDecode(response.body);
  //     } else {
  //       print("🔴 ERROR: Purchase failed with status ${response.statusCode}");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("🔴 EXCEPTION in postPurchaseData: $e");
  //     return null;
  //   }
  // }

  static Future<Map<String, dynamic>?> postPurchaseData(
    Map<String, dynamic> data,
    String authToken,
  ) async {
    final url = Uri.parse('$baseUrl/purchase/store');
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Accept'] = 'application/json';

      print("🟢 DEBUG: Preparing Purchase FormData...");

      // ✅ Add simple fields
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

      // ✅ Helper for array fields (Laravel expects "key[0]", "key[1]", etc.)
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

      print("🧾 Final FormData to API:");
      request.fields.forEach((key, value) => print("$key => $value"));

      // ✅ Send request
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      print("🟢 DEBUG: Purchase Response [${response.statusCode}] => $resBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(resBody);
      } else {
        print("🔴 ERROR: Purchase failed with status ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🔴 EXCEPTION in postPurchaseData: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchPrintPurchaseDetails(
    String authToken,
    int purchaseId,
  ) async {
    final url = Uri.parse('$baseUrl/purchase/print');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
    final body = json.encode({'PurchaseId': purchaseId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody;
    } else {
      throw Exception(
        'Failed to fetch Purchase details. Status code: ${response.statusCode}',
      );
    }
  }

  //printing
  static Future<Map<String, dynamic>> fetchPrintSaleDetails(
    String authToken,
    int saleId,
  ) async {
    final url = Uri.parse('$baseUrl/sale/print');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
    final body = json.encode({'SaleId': saleId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody;
    } else {
      throw Exception(
        'Failed to fetch sale details. Status code: ${response.statusCode}',
      );
    }
  }

  //
  static Future<List<dynamic>> getNames(String token, String type) async {
    final url = Uri.parse("$baseUrl/get_name");
    print("Fetching client name list for type: $type...");
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/x-www-form-urlencoded', // ✅ Use URL-encoded type
          'Authorization': 'Bearer $token',
        },
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
    String token,
    String type,
    int receiptId,
  ) async {
    final url = Uri.parse("$baseUrl/receipt/print");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {'ReceiptId': receiptId.toString(), 'type': type},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Receipt data fetched successfully.');
        return data;
      } else {
        debugPrint(
          'Failed to get receipt data. Status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error during getReceiptData API call: $e');
      return null;
    }
  }

  //print
  static Future<Map<String, dynamic>?> getPaymentData(
    String token,
    String type,
    int paymentId,
  ) async {
    final url = Uri.parse("$baseUrl/payment/print");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {'PaymentId': paymentId.toString(), 'type': type},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Payment data fetched successfully.');
        return data;
      } else {
        debugPrint(
          'Failed to get payment data. Status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error during getPaymentData API call: $e');
      return null;
    }
  }

  //get balance
  static Future<double> getBalance(String token, String type, int id) async {
    final url = Uri.parse("$baseUrl/get_balance");

    try {
      final response = await http.post(
        url,
        headers: {
          // Change Content-Type to form-urlencoded
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
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

  static Future<dynamic> getReceiptForEdit(
    String token,
    int receiptId,
    String type,
  ) async {
    final url = Uri.parse('$baseUrl/receipt/edit');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  static Future<bool> storeReceipt(
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$baseUrl/receipt/store");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/x-www-form-urlencoded', // ✅ Use URL-encoded type
          'Authorization': 'Bearer $token',
        },
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

  static Future<bool> updateReceipt(
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/receipt/update');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
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
    required String authToken,
    required int saleId,
    required String fileName,
  }) async {
    final url = Uri.parse('$baseUrl/sales/generate-pdf/$saleId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          // Assuming your API returns application/pdf
        },
      );

      if (response.statusCode == 200) {
        // 1. Get the device's temporary directory for file storage
        final directory = await getTemporaryDirectory();

        // 2. Create the complete file path
        final file = File('${directory.path}/$fileName');

        // 3. Write the raw API response body (the PDF bytes) to the file
        await file.writeAsBytes(response.bodyBytes);

        // 4. Return the local path
        return file.path;
      } else {
        // Handle API errors (e.g., 404 Not Found, 500 Server Error)
        print('Failed to generate PDF. Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network or File writing error: $e');
      return null;
    }
  }
}
