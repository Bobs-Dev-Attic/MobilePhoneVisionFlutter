import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/firebase_service.dart';
import '../camera/camera_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _firebaseService = FirebaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _showEmailForm = false;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final result = await _firebaseService.signInWithGoogle();
      if (result != null && mounted) {
        _navigateToCamera();
      } else if (mounted) {
        setState(() => _errorMessage = 'Google sign-in cancelled.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final result = _isRegistering
          ? await _firebaseService.registerWithEmail(
              _emailController.text.trim(), _passwordController.text)
          : await _firebaseService.signInWithEmail(
              _emailController.text.trim(), _passwordController.text);
      if (result != null && mounted) {
        _navigateToCamera();
      } else if (mounted) {
        setState(() => _errorMessage = _isRegistering
            ? 'Registration failed.'
            : 'Invalid credentials.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToCamera() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  void _skipLogin() {
    _navigateToCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 80, color: Colors.cyanAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Vision AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Split-Inference Object Detection',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  if (_loading)
                    const SpinKitRing(color: Colors.cyanAccent, size: 48)
                  else ...[
                    if (!_showEmailForm) ...[
                      _GoogleSignInButton(onTap: _signInWithGoogle),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.email_outlined, color: Colors.cyanAccent),
                        label: const Text('Continue with Email',
                            style: TextStyle(color: Colors.cyanAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.cyanAccent),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => setState(() => _showEmailForm = true),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _skipLogin,
                        child: Text('Skip (Demo Mode)',
                            style: TextStyle(color: Colors.grey[500])),
                      ),
                    ] else ...[
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Enter email' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? 'Min 6 characters'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _signInWithEmail,
                              child: Text(_isRegistering ? 'Register' : 'Sign In'),
                            ),
                            TextButton(
                              onPressed: () => setState(
                                  () => _isRegistering = !_isRegistering),
                              child: Text(_isRegistering
                                  ? 'Have an account? Sign In'
                                  : "Don't have an account? Register"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showEmailForm = false),
                              child: const Text('← Back'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
