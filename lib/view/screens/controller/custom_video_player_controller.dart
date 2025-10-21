import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayerController extends GetxController {
  VideoPlayerController? videoPlayerController;
  Timer? _hideControlsTimer;
  Timer? _hideBrightnessTimer;
  Timer? _hideVolumeTimer;

  // Observable variables
  var isPlaying = false.obs;
  var isLoading = true.obs;
  var showControls = true.obs;
  var showBrightnessControl = false.obs;
  var showVolumeControl = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var playbackSpeed = 1.0.obs;
  var brightness = 0.5.obs;
  var volume = 1.0.obs;

  // Episode info
  var currentEpisode = 'S01E01 - Daybreak'.obs;
  var episodes = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeVideo();

    // Sample episodes
    episodes.value = [
      'S01E01 - Daybreak',
      'S01E02 - Kill the Messenger',
      'S01E03 - No Good Horses',
    ];
  }

  Future<void> initializeVideo() async {
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
    );

    try {
      await videoPlayerController!.initialize();
      isLoading.value = false;
      totalDuration.value = videoPlayerController!.value.duration;
      videoPlayerController!.setVolume(volume.value);
      videoPlayerController!.addListener(() {
        if (videoPlayerController!.value.isInitialized) {
          currentPosition.value = videoPlayerController!.value.position;
          isPlaying.value = videoPlayerController!.value.isPlaying;
        }
      });
      // Start video paused to allow user interaction
      videoPlayerController!.pause();
    } catch (e) {
      print('Error initializing video: $e');
      isLoading.value = false;
    }
  }

  void togglePlayPause() {
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
      showControls.value = true;
      _cancelHideControlsTimer();
    } else {
      videoPlayerController!.play();
      _startHideControlsTimer();
    }
    update();
  }

  void seekForward() {
    final newPosition = currentPosition.value + const Duration(seconds: 10);
    if (newPosition < totalDuration.value) {
      videoPlayerController!.seekTo(newPosition);
    } else {
      videoPlayerController!.seekTo(totalDuration.value);
    }
    _startHideControlsTimer();
  }

  void seekBackward() {
    final newPosition = currentPosition.value - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      videoPlayerController!.seekTo(newPosition);
    } else {
      videoPlayerController!.seekTo(Duration.zero);
    }
    _startHideControlsTimer();
  }

  void seekToPosition(Duration position) {
    videoPlayerController!.seekTo(position);
    _startHideControlsTimer();
  }

  void changePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(playbackSpeed.value);
    final nextIndex = (currentIndex + 1) % speeds.length;
    playbackSpeed.value = speeds[nextIndex];
    videoPlayerController!.setPlaybackSpeed(playbackSpeed.value);
    Get.showSnackbar(
      GetSnackBar(
        message: 'Speed: ${playbackSpeed.value}x',
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black54,
      ),
    );
    _startHideControlsTimer();
  }

  void adjustBrightness(double value) {
    brightness.value = value.clamp(0.0, 1.0);
    showBrightnessControl.value = true;
    _startHideBrightnessTimer();
  }

  void adjustVolume(double value) {
    volume.value = value.clamp(0.0, 1.0);
    videoPlayerController?.setVolume(volume.value);
    showVolumeControl.value = true;
    _startHideVolumeTimer();
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value && isPlaying.value) {
      _startHideControlsTimer();
    } else {
      _cancelHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (isPlaying.value) {
        showControls.value = false;
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _startHideBrightnessTimer() {
    _hideBrightnessTimer?.cancel();
    _hideBrightnessTimer = Timer(const Duration(seconds: 2), () {
      showBrightnessControl.value = false;
    });
  }

  void _startHideVolumeTimer() {
    _hideVolumeTimer?.cancel();
    _hideVolumeTimer = Timer(const Duration(seconds: 2), () {
      showVolumeControl.value = false;
    });
  }

  void nextEpisode() {
    Get.showSnackbar(
      const GetSnackBar(
        message: 'Loading next episode...',
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black54,
      ),
    );
  }

  void showEpisodeList() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Episodes',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...episodes.map((ep) => ListTile(
                    title: Text(ep, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      currentEpisode.value = ep;
                      Get.back();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void changeAspectRatio() {
    Get.showSnackbar(
      const GetSnackBar(
        message: 'Aspect ratio changed',
        duration: Duration(seconds: 1),
        backgroundColor: Colors.black54,
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  void onClose() {
    _cancelHideControlsTimer();
    _hideBrightnessTimer?.cancel();
    _hideVolumeTimer?.cancel();
    videoPlayerController?.dispose();
    super.onClose();
  }
}