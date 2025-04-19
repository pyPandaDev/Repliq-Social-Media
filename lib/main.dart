import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get_storage/get_storage.dart';
import 'package:social_media/routes/route.dart';
import 'package:social_media/routes/route_names.dart';
import 'package:social_media/services/storage_service.dart';
import 'package:social_media/services/supabase_service.dart';
import 'package:social_media/theme/theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  Get.put(SupabaseService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: theme,
      getPages: Routes.pages,
      initialRoute: StorageService.userSession != null 
      ? RouteNames.home 
      : RouteNames.login, 
     defaultTransition: Transition.noTransition,
    );
  }
}

