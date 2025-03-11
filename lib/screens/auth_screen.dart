// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _isPasswordVisible = false;
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
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
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
      bool isAuthenticated = await _authService.authenticateWithFace(context as File);
      if (isAuthenticated) {
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "FACE RECOGNITION APP",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Login"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _authenticateWithFace,
                          icon: const Icon(Icons.face),
                          label: const Text("Login with Face"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
