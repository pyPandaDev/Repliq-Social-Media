import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:social_media/routes/route_names.dart';
import 'package:social_media/views/auth/login.dart';
import 'package:social_media/views/auth/register.dart';
import 'package:social_media/views/home.dart';

class Routes {
  static final pages = [
    GetPage(name: RouteNames.home,page: () => Home()),

    GetPage(name: RouteNames.login,page: () =>const Login() ,transition: Transition.fade),

    GetPage(name: RouteNames.register,page: () => const Register() ,transition: Transition.fade),
  ];
}