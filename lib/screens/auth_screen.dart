// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();
      if (username.isEmpty || password.isEmpty) {
        setState(() => _errorMessage = "Please enter username and password.");
        return;
      }

      bool isAuthenticated = await _authService.login(username, password);
      if (isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _errorMessage = "Invalid credentials. Please try again.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Login failed. Please check your network.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateWithFace() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool isAuthenticated = await _authService.authenticateWithFace();
      if (isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _errorMessage = "Face authentication failed. Try again.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Face authentication error.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/login.json', height: 150),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: "Username"),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password"),
                  ),
                  SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _login,
                              child: Text("Login"),
                            ),
                            SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _authenticateWithFace,
                              icon: Icon(Icons.face),
                              label: Text("Login with Face"),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
