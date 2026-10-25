import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;

  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color secondaryText = Color(0xFF514939);
  static const Color iconColor = Color(0xFF887D67);
  static const Color inputBackground = Colors.white;
  static const Color hintColor = Color(0xFFA69D8D);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _createAccount() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 8 ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];]').hasMatch(password)) {
      _showMessage(
        'Use at least 8 characters, 1 number and 1 special symbol.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (!_agreeToTerms) {
      _showMessage(
        'Please agree to the Terms of Service and Privacy Policy.',
      );
      return;
    }

    _showMessage('Connect your authentication controller to create an account.');
  }

  void _googleSignUp() {
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
                        'Sign Up',
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                              color: Colors.brown.withValues(alpha: 0.05),
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
                                  offset: const Offset(0, 4),
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
                    const SizedBox(height: 18),
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
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _nameController,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Email Address'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _emailController,
                      hint: 'Enter your email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _passwordController,
                      hint: 'Create strong password',
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
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline,
                            size: 15,
                            color: darkGold,
                          ),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Minimum 8 characters with 1 number and 1 special symbol',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _confirmPasswordController,
                      hint: 'Re-enter your password',
                      icon: Icons.lock_clock_outlined,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 22,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: darkGold,
                            checkColor: Colors.white,
                            side: const BorderSide(
                              color: darkGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text(
                                "I agree to DailyDhan's ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                  height: 1.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/terms',
                                ),
                                child: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: darkGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/privacy',
                                ),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: darkGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text(
                                '.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _createAccount,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, size: 21),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
                            'OR SIGN UP WITH',
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
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _googleSignUp,
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
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/login',
                          ),
                          child: const Text(
                            'Login',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: secondaryText,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 15,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: hintColor,
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