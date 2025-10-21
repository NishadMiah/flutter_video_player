import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayerController extends GetxController {
  VideoPlayerController? videoPlayerController;
  Timer? _hideControlsTimer;

  // Observable variables
  final isPlaying = false.obs;
  final isLoading = true.obs;
  final showControls = true.obs;
  final showBrightnessControl = false.obs;
  final showVolumeControl = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final playbackSpeed = 1.0.obs;
  final brightness = 0.5.obs;
  final volume = 1.0.obs;
  final currentEpisode = 'S01E01 - Daybreak'.obs;
  final episodes = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeVideo();
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
      videoPlayerController!.setPlaybackSpeed(playbackSpeed.value);
      videoPlayerController!.addListener(_updatePosition);
      videoPlayerController!.pause();
    } catch (e) {
      isLoading.value = false;
      Get.showSnackbar(
        GetSnackBar(
          message: 'Failed to load video: $e',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updatePosition() {
    if (videoPlayerController!.value.isInitialized) {
      currentPosition.value = videoPlayerController!.value.position;
      isPlaying.value = videoPlayerController!.value.isPlaying;
    }
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      videoPlayerController!.pause();
      showControls.value = true;
      _cancelHideControlsTimer();
    } else {
      videoPlayerController!.play();
      _startHideControlsTimer();
    }
  }

  void seekForward() {
    final newPosition = currentPosition.value + const Duration(seconds: 10);
    seekToPosition(newPosition < totalDuration.value ? newPosition : totalDuration.value);
  }

  void seekBackward() {
    final newPosition = currentPosition.value - const Duration(seconds: 10);
    seekToPosition(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void seekToPosition(Duration position) {
    videoPlayerController!.seekTo(position);
    _startHideControlsTimer();
  }

  void changePlaybackSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(playbackSpeed.value);
    playbackSpeed.value = speeds[(currentIndex + 1) % speeds.length];
    videoPlayerController!.setPlaybackSpeed(playbackSpeed.value);
    _showSnackbar('Speed: ${playbackSpeed.value}x');
    _startHideControlsTimer();
  }

  void adjustBrightness(double value) {
    brightness.value = value.clamp(0.0, 1.0);
    showBrightnessControl.value = true;
    HapticFeedback.lightImpact();
    _startHideControlsTimer();
  }

  void adjustVolume(double value) {
    volume.value = value.clamp(0.0, 1.0);
    videoPlayerController?.setVolume(volume.value);
    showVolumeControl.value = true;
    HapticFeedback.lightImpact();
    _startHideControlsTimer();
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value && isPlaying.value) {
      _startHideControlsTimer();
    } else {
      _cancelHideControlsTimer();
    }
  }

  void hideControlAfterDelay(RxBool control) {
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (isPlaying.value) {
        showControls.value = false;
        showBrightnessControl.value = false;
        showVolumeControl.value = false;
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
  }

  void nextEpisode() {
    _showSnackbar('Loading next episode...');
  }

  void showEpisodeList() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Episodes',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...episodes.map(
                (ep) => ListTile(
                  title: Text(ep, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    currentEpisode.value = ep;
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changeAspectRatio() {
    _showSnackbar('Aspect ratio changed');
  }

  void _showSnackbar(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black54,
      ),
    );
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  void onClose() {
    _cancelHideControlsTimer();
    videoPlayerController?.removeListener(_updatePosition);
    videoPlayerController?.dispose();
    super.onClose();
  }
}