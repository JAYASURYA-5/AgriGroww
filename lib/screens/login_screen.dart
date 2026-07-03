import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Navigation State: 'login', 'signup_step1', 'signup_step2', 'signup_step3'
  String _currentStep = 'login';

  // Login Controllers
  final TextEditingController _loginIdentifierController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();

  // Signup Step 1 Controllers
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final _signupStep1FormKey = GlobalKey<FormState>();

  // Signup Step 2 Controllers
  final TextEditingController _signupMobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;

  // Signup Step 3 Controllers
  String _selectedGender = 'Male';
  final TextEditingController _locationController = TextEditingController();
  bool _isLocating = false;
  int _selectedAvatarIndex = 0; // 0 to 4
  String? _customAvatarPath;

  // Mock avatars list (representing the 5 avatars in screenshot 4)
  final List<String> _avatars = [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&q=80', // Female avatar
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&q=80', // Male avatar with patch
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=120&q=80', // Curly haired avatar
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120&q=80', // Red haired female
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&q=80', // Male with pink hood
  ];

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupMobileController.dispose();
    _otpController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- Handlers ---

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      final identifier = _loginIdentifierController.text.trim();
      final password = _loginPasswordController.text.trim();

      final success = await AppState().login(identifier, password);
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials! Verify mobile/email and password.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _handleStep1Continue() {
    if (_signupStep1FormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 'signup_step2';
      });
    }
  }

  void _sendOtp() {
    final mobile = _signupMobileController.text.trim();
    if (mobile.isEmpty || mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    setState(() {
      _otpSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to your mobile! Use 1234 to verify.'), backgroundColor: Color(0xFF22C55E)),
    );
  }

  void _handleStep2Verify() {
    final otp = _otpController.text.trim();
    if (otp == '1234') {
      setState(() {
        _currentStep = 'signup_step3';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP! Enter 1234 to verify.'), backgroundColor: Color(0xFFEF4444)),
      );
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    // Request mock permission dialog first
    final bool? allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Allow Location Access?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('AgriGrow needs to access your device\'s location to determine your farm coordinates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (allow != true) {
      setState(() => _isLocating = false);
      return;
    }

    try {
      // Try resolving IP Geolocation
      final response = await http.get(Uri.parse('https://ip-api.com/json')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city']?.toString() ?? 'Tiruppur';
        _locationController.text = city;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location auto-detected: $city'), backgroundColor: const Color(0xFF22C55E)),
        );
      } else {
        throw Exception();
      }
    } catch (_) {
      // Fallback mock location matching screenshot
      _locationController.text = 'Tiruppur';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location detected: Tiruppur (Fallback)'), backgroundColor: Color(0xFF22C55E)),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickCustomAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _customAvatarPath = image.path;
          _selectedAvatarIndex = -1; // Deselect default avatars
        });
      }
    } catch (e) {
      debugPrint('Error picking profile picture: $e');
    }
  }

  void _handleSignUpSubmit() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm location is required!'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    final String photoUrl = _selectedAvatarIndex != -1 
        ? _avatars[_selectedAvatarIndex] 
        : (_customAvatarPath ?? _avatars[0]);

    final newUser = {
      'fullName': _signupNameController.text.trim(),
      'email': _signupEmailController.text.trim(),
      'password': _signupPasswordController.text.trim(),
      'mobile': _signupMobileController.text.trim(),
      'gender': _selectedGender,
      'location': location,
      'photo': photoUrl,
    };

    final success = await AppState().registerUser(newUser);
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number or email already registered!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentStep == 'login') _buildLoginCard(),
                if (_currentStep == 'signup_step1') _buildStep1Card(),
                if (_currentStep == 'signup_step2') _buildStep2Card(),
                if (_currentStep == 'signup_step3') _buildStep3Card(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. LOGIN SCREEN CARD
  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tractor Icon Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.agriculture, // Represents tractor/farm icon
                color: Color(0xFF22C55E),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to manage your farm',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Email or Mobile Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email or Mobile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _loginIdentifierController,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter your email or mobile';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '........',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter your password';
                return null;
              },
            ),

            // Forgot password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset instructions sent to registered contact.')),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00).withOpacity(0.9) != const Color(0xFF00FF00)
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF00FF00),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Sign In',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.login, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Google Sign In Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 16),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google Authentication selected (Mock)')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/googleg_32dp.png',
                      height: 18,
                      width: 18,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Sign in with Google', style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Go to Signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey[600])),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 'signup_step1';
                    });
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. SIGNUP STEP 1: CREATE ACCOUNT
  Widget _buildStep1Card() {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Form(
        key: _signupStep1FormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'STEP 1/3',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Full Name
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _signupNameController,
              decoration: InputDecoration(
                hintText: 'John Doe',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'john@example.com',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter your email address';
                if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _signupPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '........',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter password';
                if (val.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleStep1Continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Go to Sign In
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.grey[600])),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 'login';
                    });
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. SIGNUP STEP 2: VERIFY MOBILE
  Widget _buildStep2Card() {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verify Mobile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'STEP 2/3',
                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mobile Input with resend button
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mobile Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _signupMobileController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), // Slate blue text color matching screenshot
                  decoration: InputDecoration(
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    fillColor: const Color(0xFFEFF6FF), // soft light blue input box matching screenshot
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F8F5),
                    foregroundColor: const Color(0xFF00BFA5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Resend', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          if (_otpSent) ...[
            const SizedBox(height: 12),
            const Text(
              'OTP sent! Use 1234 to verify.',
              style: TextStyle(color: Color(0xFF0D9488), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 20),

          // OTP field title
          Text(
            'Enter 4-Digit OTP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[750]),
          ),
          const SizedBox(height: 8),

          // Large OTP Input Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
            ),
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 24,
                color: Color(0xFF1F2937),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '••••',
                hintStyle: TextStyle(letterSpacing: 24),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Verify & Next Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleStep2Verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Verify & Next',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Go Back Link
          GestureDetector(
            onTap: () {
              setState(() {
                _currentStep = 'signup_step1';
              });
            },
            child: Text(
              'Go Back',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Go to Sign In
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: Colors.grey[600])),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentStep = 'login';
                  });
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. SIGNUP STEP 3: PROFILE DETAILS
  Widget _buildStep3Card() {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'STEP 3/3',
                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gender Selection
          const Text(
            'Gender',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Male Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Male' ? const Color(0xFFDCFCE7) : Colors.white,
                      border: Border.all(
                        color: _selectedGender == 'Male' ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Male',
                        style: TextStyle(
                          color: _selectedGender == 'Male' ? const Color(0xFF1B4332) : const Color(0xFF4B5563),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Female Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Female' ? const Color(0xFFDCFCE7) : Colors.white,
                      border: Border.all(
                        color: _selectedGender == 'Female' ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Female',
                        style: TextStyle(
                          color: _selectedGender == 'Female' ? const Color(0xFF1B4332) : const Color(0xFF4B5563),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Farm Location
          const Text(
            'Farm Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Coimbatore',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLocating ? null : _detectLocation,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00).withOpacity(0.9) != const Color(0xFF00FF00)
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF00FF00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLocating 
                      ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : const Icon(Icons.gps_fixed, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile Photo Title + device link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              GestureDetector(
                onTap: _pickCustomAvatar,
                child: const Text(
                  'Choose from Device',
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Avatars List / Photo Preview
          SizedBox(
            height: 60,
            child: _customAvatarPath != null 
                ? Row(
                    children: [
                      Stack(
                        children: [
                          ClipOval(
                            child: Image.file(
                              File(_customAvatarPath!),
                              height: 54,
                              width: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 10),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Text('Custom Photo Selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    ],
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedAvatarIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarIndex = index;
                              _customAvatarPath = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(_avatars[index]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),

          // Back & Sign Up buttons row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 'signup_step2';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSignUpSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 6),
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Go to Sign In link
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.grey[600])),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 'login';
                    });
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
