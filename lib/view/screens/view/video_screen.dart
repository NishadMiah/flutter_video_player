import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_video_player/view/screens/controller/video_controller.dart';
import 'package:flutter_video_player/view/screens/widgets/video_header.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import 'package:flutter_video_player/utils/app_colors/app_colors.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> videoUrls = [
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    ];

    return Scaffold(
      appBar: VideoHeader(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          final controller = Get.put(
            VideoController(),
            tag: 'video_$index',
            permanent: false,
          );

          // Load video only once
          if (!controller.isInitialized.value) {
            controller.loadVideo(videoUrls[index]);
          }

          return Obx(() {
            final duration = controller.duration.value;
            final position = controller.position.value;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Video
                controller.isInitialized.value
                    ? GestureDetector(
                        onTap: () {
                          controller.isVisible.value =
                              !controller.isVisible.value;
                        },
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller
                                .videoPlayerController
                                .value
                                .size
                                .width,
                            height: controller
                                .videoPlayerController
                                .value
                                .size
                                .height,
                            child: VideoPlayer(
                              controller.videoPlayerController,
                            ),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),

                // Play/Pause button
                controller.isVisible.value
                    ? Center(
                        child: GestureDetector(
                          onTap: controller.togglePlayback,
                          child: Container(
                            height: 50.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            child: Icon(
                              controller.isPlaying.value
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: AppColors.white,
                              size: 30.sp,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),

                // Progress Bar at bottom
                controller.isVisible.value
                    ? Positioned(
                        left: 20.w,
                        right: 20.w,
                        bottom: 30.h,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: position.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                          0.0,
                                          duration.inMilliseconds.toDouble(),
                                        ),
                                    max: duration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      controller.seekTo(
                                        Duration(milliseconds: value.toInt()),
                                      );
                                    },
                                    activeColor: AppColors.white,
                                    inactiveColor: Colors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: controller.toggleMute,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      controller.isMuted.value
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            Gap(10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            );
          });
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
