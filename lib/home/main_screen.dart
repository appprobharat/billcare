// import 'package:billcare/clients/details.dart';
// import 'package:billcare/home/new_dashboard.dart';
// import 'package:billcare/purchase/manage.dart';
// import 'package:billcare/sale/manage.dart';
// import 'package:flutter/material.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int currentIndex = 0;

//   final List<Widget> pages = [
//     DashboardPage(),
//     SalesManagePage(),
//     PurchaseManagePage(),
//     ManageClientPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: currentIndex,
//         children: pages,
//       ),

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: currentIndex,
//         onTap: (index) {
//           setState(() {
//             currentIndex = index;
//           });
//         },

//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.point_of_sale),
//             label: "Sale",
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_cart),
//             label: "Purchase",
//           ),

//           BottomNavigationBarItem(
//             icon: Icon(Icons.people),
//             label: "Client",
//           ),
//         ],
//       ),
//     );
//   }
// }