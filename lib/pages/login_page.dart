import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:attend_me/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final success = await _authController.login(email, password);
      setState(() => _isLoading = false);
      if (success) {
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Erreur', 'Identifiants invalides', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Login failed: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email requis';
                  if (!value.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Mot de passe requis';
                  if (value.length < 6) return 'Au moins 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,valueColor:AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Se connecter')),
              TextButton(
                onPressed: () => Get.toNamed('/signup'),
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
