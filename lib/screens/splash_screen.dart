import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 1. Check Permissions & Setup
    final prefs = await SharedPreferences.getInstance();
    final isSetupCompleted = prefs.getBool('setup_completed') ?? false;

    // We also want to re-verify permissions even if setup was marked complete
    // because user might have revoked them in settings.
    bool permissionsValid = true;
    if (isSetupCompleted) {
      // Quick check
      final phone = await Permission.phone.isGranted;
      // Storage check (simplified)
      bool storage = false;
      if (Platform.isAndroid) {
        if (await Permission.audio.isGranted ||
            await Permission.storage.isGranted) {
          storage = true;
        }
      } else {
        storage = true;
      }
      permissionsValid = phone && storage;
    }

    if (!isSetupCompleted || !permissionsValid) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/setup');
      }
      return;
    }

    // 2. Check Auth
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/leads');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 100, color: AppColors.secondary),
            SizedBox(height: 24),
            Text(
              'Travel LMS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
