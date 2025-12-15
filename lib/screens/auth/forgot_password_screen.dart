import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Relative import
import '../../utils/validators.dart'; // Relative import
import '../../widgets/custom_button.dart'; // Relative import

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _message;
  bool _isError = false; // Track if the message is an error or success

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    // Close keyboard first
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
        _isError = false;
      });

      try {
        await _authService.resetPassword(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isError = false;
            _message = 'Password reset email sent! Check your inbox.';
          });
          // Optional: Go back to login after a delay
          // Future.delayed(const Duration(seconds: 2), () {
          //   if (mounted) Navigator.pop(context);
          // });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isError = true;
            // Clean up the error message slightly
            _message = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        // Centered for better look on tablets/web
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 80, color: Colors.grey),
                const SizedBox(height: 24.0),
                Text(
                  'Forgot Your Password?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Enter your email address below and we will send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32.0),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  // Action button on keyboard triggers submission
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendResetEmail(),
                ),
                const SizedBox(height: 24.0),

                CustomButton(
                  text: 'Send Reset Email',
                  onPressed: _sendResetEmail,
                  isLoading: _isLoading,
                ),

                // Message Area
                if (_message != null) ...[
                  const SizedBox(height: 24.0),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isError
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _isError ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _isError
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
