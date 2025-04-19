import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:repliq/views/home/home_page.dart';
import 'package:repliq/views/notification/notification.dart';
import 'package:repliq/views/profile/profile.dart';
import 'package:repliq/views/search/search.dart';
import 'package:repliq/views/threads/add_thread.dart';
import 'package:repliq/views/ai_chat/ai_chat.dart';

class NavigationService extends GetxService {
  RxInt currentIndex = 0.obs;
  RxInt previousIndex = 0.obs;

  void updateIndex(int index) {
    previousIndex.value = currentIndex.value;
    currentIndex.value = index;
  }

  void backToPrevIndex() {
    currentIndex.value = previousIndex.value;
  }

  List<Widget> pages() {
    return [
      HomePage(),
      const Search(),
      AddThread(),
      const AIChat(),
      const NotificationPage(),
      const Profile()
    ];
  }
}
