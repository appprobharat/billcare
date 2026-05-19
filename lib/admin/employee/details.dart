import 'package:billcare/admin/employee/add.dart';
import 'package:billcare/admin/employee/model.dart';
import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';

class ManageEmployeePage extends StatefulWidget {
  const ManageEmployeePage({super.key});

  @override
  State<ManageEmployeePage> createState() => _ManageEmployeePageState();
}

class _ManageEmployeePageState extends State<ManageEmployeePage> {
  List<EmployeeModel> _allEmployees = [];
  List<EmployeeModel> _filteredEmployees = [];
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
    _fetchEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEmployees);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.postRequest(endpoint: "/employee/list");

      if (res != null) {
        final employees = List<Map<String, dynamic>>.from(
          res,
        ).map((e) => EmployeeModel.fromJson(e)).toList();

        setState(() {
          _allEmployees = employees;
          _filteredEmployees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load employees";
      });
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredEmployees = _allEmployees);
      return;
    }

    final filtered = _allEmployees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.contactNo.toLowerCase().contains(query);
    }).toList();

    setState(() => _filteredEmployees = filtered);
  }

  void _navigateToEditEmployeePage(EmployeeModel employee) async {
    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) => AddEmployeePage(clientId: employee.id),
      ),
    );

    if (result == true) {
      _fetchEmployees();
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

    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchController.text.isEmpty
                  ? "No employees available"
                  : "No matching employees found",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredEmployees.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee, index);
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
          'Employees',
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
                  MaterialPageRoute(builder: (_) => const AddEmployeePage()),
                );

                if (result == true) {
                  // _fetchEmployees();
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

  Widget _buildEmployeeCard(EmployeeModel employee, int index) {
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
              "Employee",
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
                      employee.photo ?? "",
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

                /// Employee Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee.relative.trim().isEmpty
                                  ? employee.name
                                  : "${employee.name} (${employee.relative})",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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
                            employee.contactNo.isEmpty
                                ? "N/A"
                                : employee.contactNo,
                            style: const TextStyle(fontSize: 11),
                          ),

                          const SizedBox(width: 12),

                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 3),

                          Expanded(
                            child: Text(
                              employee.state.isEmpty ? "N/A" : employee.state,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
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
                              employee.address.isEmpty
                                  ? "No Address"
                                  : employee.address,
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
                  onPressed: () => _navigateToEditEmployeePage(employee),
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
