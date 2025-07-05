import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_video_player/utils/app_colors/app_colors.dart';

class VideoHeader extends StatelessWidget implements PreferredSizeWidget {
  const VideoHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 50.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent.withAlpha(200),
            ),
            child: Icon(
              Icons.outlined_flag_outlined,
              size: 24.sp,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(110.h);
}
