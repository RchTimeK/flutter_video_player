

import 'package:flutter/material.dart';
import 'package:flutter_rc_video_player/utils/video_player_utils.dart';
import 'package:flutter_rc_video_player/widget/video_player_page.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoPlayerPage(), // 不简单使用
    );
  }
}

// 简单使用
class VideoPlayerUI extends StatefulWidget {
  const VideoPlayerUI({Key? key}) : super(key: key);

  @override
  _VideoPlayerUIState createState() => _VideoPlayerUIState();
}

class _VideoPlayerUIState extends State<VideoPlayerUI> {
  Widget? _playerUI;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 播放视频
    VideoPlayerUtils.playerHandle("http://flv3.bn.netease.com/tvmrepo/2018/6/9/R/EDJTRAD9R/SD/EDJTRAD9R-mobile.mp4");
    // 播放新视频，初始化监听
    VideoPlayerUtils.initializedListener(key: this, listener: (initialize,widget){
      if(initialize){
        _playerUI = widget;
        if(!mounted) return;
        setState(() {});
      }
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    VideoPlayerUtils.removeInitializedListener(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        width: 414,
        height: 414*9/16,
        color: Colors.black26,
        child: _playerUI ?? const CircularProgressIndicator(
          strokeWidth: 3,
        )
    );
  }
}
