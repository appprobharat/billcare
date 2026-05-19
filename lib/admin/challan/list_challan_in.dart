import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'add_challan_in.dart';

class ChallanInListPage extends StatefulWidget {
  const ChallanInListPage({super.key});

  @override
  State<ChallanInListPage> createState() => _ChallanInListPageState();
}

class _ChallanInListPageState extends State<ChallanInListPage> {
  List<Map<String, String>> challanList = [
    {
      "client": "ABC Pvt Ltd",
      "challanNo": "CH-001",
      "date": "10-04-2026",
      "gstin": "22AAAAA0000A1Z5",
      "contact": "9876543210",

      "item": "Laptop",
    },
    {
      "client": "XYZ Traders",
      "challanNo": "CH-002",
      "date": "10-04-2026",
      "gstin": "33BBBBB1111B2Z6",
      "contact": "9123456780",
      "item": "computer",
    },
  ];

  Widget twoColText(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget challanCard(Map<String, String> data) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 4), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['client'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  data['date'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 4),


            Row(
              children: [
                twoColText("No", data['challanNo'] ?? ''),
                twoColText("GSTIN", data['gstin'] ?? ''),
              ],
            ),

            const SizedBox(height: 4),

          
            Row(
              children: [
                twoColText("Mob", data['contact'] ?? ''),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Item",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              data['item'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          // TODO: Edit
                        },
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'AddChallan In',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddChallanInPage()),
              ).then((result) async {});
            },
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
     
      body: challanList.isEmpty
          ? const Center(child: Text("No Challans Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: challanList.length,
              itemBuilder: (_, index) {
                return challanCard(challanList[index]);
              },
            ),
    );
  }
}
