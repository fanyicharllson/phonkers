import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailCheckPage extends StatefulWidget {
  final String email;

  const EmailCheckPage({super.key, required this.email});

  @override
  State<EmailCheckPage> createState() => _EmailCheckPageState();
}

class _EmailCheckPageState extends State<EmailCheckPage>
    with WidgetsBindingObserver {
  bool isChecking = false;
  bool canResend = false;
  int resendTimer = 60;
  Timer? _periodicTimer;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startResendTimer();
    _startSmartPeriodicCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - user might have verified email
        _isAppInForeground = true;
        _checkEmailVerificationNow(); // Immediate check
        _startSmartPeriodicCheck(); // Resume periodic checking
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background - save battery
        _isAppInForeground = false;
        _periodicTimer?.cancel();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startResendTimer() {
    setState(() {
      canResend = false;
      resendTimer = 60;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && resendTimer > 0) {
        setState(() {
          resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          canResend = true;
        });
      }
    });
  }

  void _startSmartPeriodicCheck() {
    _periodicTimer?.cancel();

    if (_isAppInForeground) {
      // Check every 3 seconds when app is active
      _periodicTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_isAppInForeground) {
          _checkEmailVerificationNow();
        } else {
          timer.cancel(); // Stop if app goes to background
        }
      });
    }
  }

  Future<void> _checkEmailVerificationNow() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        // Email verified! Show success and redirect
        _showVerificationSuccess();
      }
    }
  }

  void _showVerificationSuccess() {
    // Cancel periodic checking
    _periodicTimer?.cancel();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Email verified successfully! 🎉",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Wait a moment then navigate
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      isChecking = true;
    });

    await _checkEmailVerificationNow();

    // If still not verified, show message
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please check your email and click the verification link",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      isChecking = false;
    });
  }

  Future<void> _resendEmail() async {
    if (!canResend) return;

    try {
      authService.value.sendEmailVerification();

      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification email sent to ${widget.email}"),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to resend verification email! Please try again later",
              style: TextStyle(color: Colors.white),
            ),
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
                  // Email Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 50,
                      color: Colors.purple,
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
                        const TextSpan(
                          text: "We've sent a verification link to\n",
                        ),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text:
                              "\n\nClick the link in your email to verify your account.",
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildBullet("Check your inbox (and spam folder)"),
                        const SizedBox(height: 12),
                        _buildBullet("Click the verification link"),
                        const SizedBox(height: 12),
                        _buildBullet("Return to this app"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40), 
                  // Check Again Button
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
                      onPressed: isChecking ? null : _checkEmailVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "I've Verified My Email",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resend Section
                  Column(
                    children: [
                      Text(
                        "Didn't receive the email?",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: canResend ? _resendEmail : null,
                        child: Text(
                          canResend
                              ? "Resend Email"
                              : "Resend in ${resendTimer}s",
                          style: TextStyle(
                            color: canResend
                                ? Colors.purple
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Back Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Back to Sign Up",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // helper widget for instructions
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
