import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:survey/core/di/injection.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/core/theme/app_theme.dart';
import 'package:survey/presentation/screens/login/login_screen.dart';
import 'package:survey/presentation/screens/surveys_list/surveys_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await HiveService.init();

  // Initialize dependency injection
  Injection.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Injection.surveysListViewModel),
        ChangeNotifierProvider(create: (_) => Injection.surveyDetailsViewModel),
        ChangeNotifierProvider(create: (_) => Injection.loginViewModel),
      ],
      child: MaterialApp(
        title: 'المسح الميداني للباحة',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to check auth state and navigate accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = HiveService.isLoggedIn();
    
    if (isLoggedIn) {
      return const SurveysListScreen();
    } else {
      return const LoginScreen();
    }
  }
}
