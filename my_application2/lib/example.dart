// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class UserPage extends StatefulWidget {
//   const UserPage({super.key});

//   @override
//   _UserPageState createState() => _UserPageState();
// }

// class _UserPageState extends State<UserPage> {
//   List<dynamic> slots = [];
//   final storage = const FlutterSecureStorage();
//   String? authToken;

//   @override
//   void initState() {
//     super.initState();
//     _authenticateUser();
//   }

//   // Authenticate and get token
//   Future<void> _authenticateUser() async {
//     const url = 'http://127.0.0.1:8000/api/get-token';
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'email': 'api@product.com',
//           'password': 'asdqwertyuiolkj',
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         authToken = data['data']['token'];
//         await storage.write(key: 'token', value: authToken);
//         print('Auth token: $authToken');
//         fetchSlots();
//       } else {
//         print('Failed to authenticate: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error authenticating: $e');
//     }
//   }

//   // Fetch slots with token
//   Future<void> fetchSlots() async {
//     authToken ??= await storage.read(key: 'token');
//     if (authToken == null) {
//       print("Token is null, please authenticate first.");
//       return;
//     }

//     const url = 'http://127.0.0.1:8000/api/slots';
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $authToken',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode({}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           slots = data['data'];
//         });
//         print('Slots: $slots');
//       } else {
//         print('Failed to fetch slots: ${response.statusCode}');
//         print(response.body);
//       }
//     } catch (e) {
//       print('Error fetching slots: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Smart Car Parking System'),
//         backgroundColor: Colors.deepPurpleAccent,
//       ),
//       body: Center(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               child:ElevatedButton(
//               onPressed: fetchSlots,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 135, 105, 216), // Use backgroundColor instead of primary
//                 padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                 textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30), // Rounded corners
//                 ),
//               ),
//               child: const Text('Fetch Parking Slots'),
//             )
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: slots.length,
//                 itemBuilder: (context, index) {
//                   var slot = slots[index];
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 8,
//                     shadowColor: Colors.black26,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.all(20),
//                       leading: Icon(
//                         slot['status'] == 'occupied'
//                             ? Icons.local_parking
//                             : Icons.free_breakfast,
//                         color: slot['status'] == 'occupied'
//                             ? Colors.red
//                             : Colors.green,
//                         size: 40,
//                       ),
//                       title: Text(
//                         'Slot ${slot['slot_number']}',
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       subtitle: Text(
//                         'Status: ${slot['status']}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: slot['status'] == 'occupied'
//                               ? Colors.red
//                               : Colors.green,
//                         ),
//                       ),
//                       trailing: Icon(
//                         slot['status'] == 'occupied'
//                             ? Icons.block
//                             : Icons.check_circle,
//                         color: slot['status'] == 'occupied'
//                             ? Colors.red
//                             : Colors.green,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// 