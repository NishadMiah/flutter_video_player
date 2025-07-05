import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  late VideoPlayerController videoPlayerController;
  RxBool isInitialized = false.obs;
  RxBool isPlaying = false.obs;
  Rx<Duration> position = Duration.zero.obs;
  RxBool isMuted = false.obs;
  Rx<Duration> duration = Duration.zero.obs;

  Future<void> loadVideo(String url) async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await videoPlayerController.initialize();
    isInitialized.value = true;
    duration.value = videoPlayerController.value.duration;

    videoPlayerController.setLooping(true);
    videoPlayerController.play();
    isPlaying.value = true;

    // Listen to video position
    videoPlayerController.addListener(() {
      position.value = videoPlayerController.value.position;
      isPlaying.value = videoPlayerController.value.isPlaying;
    });
  }

  void togglePlayback() {
    if (videoPlayerController.value.isPlaying) {
      videoPlayerController.pause();
    } else {
      videoPlayerController.play();
    }
  }

  void seekTo(Duration newPosition) {
    videoPlayerController.seekTo(newPosition);
  }

  @override
  void onClose() {
    videoPlayerController.dispose();
    super.onClose();
  }
  
  void toggleMute() {
    if (isMuted.value) {
      videoPlayerController.setVolume(1.0);
      isMuted.value = false;
    } else {
      videoPlayerController.setVolume(0.0);
      isMuted.value = true;
    }
  }

  Rx<bool> isVisible = false.obs;
}
