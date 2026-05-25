// import 'package:billcare/helper.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// class Client {
//   final String name;
//   final String mobile;
//   final String state;

//   Client({required this.name, required this.mobile, required this.state});
// }
// class AddChallanInPage extends StatefulWidget {
//   const AddChallanInPage({super.key});

//   @override
//   State<AddChallanInPage> createState() => _AddChallanInPageState();
// }

// class _AddChallanInPageState extends State<AddChallanInPage> {
//   final TextEditingController challanNoController = TextEditingController();
//   final TextEditingController poNoController = TextEditingController();

//   DateTime selectedDate = DateTime.now();
//   DateTime? poDate;

//   String? selectedClient;
//   String? selectedItem;

//   // Dummy data (later API se replace karna)
//   final List<String> clients = ['ABC Pvt Ltd', 'XYZ Traders', 'Demo Client'];
//   final List<String> items = ['Item 1', 'Item 2', 'Item 3'];
//   // 🔹 Date Controller
//   late TextEditingController dateController;
//   late TextEditingController poDateController;

//   @override
//   void initState() {
//     super.initState();
//     dateController = TextEditingController(text: formatDate(DateTime.now()));
//     poDateController = TextEditingController();
//   }

//   // 🔹 Date Picker Common
//   Future<void> pickDate(TextEditingController controller) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       controller.text = formatDate(picked);
//     }
//   }

//   String formatDate(DateTime date) {
//     return DateFormat('dd-MM-yyyy').format(date);
//   }

//   Future<void> pickPoDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: poDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         poDate = picked;
//       });
//     }
//   }

//   Widget buildDropdown({
//     required String hint,
//     required String? value,
//     required List<String> items,
//     required Function(String?) onChanged,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: DropdownButton<String>(
//         value: value,
//         hint: Text(hint),
//         isExpanded: true,
//         underline: const SizedBox(),
//         items: items
//             .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//             .toList(),
//         onChanged: onChanged,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Add Challan In")),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // 🔹 Date Field
//               TextField(
//                 controller: dateController,
//                 readOnly: true,
//                 onTap: () => pickDate(dateController),
//                 decoration: const InputDecoration(
//                   labelText: "Date",
//                   border: OutlineInputBorder(),
//                   suffixIcon: Icon(Icons.calendar_today, size: 18),
//                 ),
//               ),

//               const SizedBox(height: 10),

//               // 🔹 Client Dropdown (Overlay helper use)
//               SizedBox(
//                 height: 60,
//                 child: OverlayDropdown(
//                   label: "Client",
//                   value: selectedClient,
//                   items: clients,
//                   onSelect: (val) {
//                     setState(() {
//                       selectedClient = val;
//                     });
//                   },
//                 ),
//               ),

//               const SizedBox(height: 10),

//               // 🔹 Challan No
//               TextField(
//                 controller: challanNoController,
//                 decoration: const InputDecoration(
//                   labelText: "Challan No",
//                   border: OutlineInputBorder(),
//                   isDense: true,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               // 🔥 PO No + PO Date SAME ROW
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: poNoController,
//                       decoration: const InputDecoration(
//                         labelText: "PO No",
//                         border: OutlineInputBorder(),
//                         isDense: true,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: poDateController,
//                       readOnly: true,
//                       onTap: () => pickDate(poDateController),
//                       decoration: const InputDecoration(
//                         labelText: "PO Date",
//                         border: OutlineInputBorder(),
//                         isDense: true,
//                         suffixIcon: Icon(Icons.calendar_today, size: 18),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               // 🔹 Item Dropdown (compact)
//               SizedBox(
//                 height: 60,
//                 child: OverlayDropdown(
//                   label: "Item",
//                   value: selectedItem,
//                   items: items,
//                   onSelect: (val) {
//                     setState(() {
//                       selectedItem = val;
//                     });
//                   },
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // 🔹 Save Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {},
//                   child: const Text("Save"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
