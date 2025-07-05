import 'package:flutter_video_player/view/screens/video/view/video_screen.dart';
import 'package:get/get.dart';

class AppRoutes {
  //========== saller video ================
  static const String videoScreen = "/VideoScreen";

  static List<GetPage> routes = [
    //========== saller video ================
    GetPage(name: videoScreen, page: () => VideoScreen()),
  ];
}
