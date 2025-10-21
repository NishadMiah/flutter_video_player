import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class BetterVideoController extends GetxController {
  late BetterPlayerController betterPlayerController;
  Timer? _hideControlsTimer;

  // Observable variables
  final isInitialized = false.obs;
  final isPlaying = false.obs;
  final showControls = true.obs;
  final showBrightnessControl = false.obs;
  final showVolumeControl = false.obs;
  final showLockOverlay = false.obs;
  final isLocked = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final playbackSpeed = 1.0.obs;
  final brightness = 0.5.obs;
  final volume = 1.0.obs;
  final currentEpisode = 'S01E01 - Daybreak'.obs;
  final episodes = <String>[].obs;

  final String videoUrl;
  final bool isLive;

  BetterVideoController({required this.videoUrl, this.isLive = false});

  @override
  void onInit() {
    super.onInit();
    _initializeVideo();
    episodes.value = [
      'S01E01 - Daybreak',
      'S01E02 - Kill the Messenger',
      'S01E03 - No Good Horses',
    ];
    _initializeBrightnessAndVolume();
  }

  Future<void> _initializeVideo() async {
    final isHls = videoUrl.toLowerCase().endsWith('.m3u8');
    debugPrint("Loading video: $videoUrl | isHls=$isHls | isLive=$isLive");

    final config = BetterPlayerConfiguration(
      autoPlay: false,
      looping: !isLive,
      aspectRatio: 16 / 9,
      fit: BoxFit.cover,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false, // Disable default controls
      ),
    );

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoUrl,
      liveStream: isLive,
      videoFormat: isHls ? BetterPlayerVideoFormat.hls : BetterPlayerVideoFormat.other,
      headers: {"User-Agent": "BetterPlayer"},
    );

    betterPlayerController = BetterPlayerController(config);

    betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        isPlaying.value = true;
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        isPlaying.value = false;
      } else if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        currentPosition.value = betterPlayerController.videoPlayerController?.value.position ?? Duration.zero;
        totalDuration.value = betterPlayerController.videoPlayerController?.value.duration ?? Duration.zero;
      } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        debugPrint("BetterPlayer error: ${event.parameters}");
      }
    });

    try {
      await betterPlayerController.setupDataSource(dataSource);
      isInitialized.value = true;
      betterPlayerController.pause();
      await betterPlayerController.setVolume(volume.value);
      await betterPlayerController.setSpeed(playbackSpeed.value);
    } catch (e) {
      debugPrint("Error setting up video source: $e");
      _showSnackbar('Failed to load video: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _initializeBrightnessAndVolume() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      final currentVolume = await VolumeController.instance.getVolume();
      brightness.value = currentBrightness.clamp(0.0, 1.0);
      volume.value = currentVolume.clamp(0.0, 1.0);
      VolumeController.instance.showSystemUI = false;
    } catch (e) {
      debugPrint("Error initializing brightness/volume: $e");
    }
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      betterPlayerController.pause();
      showControls.value = true;
      _cancelHideControlsTimer();
    } else {
      betterPlayerController.play();
      _startHideControlsTimer();
    }
  }

  void seekForward() {
    final newPosition = currentPosition.value + const Duration(seconds: 10);
    seekTo(newPosition < totalDuration.value ? newPosition : totalDuration.value);
  }

  void seekBackward() {
    final newPosition = currentPosition.value - const Duration(seconds: 10);
    seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void seekTo(Duration position) {
    betterPlayerController.seekTo(position);
    _startHideControlsTimer();
  }

  void changePlaybackSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(playbackSpeed.value);
    playbackSpeed.value = speeds[(currentIndex + 1) % speeds.length];
    betterPlayerController.setSpeed(playbackSpeed.value);
    _showSnackbar('Speed: ${playbackSpeed.value}x');
    _startHideControlsTimer();
  }

  void adjustBrightness(double value) async {
    brightness.value = value.clamp(0.0, 1.0);
    showBrightnessControl.value = true;
    await ScreenBrightness().setScreenBrightness(brightness.value);
    HapticFeedback.lightImpact();
    _startHideControlsTimer();
  }

  void adjustVolume(double value) async {
    volume.value = value.clamp(0.0, 1.0);
    await VolumeController.instance.setVolume(volume.value);
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

  void toggleLock() {
    isLocked.value = !isLocked.value;
    showControls.value = false;
    showLockOverlay.value = true;
    _showSnackbar(isLocked.value ? 'Screen locked' : 'Screen unlocked');
    _startHideControlsTimer();
  }

  void toggleLockOverlay() {
    showLockOverlay.value = !showLockOverlay.value;
    if (showLockOverlay.value) {
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
        showLockOverlay.value = false;
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

  void _showSnackbar(String message, {Color backgroundColor = Colors.black54}) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 1),
        backgroundColor: backgroundColor,
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
    betterPlayerController.dispose();
    VolumeController.instance.showSystemUI = true;
    super.onClose();
  }
}