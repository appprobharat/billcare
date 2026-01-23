import 'package:billcare/clients/add.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/clients/model.dart';

class ManageClientPage extends StatefulWidget {
  const ManageClientPage({super.key});

  @override
  State<ManageClientPage> createState() => _ManageClientPageState();
}

class _ManageClientPageState extends State<ManageClientPage> {
  // To store the list of all clients
  List<ClientModel> _allClients = [];
  // To store the filtered list for the search bar
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterClients);
    _searchController.dispose();
    super.dispose();
  }

  // Fetches the client list from the API
  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    try {
      if (token == null) {
        throw Exception("Auth token not found.");
      }
      final List<dynamic> clientData = await ApiService.getClientList(token);
      final List<ClientModel> clients = clientData
          .map((json) => ClientModel.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _allClients = clients;
          _filteredClients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Failed to load clients. Please check your connection.";
        });
      }
      print("Error fetching clients: $e");
    }
  }

  // Filters the client list based on the search query
  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _allClients.where((client) {
        // Search by name or contact number
        return client.clientName.toLowerCase().contains(query) ||
            client.contactNo.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Handles navigation to AddClientPage and refreshes the list upon return
  void _navigateToAddClientPage() async {
    // Assuming AddClientPage is correct as imported
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddClientPage()),
    );
    // If a client was added successfully, refresh the list
    if (result == true) {
      _fetchClients();
    }
  }

  // Handles navigation to EditClientPage and refreshes the list upon return
  void _navigateToEditClientPage(ClientModel client) async {
    final result = await Navigator.push(
      context,
      // Passing client.id for editing
      MaterialPageRoute(
        builder: (context) => AddClientPage(clientId: client.id),
      ),
    );

    if (result == true) {
      _fetchClients();
    }
  }

  // Helper method to build the main content based on state
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_filteredClients.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "No clients found."
              : "No matching clients found.",
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredClients.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return _buildClientCard(client);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Manage Clients")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or mobile no.",
                prefixIcon: const Icon(Icons.search, size: 16),

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),

          Expanded(child: _buildBodyContent()),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => _navigateToAddClientPage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add New Client',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    // Check if clientPhotoUrl is valid
    final hasImage =
        client.clientPhotoUrl != null &&
        (client.clientPhotoUrl?.isNotEmpty ?? false);

    // Helper function to capitalize and bold the first letter of each word
    List<TextSpan> createBoldFirstLetterSpans(String name) {
      final words = name.split(' ');
      final List<TextSpan> spans = [];

      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        if (word.isEmpty) continue;

        final firstLetter = word[0].toUpperCase();
        final remainingLetters = word.substring(1).toLowerCase();
        final isLastWord = i == words.length - 1;

        spans.add(
          TextSpan(
            text: firstLetter,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

        spans.add(
          TextSpan(
            text: remainingLetters + (isLastWord ? '' : ' '),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
      return spans;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEditClientPage(client),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Photo/Placeholder with NetworkImage Error Handling
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey.withOpacity(0.1),
                child: hasImage
                    ? ClipOval(
                        child: Image.network(
                          client.clientPhotoUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 22,
                              color: Colors.blueGrey,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 22,
                        color: Colors.blueGrey,
                      ),
              ),

              const SizedBox(width: 20),

              // Client Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Client Name (Left) | Client Type (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client Name
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: createBoldFirstLetterSpans(
                                client.clientName,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Client Type
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: client.type == 'Party'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            client.type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: client.type == 'Party'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // ✅ UPDATED Row 2: Mobile and GSTIN in one row with small font
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Mobile
                        Flexible(
                          flex: client.gstin.isNotEmpty
                              ? 5
                              : 1, // If no GSTIN, take full space
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 11, // Small font size
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                const TextSpan(
                                  text: 'Mob: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: client.contactNo),
                              ],
                            ),
                            maxLines: 1, // Ensure it stays in one row
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 2. GSTIN (Only show if not empty)
                        if (client.gstin.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6, // Gives GSTIN more space
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontSize: 11, // Small font size
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'GST: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: client.gstin),
                                ],
                              ),
                              textAlign: TextAlign.end, // Align to the right
                              maxLines: 1, // Ensure it stays in one row
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    // State:
                    if (client.state.isNotEmpty)
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'State: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: client.state),
                          ],
                        ),
                      ),

                    const SizedBox(height: 2),

                    // Address:
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Address: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: client.address),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
