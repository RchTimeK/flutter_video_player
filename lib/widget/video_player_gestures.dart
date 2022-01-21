/// Created by RongCheng on 2022/1/19.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rc_video_player/other/temp_value.dart';
import 'package:flutter_rc_video_player/utils/video_player_utils.dart';
class VideoPlayerGestures extends StatefulWidget {
  const VideoPlayerGestures({Key? key,required this.children,required this.appearCallback}) : super(key: key);
  final List<Widget> children;
  final Function(bool) appearCallback;
  @override
  _VideoPlayerGesturesState createState() => _VideoPlayerGesturesState();
}

class _VideoPlayerGesturesState extends State<VideoPlayerGestures> {

  bool _appear = true; // 控件隐藏与显示
  Timer? _timer;
  double _width = 0.0; // 组件宽度
  double _height = 0.0; // 组件高度
  late Offset _startPanOffset; //  滑动的起始位置
  late double _movePan; // 滑动的偏移量累计总和
  bool _brightnessOk = false; // 是否允许调节亮度
  bool _volumeOk = false; // 是否允许调节亮度
  bool _seekOk = false; // 是否允许调节播放进度
  double _brightnessValue = 0.0; // 设备当前的亮度
  double _volumeValue = 0.0; // 设备本身的音量
  Duration _positionValue = const Duration(seconds: 0); // 当前播放时间，以计算手势快进或快退
  late PercentageWidget _percentageWidget; // 快退、快进、音量、亮度的百分比，手势操作时显示的widget
  final List<Widget> _children = [];
  @override
  void initState(){
    // TODO: implement initState
    _percentageWidget = PercentageWidget();
    _children.addAll(widget.children);
    _children.add(_percentageWidget);
    super.initState();
    _setInit();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap, // 单击上下widget隐藏与显示
      onDoubleTap: _onDoubleTap, // 双击暂停、播放
      onVerticalDragStart:_onVerticalDragStart, // 根据起始位置。确定是调整亮度还是调整声音
      onVerticalDragUpdate: _onVerticalDragUpdate,// 一般在更新的时候，同步调整亮度或声音
      onVerticalDragEnd: _onVerticalDragEnd, // 结束后，隐藏百分比提示信息widget
      onHorizontalDragStart: _onHorizontalDragStart,  // 手势跳转播放起始位置
      onHorizontalDragUpdate: _onHorizontalDragUpdate, // 根据手势更新快进或快退
      onHorizontalDragEnd: _onHorizontalDragEnd,  // 手势结束seekTo
      child: Stack(
        children: _children,
      ),
    );
  }

  void _setInit() async{
    _volumeValue = await VideoPlayerUtils.getVolume();
    _brightnessValue = await VideoPlayerUtils.getBrightness();
  }

  void _onTap(){
    if(TempValue.isLocked) return;
    _appear = !_appear;
    widget.appearCallback(_appear);
    // 开启定时器，已经显示并且正在播放，才会在3s后自动隐藏（偷个懒，用户单击过以后才会触发这类效果）
    if(_appear == true && VideoPlayerUtils.state == VideoPlayerState.playing){
      _setupTimer();
    }
  }

  void _onDoubleTap(){
    if(TempValue.isLocked) return;
    VideoPlayerUtils.playerHandle(VideoPlayerUtils.url);
  }

  void _onVerticalDragStart(DragStartDetails details){
    if(TempValue.isLocked) return;
    if(!VideoPlayerUtils.isInitialized) return;
    _resetPan();
    _startPanOffset = details.globalPosition;
    if(_startPanOffset.dx < _width*0.5){ // 左边调整亮度
      _brightnessOk = true;
    }else{ // 右边调整声音
      _volumeOk = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details){
    if(TempValue.isLocked) return;
    // 累计计算偏移量(下滑减少百分比，上滑增加百分比)
    _movePan += (-details.delta.dy);
    if (_startPanOffset.dx < (_width / 2)){
      if(_brightnessOk){
        double b = _getBrightnessValue();
        _percentageWidget.percentageCallback("亮度：${(b * 100).toInt()}%");
        VideoPlayerUtils.setBrightness(b);
      }
    }else{
      if(_volumeOk){
        double v = _getVolumeValue();
        _percentageWidget.percentageCallback("音量：${(v * 100).toInt()}%");
        VideoPlayerUtils.setVolume(v);
      }
    }
  }

  void _onVerticalDragEnd(_){
    if(TempValue.isLocked) return;
    // 隐藏
    _percentageWidget.offstageCallback(true);
    if(_volumeOk){
      _volumeValue = _getVolumeValue();
      _volumeOk = false;
    }else if(_brightnessOk){
      _brightnessValue = _getBrightnessValue();
      _brightnessOk = false;
    }
  }

  void _onHorizontalDragStart(DragStartDetails details){
    if(TempValue.isLocked) return;
    if(!VideoPlayerUtils.isInitialized) return;
    _resetPan();
    _positionValue = VideoPlayerUtils.position;
    _seekOk = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details){
    if(TempValue.isLocked) return;
    if(!_seekOk) return;
    _movePan += details.delta.dx;
    double value = _getSeekValue();
    String currentSecond = VideoPlayerUtils.formatDuration((value * VideoPlayerUtils.duration.inSeconds).toInt());
    if(_movePan >= 0){
      _percentageWidget.percentageCallback("快进至：$currentSecond");
    }else{
      _percentageWidget.percentageCallback("快退至：$currentSecond");
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if(TempValue.isLocked) return;
    if(!_seekOk) return;
    double value = _getSeekValue();
    int seek = (value * VideoPlayerUtils.duration.inMilliseconds).toInt();
    VideoPlayerUtils.seekTo(position: Duration(milliseconds: seek));
    _percentageWidget.offstageCallback(true);
    _seekOk = false;
  }

  // 计算亮度百分比
  double _getBrightnessValue(){
    double value = double.parse((_movePan / _height + _brightnessValue).toStringAsFixed(2));
    if (value >= 1.00) {
      value = 1.00;
    } else if (value <= 0.00) {
      value = 0.00;
    }
    return value;
  }

  // 计算声音百分比
  double _getVolumeValue() {
    double value = double.parse((_movePan / _height + _volumeValue).toStringAsFixed(2));
    if (value >= 1.0) {
      value = 1.0;
    } else if (value <= 0.0) {
      value = 0.0;
    }
    return value;
  }
  // 计算播放进度百分比
  double _getSeekValue(){
    // 进度条百分控制
    double valueHorizontal = double.parse((_movePan / _width).toStringAsFixed(2));
    // 当前进度条百分比
    double currentValue = _positionValue.inMilliseconds / VideoPlayerUtils.duration.inMilliseconds;
    double value = double.parse((currentValue + valueHorizontal).toStringAsFixed(2));
    if (value >= 1.00) {
      value = 1.00;
    } else if (value <= 0.00) {
      value = 0.00;
    }
    return value;
  }

  // 重置手势
  void _resetPan(){
    _startPanOffset = const Offset(0, 0);
    _movePan = 0;
    _width = context.size!.width;
    _height = context.size!.height;
  }

  // 开启定时器
  void _setupTimer(){
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), (){
      _appear = false;
      widget.appearCallback(_appear);
      _timer?.cancel();
    });
  }
}

// ignore: must_be_immutable
class PercentageWidget extends StatefulWidget {
  PercentageWidget({Key? key}) : super(key: key);
  late Function(String) percentageCallback; // 百分比
  late Function(bool) offstageCallback;
  @override
  _PercentageWidgetState createState() => _PercentageWidgetState();
}

class _PercentageWidgetState extends State<PercentageWidget> {
  String _percentage = ""; // 具体的百分比信息
  bool _offstage = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.percentageCallback = (percentage){
      _percentage = percentage;
      _offstage = false;
      if(!mounted) return;
      setState(() {});
    };
    widget.offstageCallback = (offstage){
      _offstage = offstage;
      if(!mounted) return;
      setState(() {});
    };
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Offstage(
        offstage: _offstage,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          child: Text(_percentage,style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }
}