import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_player/view/screens/controller/custom_video_player_controller.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({super.key});

  @override
  _CustomVideoPlayerState createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  final controller = Get.find<CustomVideoPlayerController>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        return GestureDetector(
          onTap: controller.isLocked.value ? controller.toggleLockOverlay : controller.toggleControls,
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(controller.videoPlayerController!),
                ),
              ),
              Positioned.fill(
                child: Obx(
                  () => IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(1 - controller.brightness.value),
                    ),
                  ),
                ),
              ),
              Obx(
                () => AnimatedOpacity(
                  opacity: controller.isLocked.value && !controller.showLockOverlay.value
                      ? 0.0
                      : controller.showControls.value && !controller.isLocked.value
                          ? 1.0
                          : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildControlsOverlay(),
                ),
              ),
              Obx(
                () => controller.isLocked.value && controller.showLockOverlay.value
                    ? _buildLockOverlay()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.transparent,
            Colors.black54,
          ],
          stops: [0, 0.15, 0.85, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildCenterControls()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.lock_open, color: Colors.white, size: 32),
          onPressed: controller.toggleLock,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: controller.isLocked.value ? null : Get.back,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(
              () => Text(
                'EN - Yellowstone (2018) - ${controller.currentEpisode.value}',
                style: const TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white, size: 22),
            onPressed: controller.isLocked.value ? null : () => _showNotImplementedSnackbar(),
          ),
          IconButton(
            icon: Obx(
              () => Icon(
                controller.isLocked.value ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 22,
              ),
            ),
            onPressed: controller.toggleLock,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
            onPressed: controller.isLocked.value ? null : () => _showNotImplementedSnackbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      children: [
        _buildGestureControl(
          width: 100,
          showControl: controller.showBrightnessControl,
          value: controller.brightness,
          icon: Icons.brightness_6,
          onDragUpdate: controller.isLocked.value ? (_) {} : controller.adjustBrightness,
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              icon: Icons.replay_10,
              label: '-10s',
              onTap: controller.isLocked.value ? () {} : controller.seekBackward,
            ),
            const SizedBox(width: 35),
            Obx(
              () => GestureDetector(
                onTap: controller.isLocked.value ? () {} : controller.togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 35),
            _buildControlButton(
              icon: Icons.forward_10,
              label: '+10s',
              onTap: controller.isLocked.value ? () {} : controller.seekForward,
            ),
          ],
        ),
        const Spacer(),
        _buildGestureControl(
          width: 100,
          showControl: controller.showVolumeControl,
          value: controller.volume,
          icon: controller.volume.value == 0
              ? Icons.volume_off
              : controller.volume.value < 0.5
                  ? Icons.volume_down
                  : Icons.volume_up,
          onDragUpdate: controller.isLocked.value ? (_) {} : controller.adjustVolume,
        ),
      ],
    );
  }

  Widget _buildGestureControl({
    required double width,
    required RxBool showControl,
    required RxDouble value,
    required IconData icon,
    required Function(double) onDragUpdate,
  }) {
    return GestureDetector(
      onVerticalDragStart: controller.isLocked.value ? null : (_) => showControl.value = true,
      onVerticalDragUpdate: controller.isLocked.value
          ? null
          : (details) {
              final sensitivity = 0.005;
              onDragUpdate(value.value - details.delta.dy * sensitivity);
            },
      onVerticalDragEnd: controller.isLocked.value ? null : (_) => controller.hideControlAfterDelay(showControl),
      child: Container(
        width: width,
        color: Colors.transparent,
        child: Obx(
          () => AnimatedOpacity(
            opacity: showControl.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  width: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: value.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xCCFFFFFF), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(value.value * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Obx(
                () => Text(
                  controller.formatDuration(controller.currentPosition.value),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Expanded(
                child: Obx(
                  () => SliderTheme(
                    data: const SliderThemeData(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: controller.currentPosition.value.inSeconds.toDouble(),
                      min: 0,
                      max: controller.totalDuration.value.inSeconds.toDouble(),
                      onChanged: controller.isLocked.value
                          ? null
                          : (value) => controller.seekToPosition(Duration(seconds: value.toInt())),
                      activeColor: Colors.red,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Obx(
                () => Text(
                  controller.formatDuration(controller.totalDuration.value),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomButton(Icons.video_library, 'Episodes', controller.isLocked.value ? () {} : controller.showEpisodeList),
              _buildBottomButton(Icons.aspect_ratio, 'Aspect Ratio', controller.isLocked.value ? () {} : controller.changeAspectRatio),
              Obx(
                () => _buildBottomButton(
                  Icons.speed,
                  'Speed (${controller.playbackSpeed.value}x)',
                  controller.isLocked.value ? () {} : controller.changePlaybackSpeed,
                ),
              ),
              _buildBottomButton(Icons.skip_next, 'Next Episode', controller.isLocked.value ? () {} : controller.nextEpisode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showNotImplementedSnackbar() {
    Get.showSnackbar(
      const GetSnackBar(
        message: 'Feature not implemented',
        duration: Duration(seconds: 1),
        backgroundColor: Colors.black54,
      ),
    );
  }
}