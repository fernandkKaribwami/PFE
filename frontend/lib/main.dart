import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'theme/app_colors.dart';

// Configuration API
const String API_URL = 'http://localhost:5000';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'USMBA Social',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppInitializer(),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/main': (context) => const MainNavigationScreen(),
              '/admin': (context) => const AdminDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (token != null && userId != null) {
      // Validate token and navigate to main screen
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isValid = await authProvider.validateToken(token);

        if (isValid && mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          // Token invalid, go to auth
          await prefs.clear();
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } else {
      // No token, go to auth
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF003366),
                    Colors.blueAccent,
                    _ctrl.value,
                  )!,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: _ctrl.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 96, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'USMBA Social',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


                        CircleAvatar(
                          radius = 60,
                          backgroundColor = Colors.grey[300],
                          backgroundImage = avatarFile != null
                              ? FileImage(File(avatarFile!.path))
                              : null,
                          child = avatarFile == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey[700],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom = 0,
                          right = 0,
                          child = Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF003366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height = 20),
                // Nom
                Padding(
                  padding = const EdgeInsets.only(bottom: 12),
                  child = TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                // Faculty
                Padding(
                  padding = const EdgeInsets.only(bottom: 12),
                  child = DropdownButtonFormField<String>(
                    initialValue: selectedFaculty,
                    items: faculties
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedFaculty = v),
                    decoration: const InputDecoration(
                      labelText: 'Faculté / École / Institut',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                ),
                // Bio
                Padding(
                  padding = const EdgeInsets.only(bottom: 12),
                  child = TextField(
                    controller: bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio (optionnel)',
                      hintText: 'Écrivez quelque chose sur vous...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                  ),
                ),
              ],
              // Email
              Padding(
                padding = const EdgeInsets.only(bottom: 12),
                child = TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email @usmba.ac.ma',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),
              // Password
              Padding(
                padding = const EdgeInsets.only(bottom: 20),
                child = TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              // Submit Button
              ElevatedButton(
                onPressed = isLoading ? null : submit,
                style = ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF003366),
                  disabledBackgroundColor: Colors.grey,
                ),
                child = isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        isLogin ? 'Se connecter' : 'S\'inscrire',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
              SizedBox(height = 12),
              // Toggle Login/Register
              TextButton(
                onPressed = () {
                  setState(() => isLogin = !isLogin);
                  nomCtrl.clear();
                  emailCtrl.clear();
                  passCtrl.clear();
                  bioCtrl.clear();
                  selectedFaculty = null;
                  avatarFile = null;
                },
                child = Text(
                  isLogin ? 'Créer un compte' : 'Déjà inscrit ?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF003366),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
