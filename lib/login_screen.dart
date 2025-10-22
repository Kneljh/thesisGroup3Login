import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'sign_up.dart'; // Import for navigation back to sign up

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  bool _isSystemUIVisible = false;
  bool _isButtonHovered = false; // State for hover animation
  bool _isLoading = false; // State for loading indicator
  bool _isPasswordVisible = false; // State for password visibility
  bool _isLinkHovered = false; // State for link hover animation

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() => _isSystemUIVisible = false);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() => _isSystemUIVisible = true);
  }

  void _toggleSystemUI() {
    _isSystemUIVisible ? _hideSystemUI() : _showSystemUI();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        // --- ADDED BORDER ---
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          // --- CHANGED TEXT COLOR ---
          color: Colors.black,
          // Removed shadow as it's not needed for black text
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            // --- CHANGED HINT COLOR ---
            color: Colors.grey,
            // Removed shadow
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Future<void> _logIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    String? errorMessage;

    if (email.isEmpty || password.isEmpty) {
      errorMessage = "Please enter both email and password.";
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Log in failed: ${e.message}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Log in error")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIXED TYPO HERE ---
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleSystemUI,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splashscreen.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      hint: "Email",
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      hint: "Password",
                      obscure: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          // --- CHANGED ICON COLOR ---
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    MouseRegion(
                      onEnter: (_) => setState(() => _isButtonHovered = true),
                      onExit: (_) => setState(() => _isButtonHovered = false),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _logIn,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          height: 70,
                          transform:
                              Matrix4.identity()
                                ..scale(_isButtonHovered ? 1.1 : 1.0),
                          transformAlignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: _isButtonHovered ? 12 : 6,
                                spreadRadius: _isButtonHovered ? 2 : 0,
                                offset: Offset(0, _isButtonHovered ? 5 : 3),
                              ),
                            ],
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Color.fromARGB(255, 80, 187, 48),
                                  )
                                  : const Icon(
                                    Icons.login,
                                    color: Color.fromARGB(255, 80, 187, 48),
                                    size: 36,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Link to Sign Up with selective hover
                    MouseRegion(
                      onEnter: (_) => setState(() => _isLinkHovered = true),
                      onExit: (_) => setState(() => _isLinkHovered = false),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _isLinkHovered
                                        ? Colors.blue
                                        : Colors.blueAccent,
                                decoration:
                                    _isLinkHovered
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignUpScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
