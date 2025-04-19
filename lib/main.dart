import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:repliq/routes/route.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/config_service.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/theme/theme.dart';
import 'package:repliq/utils/back_button_handler.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services in correct order
    await GetStorage.init();
    await ConfigService.initialize();
    
    // Initialize Supabase service after config is loaded
    final supabaseService = Get.put(SupabaseService());
    
    // Initialize voice service and wait for it
    await initServices();
    
    // Run the app with error handling
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

Future<void> initServices() async {
  print('Starting service initialization...');
  try {
    // Initialize base services
    print('Initializing base services...');
    await Get.putAsync(() async {
      final configService = ConfigService();
      return await configService.init();
    });
    
    print('Initializing VoiceService...');
    final voiceService = Get.put(VoiceService());
    int retryCount = 0;
    const maxRetries = 3;
    
    while (!voiceService.isInitialized.value && retryCount < maxRetries) {
      print('VoiceService initialization attempt ${retryCount + 1}/$maxRetries');
      final success = await voiceService.initializeTts();
      
      if (!success) {
        retryCount++;
        if (retryCount < maxRetries) {
          print('Waiting before retry...');
          await Future.delayed(const Duration(seconds: 2));
        }
      } else {
        break;
      }
    }
    
    if (!voiceService.isInitialized.value) {
      print('WARNING: VoiceService failed to initialize after $maxRetries attempts');
    }
    
    print('All services initialization completed');
  } catch (e, stackTrace) {
    print('Error during service initialization: $e');
    print('Stack trace: $stackTrace');
    Get.snackbar(
      'Initialization Error',
      'Failed to initialize services: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = Get.find<SupabaseService>();
    
    return Obx(() {
      if (!supabaseService.isInitialized.value) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (supabaseService.errorMessage.value.isNotEmpty) {
        return MaterialApp(
          home: ErrorApp(error: supabaseService.errorMessage.value),
        );
      }

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Repliq',
        theme: theme,
        getPages: Routes.pages,
        defaultTransition: Transition.noTransition,
        initialRoute: RouteNames.splash,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return WillPopScope(
            onWillPop: () async {
              try {
                return await BackButtonHandler.handleBackButton(context);
              } catch (e) {
                print('Error handling back button: $e');
                return true;
              }
            },
            child: child,
          );
        },
      );
    });
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 16),
                Text(
                  'Application Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}