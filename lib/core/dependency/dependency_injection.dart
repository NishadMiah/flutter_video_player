import 'package:flutter_video_player/view/screens/controller/custom_video_player_controller.dart';
import 'package:flutter_video_player/view/screens/controller/video_controller.dart';
import 'package:get/get.dart';
 

class DependencyInjection extends Bindings {
  @override
  void dependencies() {
 
    Get.lazyPut(() => VideoController(), fenix: true);
    Get.lazyPut(() => CustomVideoPlayerController(), fenix: true);
  }
}
