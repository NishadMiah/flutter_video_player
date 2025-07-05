import 'package:flutter_video_player/view/screens/video/controller/video_controller.dart';
import 'package:get/get.dart';
 

class DependencyInjection extends Bindings {
  @override
  void dependencies() {
 
    Get.lazyPut(() => VideoController(), fenix: true);
  }
}
