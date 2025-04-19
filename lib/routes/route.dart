import 'package:get/get.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/views/auth/login.dart';
import 'package:repliq/views/auth/register.dart';
import 'package:repliq/views/comment/add_comment.dart';
import 'package:repliq/home.dart';
import 'package:repliq/views/profile/edit_profile.dart';
import 'package:repliq/views/profile/followers_list.dart';
import 'package:repliq/views/profile/show_profile.dart';
import 'package:repliq/views/setting/setting.dart';
import 'package:repliq/views/threads/show_image.dart';
import 'package:repliq/views/threads/show_thread.dart';
import 'package:repliq/bindings/profile_binding.dart';
import 'package:repliq/bindings/followers_binding.dart';
import 'package:repliq/views/splash/splash_screen.dart';
import 'package:repliq/views/setting/contact_us.dart';

class Routes {
  static final pages = [
    GetPage(
      name: RouteNames.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: RouteNames.home,
      page: () => Home(),
      transition: Transition.fadeIn,
    ),
    GetPage(name: RouteNames.login,page: () =>const Login() ,transition: Transition.fade),

    GetPage(name: RouteNames.register,page: () => const Register() ,transition: Transition.fade),

    GetPage(
      name: RouteNames.setting,
      page: () => Setting(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteNames.editProfile,
      page: () => const EditProfile(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: RouteNames.addComment,
      page: () => const AddComment(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: RouteNames.showThread,
      page: () => const ShowThread(),
      transition: Transition.leftToRightWithFade,
    ),
    GetPage(
      name: RouteNames.showImage,
      page: () => ShowImage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: RouteNames.showProfile,
      page: () => const ShowProfile(),
      binding: ProfileBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: RouteNames.followers,
      page: () => FollowersList(userId: Get.arguments),
      binding: FollowersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RouteNames.contactUs,
      page: () => const ContactUs(),
      transition: Transition.rightToLeft,
    ),
  ];
}