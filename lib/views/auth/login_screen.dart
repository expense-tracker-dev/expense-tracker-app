import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color secondaryText = Color(0xFF514939);
  static const Color iconColor = Color(0xFF887D67);
  static const Color inputBackground = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _login() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    _showMessage('Connect your authentication controller to log in.');
  }

  void _googleLogin() {
    _showMessage('Connect Google Sign-In to continue.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: background,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 26,
                      color: textColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withValues(alpha: 0.06),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withValues(alpha: 0.13),
                                  blurRadius: 8,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF705000),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8DF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'DAILYDHAN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: secondaryText,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _emailController,
                      hint: 'Enter your email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _passwordController,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 22,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: const Color(0xFF624900),
                          elevation: 3,
                          shadowColor: Colors.brown.withValues(alpha: 0.16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, size: 21),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Color(0xFFE5DED1),
                            thickness: 1.2,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFFE5DED1),
                            thickness: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _googleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: inputBackground,
                          foregroundColor: textColor,
                          elevation: 1,
                          shadowColor: Colors.brown.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFFEDE6D9),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _googleLogo(),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: darkGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE6D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.035),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 15,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFA69D8D),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(icon, size: 21, color: iconColor),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 44,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _googleLogo() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}