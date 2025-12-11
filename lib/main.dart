import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lead_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/leads/leads_list_screen.dart';
import 'screens/leads/lead_detail_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const TravelLMSApp());
}

class TravelLMSApp extends StatelessWidget {
  const TravelLMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
      ],
      child: MaterialApp(
        title: 'Travel LMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/leads': (context) => const LeadsListScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle lead detail route with parameter
          if (settings.name == '/lead-detail') {
            final leadId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => LeadDetailScreen(leadId: leadId),
            );
          }
          return null;
        },
      ),
    );
  }
}
