import 'package:flutter/material.dart';
import 'userPage.dart'; 

class UserAccountPage extends StatelessWidget {
  final String email;
  final String name;
  final String userId;  

  const UserAccountPage({
    Key? key,
    required this.email,
    required this.name,
    required this.userId,  
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF719DEA),
        elevation: 5.0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Details",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            buildInfoCard("Email", email),
            buildInfoCard("Name", name),
            buildInfoCard("User ID", userId),
            const SizedBox(height: 30),

            /// Button to navigate to UserPage
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserPage(userId: userId),
                  ),
                );
              },
              icon: const Icon(Icons.account_circle, size: 20),
              label: const Text(
                'Go to Slots Page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,  
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5.0,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.exit_to_app, size: 20),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,  
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
