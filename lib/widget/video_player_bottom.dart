/// Created by RongCheng on 2022/1/19.

import 'package:flutter/material.dart';
import 'package:flutter_rc_video_player/other/temp_value.dart';
import 'package:flutter_rc_video_player/utils/video_player_utils.dart';
import 'package:flutter_rc_video_player/widget/video_player_slider.dart';
// ignore: must_be_immutable
class VideoPlayerBottom extends StatefulWidget {
  VideoPlayerBottom({Key? key}) : super(key: key);
  late Function(bool) opacityCallback;
  @override
  _VideoPlayerBottomState createState() => _VideoPlayerBottomState();
}

class _VideoPlayerBottomState extends State<VideoPlayerBottom> {
  double _opacity = TempValue.isLocked ? 0.0 : 1.0;  // 不能固定值，横竖屏触发会重置
  bool get _isFullScreen => MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.opacityCallback = (appear){
      _opacity = appear ? 1.0 : 0.0;
      if(!mounted) return;
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 250),
        child: Container(
          width: double.maxFinite,
          height: 40,
          padding: const EdgeInsets.only(right: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient( // 来点黑色到透明的渐变优雅一下
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color.fromRGBO(0, 0, 0, .7), Color.fromRGBO(0, 0, 0, 0)],
            ),
          ),
          child: Row(
            children: [
              const VideoPlayerButton(),
              const Expanded(
                child: VideoPlayerSlider(),
              ),
              Text("/${VideoPlayerUtils.formatDuration(VideoPlayerUtils.duration.inSeconds)}",style: const TextStyle(color: Colors.white,fontSize: 15),),
              const SizedBox(width: 5,),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: (){
                  if (_isFullScreen) {
                    VideoPlayerUtils.setPortrait();
                  } else {
                    VideoPlayerUtils.setLandscape();
                  }
                },
                icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,color: Colors.white,size: 32,),
              )
            ],
          ),
        ),
      ),
    );
  }
}
class VideoPlayerButton extends StatefulWidget {
  const VideoPlayerButton({Key? key}) : super(key: key);
  @override
  _VideoPlayerButtonState createState() => _VideoPlayerButtonState();
}

class _VideoPlayerButtonState extends State<VideoPlayerButton> with SingleTickerProviderStateMixin{

  late AnimationController _animationController;

  @override
  void initState() {
    // TODO: implement initState
    _animationController = AnimationController(vsync: this,duration: const Duration(milliseconds: 250));
    if(VideoPlayerUtils.state == VideoPlayerState.playing){
      _animationController.forward();
    }
    super.initState();
    ///播放状态监听
    VideoPlayerUtils.statusListener(key: this, listener: (state){
      if(state == VideoPlayerState.playing){
        _animationController.forward();
      }else{
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    VideoPlayerUtils.removeStatusListener(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => VideoPlayerUtils.playerHandle(VideoPlayerUtils.url),
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _animationController,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}