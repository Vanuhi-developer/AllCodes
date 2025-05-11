import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserPage extends StatefulWidget {
  final String userId;

  const UserPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<dynamic> slots = [];
  final storage = const FlutterSecureStorage();
  String? authToken;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _authenticateUser();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _authenticateUser() async {
    const url = 'http://192.168.2.106:8000/api/get-token';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'api@product.com',
          'password': 'asdqwertyuiolkj',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        authToken = data['data']['token'];
        await storage.write(key: 'token', value: authToken);
        print('Auth token: $authToken');
        fetchSlots();

        // Start timer for auto refresh
        timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchSlots());
      } else {
        print('Failed to authenticate: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error authenticating: $e');
    }
  }

  Future<void> fetchSlots() async {
    authToken = await storage.read(key: 'token');
    if (authToken == null) {
      print("Token is null, please authenticate first.");
      return;
    }

    const url = 'http://192.168.2.106:8000/api/slots';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          slots = data['data'];
        });
      } else {
        print('Failed to fetch slots: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching slots: $e');
    }
  }

  Future<void> bookSlot(int slotNumber) async {
    authToken = await storage.read(key: 'token');
    if (authToken == null) {
      print("Token is null, please authenticate first.");
      return;
    }

    const url = 'http://192.168.2.106:8000/api/book-slot';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'slot_number': slotNumber,
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Slot $slotNumber booked successfully');
        fetchSlots();
        showDialogWithCode(response.body);
      } else {
        print('Failed to book slot: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error booking slot: $e');
    }
  }

  void showDialogWithCode(String responseBody) {
    final data = jsonDecode(responseBody);
    final bookingCode = data['data']['code'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Successful'),
          content: Text('Your booking code: $bookingCode'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Car Parking System'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  var slot = slots[index];
                  bool isOccupied = slot['status'] == 'occupied';
                  bool isReserved = slot['status'] == 'reserved';
                  bool isBusy = slot['status'] == 'busy';
                  bool showBookButton = !(isOccupied || isReserved || isBusy);
                  int? slotNumber = int.tryParse(slot['slot_number'].toString());

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Icon(
                        isBusy
                            ? Icons.block
                            : (slot['status'] == 'free'
                                ? Icons.free_breakfast
                                : Icons.local_parking),
                        color: isBusy
                            ? Colors.red
                            : (slot['status'] == 'free'
                                ? Colors.green
                                : Colors.grey),
                        size: 40,
                      ),
                      title: Text(
                        'Slot ${slot['slot_number']}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Status: ${slot['status']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isReserved
                              ? Colors.orange
                              : (isOccupied
                                  ? Colors.red
                                  : (isBusy ? Colors.redAccent : Colors.green)),
                        ),
                      ),
                      trailing: showBookButton
                          ? ElevatedButton(
                              onPressed: () {
                                if (slotNumber != null && slotNumber > 0) {
                                  bookSlot(slotNumber);
                                } else {
                                  print("Invalid slot number: ${slot['slot_number']}");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Book',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class UserPage extends StatefulWidget {
//   final String userId;

//   const UserPage({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);

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

//   Future<void> _authenticateUser() async {
//     const url = 'http://192.168.1.108:8000/api/get-token';
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
//         print('Failed to authenticate: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('Error authenticating: $e');
//     }
//   }

//   Future<void> fetchSlots() async {
//     authToken = await storage.read(key: 'token'); 
//     if (authToken == null) {
//       print("Token is null, please authenticate first.");
//       return;
//     }

//     const url = 'http://192.168.1.108:8000/api/slots';
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $authToken',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           slots = data['data'];
//         });
//       } else {
//         print('Failed to fetch slots: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('Error fetching slots: $e');
//     }
//   }

//   // Book a slot
//   Future<void> bookSlot(int slotNumber) async {
//   authToken = await storage.read(key: 'token');
//   if (authToken == null) {
//     print("Token is null, please authenticate first.");
//     return;
//   }

//   const url = 'http://192.168.1.108:8000/api/book-slot';
//   try {
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $authToken',
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'slot_number': slotNumber,
//         'user_id': widget.userId, 
//       }),
//     );

//     if (response.statusCode == 200) {
//       print('Slot $slotNumber booked successfully');
//       fetchSlots();

//       // Show the code in a dialog for 2 seconds
//       showDialogWithCode(response.body);
//     } else {
//       print('Failed to book slot: ${response.statusCode} - ${response.body}');
//     }
//   } catch (e) {
//     print('Error booking slot: $e');
//   }
// }

// void showDialogWithCode(String responseBody) {
//   // Assuming the response contains the booking code
//   final data = jsonDecode(responseBody);
//   final bookingCode = data['data']['code']; // Adjust according to your API response

//   // Show a dialog with the booking code
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Booking Successful'),
//         content: Text('Your booking code: $bookingCode'),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Close the dialog immediately
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       );
//     },
//   );

  
// }


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
//               child: ElevatedButton(
//                 onPressed: fetchSlots,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 135, 105, 216),
//                   padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                   textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: const Text('Fetch Parking Slots'),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: slots.length,
//                 itemBuilder: (context, index) {
//                   var slot = slots[index];
//                   bool isOccupied = slot['status'] == 'occupied';
//                   bool isReserved = slot['status'] == 'reserved';
//                   int? slotNumber = int.tryParse(slot['slot_number'].toString());

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
//                       slot['status'] == 'busy' 
//                           ? Icons.block // Icon for busy (unavailable) slot
//                           : (slot['status'] == 'free' 
//                               ? Icons.free_breakfast // Icon for free slot
//                               : Icons.local_parking), // Default icon for other states
//                       color: slot['status'] == 'busy'
//                           ? Colors.red // Color for busy slot
//                           : (slot['status'] == 'free'
//                               ? Colors.green // Color for free slot
//                               : Colors.grey), // Default color for other states
//                       size: 40,
//                     ),

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
//                           color: isReserved 
//                               ? Colors.orange 
//                               : (isOccupied ? Colors.red : Colors.green),
//                         ),
//                       ),
//                       trailing: !isOccupied && !isReserved // Only show button for free slots
//                           ? ElevatedButton(
//                               onPressed: () {
//                                 if (slotNumber != null && slotNumber > 0) {
//                                   bookSlot(slotNumber);
//                                 } else {
//                                   print("Invalid slot number: ${slot['slot_number']}");
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Book',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             )
//                           : null, // Don't show button if slot is not free
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
