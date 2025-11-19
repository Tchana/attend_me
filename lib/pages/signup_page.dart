import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:attend_me/controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Interval(0.0, 0.35, curve: Curves.elasticOut)));
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Interval(0.35, 1.0, curve: Curves.easeOut)));
    _formOffset = Tween<Offset>(begin: Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Interval(0.35, 1.0, curve: Curves.easeOut)));
    Future.delayed(Duration(milliseconds: 80), () => _animController.forward());
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final success = await _authController.signup(name, email, password);
      setState(() => _isLoading = false);
      if (success) {
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Erreur', 'Échec de l\'inscription', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Signup failed: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("S'inscrire")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset('assets/icon/attendme.png', height: 92, fit: BoxFit.contain, errorBuilder: (c, e, s) => SizedBox(height: 92)),
                  ),
                  const SizedBox(height: 12),
                  Text('Créer un compte', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Créez un compte pour sauvegarder vos programmes et données.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _formOpacity,
                    child: SlideTransition(
                      position: _formOffset,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom complet',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Nom requis' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email requis';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                                  if (v.length < 6) return 'Au moins 6 caractères';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirmer le mot de passe',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Confirmation requise';
                                  if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF007BFF),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                    child: _isLoading
                                        ? SizedBox(key: ValueKey('loader'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                        : Text("S'inscrire", key: ValueKey('text'), style: TextStyle(color: Color(0xFFFFFFFF))),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Déjà un compte ?'),
                                  TextButton(onPressed: () => Get.back(), child: const Text('Se connecter')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
