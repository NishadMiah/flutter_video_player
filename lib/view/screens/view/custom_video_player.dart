import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_player/view/screens/controller/custom_video_player_controller.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  @override
  _CustomVideoPlayerState createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  final controller = Get.put(CustomVideoPlayerController());
  bool _isDraggingBrightness = false;
  bool _isDraggingVolume = false;

  @override
  void initState() {
    super.initState();
    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientations when leaving
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
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        return Stack(
          children: [
            // Video Player (Full Screen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (!_isDraggingBrightness && !_isDraggingVolume) {
                    controller.toggleControls();
                  }
                },
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller
                              .videoPlayerController!
                              .value
                              .aspectRatio,
                          child: VideoPlayer(controller.videoPlayerController!),
                        ),
                      ),
                      // Brightness overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black.withOpacity(
                              1 - controller.brightness.value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls Overlay
            if (controller.showControls.value)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: [0, 0.15, 0.85, 1],
                  ),
                ),
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildCenterControls()),
                    _buildBottomControls(),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Get.back(),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Obx(
              () => Text(
                'EN - Yellowstone (2018) - ${controller.currentEpisode.value}',
                style: TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.cast, color: Colors.white, size: 22),
            onPressed: () {},
          ),

          IconButton(
            icon: Icon(Icons.lock_open, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      children: [
        // Brightness Control (Left Side)
        Obx(
          () => AnimatedOpacity(
            opacity: controller.showBrightnessControl.value ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Visibility(
              visible: controller.showBrightnessControl.value,
              child: Container(
                width: 100,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.brightness_6, color: Colors.white, size: 30),
                    SizedBox(height: 12),
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
                              heightFactor: controller.brightness.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${(controller.brightness.value * 100).toInt()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onVerticalDragStart: (details) {
            setState(() {
              _isDraggingBrightness = true;
            });
            controller.showBrightnessControl.value = true;
          },
          onVerticalDragUpdate: (details) {
            final sensitivity = 0.005;
            final change = -details.delta.dy * sensitivity;
            controller.adjustBrightness(controller.brightness.value + change);
          },
          onVerticalDragEnd: (details) {
            setState(() {
              _isDraggingBrightness = false;
            });
          },
          child: Container(width: 100, color: Colors.transparent),
        ),

        Spacer(),

        // Play/Pause Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: controller.seekBackward,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_10, color: Colors.white, size: 36),
                    SizedBox(height: 2),
                    Text(
                      '-10s',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 35),
            GestureDetector(
              onTap: controller.togglePlayPause,
              child: Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Obx(
                  () => Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            SizedBox(width: 35),
            GestureDetector(
              onTap: controller.seekForward,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward_10, color: Colors.white, size: 36),
                    SizedBox(height: 2),
                    Text(
                      '+10s',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        Spacer(),

        // Volume Control (Right Side)
        Obx(
          () => AnimatedOpacity(
            opacity: controller.showVolumeControl.value ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Visibility(
              visible: controller.showVolumeControl.value,
              child: Container(
                width: 100,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.volume.value == 0
                          ? Icons.volume_off
                          : controller.volume.value < 0.5
                          ? Icons.volume_down
                          : Icons.volume_up,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(height: 12),
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
                              heightFactor: controller.volume.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${(controller.volume.value * 100).toInt()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onVerticalDragStart: (details) {
            setState(() {
              _isDraggingVolume = true;
            });
            controller.showVolumeControl.value = true;
          },
          onVerticalDragUpdate: (details) {
            final sensitivity = 0.005;
            final change = -details.delta.dy * sensitivity;
            controller.adjustVolume(controller.volume.value + change);
          },
          onVerticalDragEnd: (details) {
            setState(() {
              _isDraggingVolume = false;
            });
          },
          child: Container(width: 100, color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Obx(
                () => Text(
                  controller.formatDuration(controller.currentPosition.value),
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Expanded(
                child: Obx(
                  () => SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: controller.currentPosition.value.inSeconds
                          .toDouble(),
                      min: 0,
                      max:
                          controller.totalDuration.value.inSeconds.toDouble() >
                              0
                          ? controller.totalDuration.value.inSeconds.toDouble()
                          : 1,
                      onChanged: (value) {
                        controller.seekToPosition(
                          Duration(seconds: value.toInt()),
                        );
                      },
                      activeColor: Colors.red,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Obx(
                () => Text(
                  controller.formatDuration(controller.totalDuration.value),
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Bottom Buttons
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomButton(
                Icons.video_library,
                'Episodes',
                controller.showEpisodeList,
              ),
              _buildBottomButton(
                Icons.aspect_ratio,
                'Aspect Ratio',
                controller.changeAspectRatio,
              ),
              GestureDetector(
                onTap: controller.changePlaybackSpeed,
                child: Obx(
                  () => _buildBottomButton(
                    Icons.speed,
                    'Speed (${controller.playbackSpeed.value}x)',
                    null,
                  ),
                ),
              ),
              _buildBottomButton(
                Icons.skip_next,
                'Next Episode',
                controller.nextEpisode,
              ),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
