import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isSystemUIVisible = false;
  bool _isButtonHovered = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility
  bool _isLinkHovered = false; // State for link hover animation

  final TextEditingController _nameController = TextEditingController();
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
    _nameController.dispose();
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
          // Removed shadow
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

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    String? errorMessage;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      errorMessage = "Please fill in all fields.";
    } else if (!email.contains('@') || !email.contains('.')) {
      errorMessage = "Please enter a valid email address.";
    } else if (password.length < 6) {
      errorMessage = "Password must be at least 6 characters long.";
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({'name': name, 'email': email, 'createdAt': DateTime.now()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please log in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LogInScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign up failed: ${e.message}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Sign up error")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // --- MODIFIED FOR CENTERING ---
                left: 0,
                right: 0,
                top: 130,
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center, // <-- Added this
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
                      controller: _nameController,
                      hint: "Full Name",
                    ),
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
                        onTap: _isLoading ? null : _signUp,
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
                                    Icons.person_add,
                                    color: Color.fromARGB(255, 80, 187, 48),
                                    size: 36,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Link to Log In with selective hover
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
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Log in",
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
                                          builder: (context) => LogInScreen(),
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
