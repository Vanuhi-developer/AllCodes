import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserAccountPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text;
      final String password = _passwordController.text;

      final url = Uri.parse('http://192.168.2.106:8000/api/direct-login'); // Your Laravel API endpoint
      final response = await http.post(
        url,
        body: {
          'email': email,
          'password': password,
        },
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          // Store user data locally (Optional, if needed)
          final userId = responseData['data']['id'];
          final userEmail = responseData['data']['email'];
          final userName = responseData['data']['name'];

          // Navigate to UserAccountPage and pass user data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserAccountPage(
               userId: userId.toString(),  // Pass userId as a string
                email: userEmail,
                name: userName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${responseData['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF719DEA),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2159BC), Color(0xFF497FDD)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      "https://www.shutterstock.com/image-vector/vector-illustration-car-park-icon-260nw-2564506581.jpg",
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Log in to continue",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.email, color: Colors.blue),
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
