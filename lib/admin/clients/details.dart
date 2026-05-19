import 'package:billcare/admin/clients/add.dart';
import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/admin/clients/model.dart';

class ManageClientPage extends StatefulWidget {
  const ManageClientPage({super.key});

  @override
  State<ManageClientPage> createState() => _ManageClientPageState();
}

class _ManageClientPageState extends State<ManageClientPage> {
  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final List<List<Color>> _headerGradients = [
    [Color(0xfff953c6), Color(0xffb91d73)], // pink
    [Color(0xff43cea2), Color(0xff185a9d)], // teal-blue
    [Color(0xff8E2DE2), Color(0xffC471ED)], // purple
    [Color(0xffff9966), Color(0xffff5e62)], // orange-red
    [Color(0xff36D1DC), Color(0xff5B86E5)], // cyan-blue
  ];
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

    try {
      final List<dynamic> clientData = await ApiService.getClientList();
      final clients = clientData.map((e) => ClientModel.fromJson(e)).toList();
      debugPrint("CLIENT API RESPONSE: $clientData");
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
      debugPrint("❌ Error fetching clients: $e");
    }
  }

  void _filterClients() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredClients = _allClients);
      return;
    }

    final filtered = _allClients.where((client) {
      return client.clientName.toLowerCase().contains(query) ||
          client.contactNo.toLowerCase().contains(query);
    }).toList();

    setState(() => _filteredClients = filtered);
  }

  void _navigateToEditClientPage(ClientModel client) async {
    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) => AddClientPage(clientId: client.id),
      ),
    );

    if (result == true) {
      _fetchClients();
    }
  }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchController.text.isEmpty
                  ? "No clients available"
                  : "No matching clients found",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredClients.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return _buildClientCard(client, index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Clients',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClientPage()),
                );

                if (result == true) {
                  _fetchClients();
                }
              },
            ),
          ),
        ],
      ),
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
    );
  }

  Widget _buildClientCard(ClientModel client, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          /// Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _headerGradients[index % _headerGradients.length],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              client.type,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),

          /// Card Body
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.network(
                      client.clientPhotoUrl ?? "",
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 20);
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// Client Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Name
                      Text(
                        client.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 3),

                      /// Mobile + GST
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            client.contactNo.isEmpty ? "N/A" : client.contactNo,
                            style: const TextStyle(fontSize: 11),
                          ),

                          const SizedBox(width: 12),

                          const Icon(
                            Icons.receipt_long,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              client.gstin.isEmpty ? "No GST" : client.gstin,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      /// Address + State
                      Row(
                        children: [
                          const Icon(
                            Icons.home,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              client.address.isEmpty
                                  ? "No Address"
                                  : client.address,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 8),

                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 3),

                          Expanded(
                            child: Text(
                              client.state.isEmpty ? "N/A" : client.state,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Edit Icon
                IconButton(
                  onPressed: () => _navigateToEditClientPage(client),
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.blue,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
