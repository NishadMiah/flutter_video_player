import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_video_player/core/app_routes/app_routes.dart';
import 'package:flutter_video_player/core/dependency/dependency_injection.dart';
import 'package:flutter_video_player/utils/app_colors/app_colors.dart';
import 'package:flutter_video_player/view/screens/view/better_video_player.dart';
import 'package:flutter_video_player/view/screens/view/custom_video_player.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: const Size(440, 956),
      child: GetMaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.backgroundClr,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: VideoPlayerMain(
          videoUrl:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        // defaultTransition: Transition.fadeIn,
        // transitionDuration: const Duration(milliseconds: 200),
        // initialRoute: AppRoutes.videoScreen,
        // getPages: AppRoutes.routes,
        initialBinding: DependencyInjection(),
      ),
    );
  }
}
