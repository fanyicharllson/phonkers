import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email; // Optional email passed from login screen

  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _canResend = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.value.resetPasword(email: _emailController.text.trim());

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Password reset email sent to ${_emailController.text.trim()}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = "Failed to send reset email. Please try again.";

        // Handle specific Firebase errors
        if (e.toString().contains('user-not-found')) {
          errorMessage = "No account found with this email address.";
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = "Please enter a valid email address.";
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = "Too many attempts. Please try again later.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    try {
      await authService.value.resetPasword(email: _emailController.text.trim());
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password reset email resent to ${_emailController.text.trim()}",
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to resend email. Please try again later."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A0B2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Section
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Image.asset(
                        "assets/icon/dark_phonkers_logo.png",
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (!_emailSent) ...[
                    // Initial Reset Form
                    _buildResetForm(),
                  ] else ...[
                    // Email Sent Confirmation
                    _buildEmailSentView(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        // Lock Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            size: 50,
            color: Colors.purple,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        const Text(
          "Reset Password",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          "Enter your email address you used to sign up and we'll send you a link to reset your password.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        // Email Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Send Reset Email Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Send Reset Email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Back to Login
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 18, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                "Back to Login",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSentView() {
    return Column(
      children: [
        // Email Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        const Text(
          "Check Your Email",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Description
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "We've sent a password reset link to\n"),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text:
                    "\n\nClick the link in your email to create a new password.",
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildBullet("Check your inbox (and spam folder)"),
              const SizedBox(height: 12),
              _buildBullet("Click the password reset link"),
              const SizedBox(height: 12),
              _buildBullet("Create your new password"),
              const SizedBox(height: 12),
              _buildBullet("Return to login with new password"),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Resend Section
        Column(
          children: [
            Text(
              "Didn't receive the email?",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _canResend ? _resendEmail : null,
              child: Text(
                _canResend ? "Resend Email" : "Resend in ${_resendTimer}s",
                style: TextStyle(
                  color: _canResend
                      ? Colors.purple
                      : Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Try Different Email
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            "Try a different email address",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Back Button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 18, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                "Back to Login",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}
