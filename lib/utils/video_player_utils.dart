/// Created by RongCheng on 2022/1/17.

import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:brightness_volume/brightness_volume.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerUtils{

  ///  ---------------------  public -------------------------

  static String get url => _instance._url; // 当前播放的url
  static VideoPlayerState get state => _instance._state; // 当前播放状态
  static bool get isInitialized => _instance._isInitialized; // 视频是否已经完成初始化
  static Duration get duration => _instance._duration; // 视频总时长
  static Duration get position => _instance._position; // 当前视频播放进度
  static double get aspectRatio => _instance._aspectRatio; // 视频播放比例

  // 播放、暂停、切换视频等播放操作
  static void playerHandle(String url,{bool autoPlay = true,bool looping = false}) async{
    if(url == _instance._url){ //
      if(_instance._controller!.value.isPlaying){ // 播放中，点击暂停
        await _instance._controller!.pause();
        _instance._updatePlayerState(VideoPlayerState.paused);
      }else{ //  暂停中，点击播放
        await _instance._controller!.play();
        _instance._updatePlayerState(VideoPlayerState.playing);
      }
    }else{ // 新的播放
      if(url.isEmpty) return;
      // 重置播放器
      _instance._resetController();
      _instance._controller = VideoPlayerController.network(url);
      try {
        await _instance._controller!.initialize();
        _instance._isInitialized = true;
        _instance._url = url;
        _instance._controller!.addListener(_instance._positionListener);
        _instance._duration = _instance._controller!.value.duration;
        _instance._aspectRatio = _instance._controller!.value.aspectRatio;
        // 更新初始化结果
        _instance._updateInitialize(true);
        if(autoPlay == true){
          await _instance._controller!.play();
          _instance._updatePlayerState(VideoPlayerState.playing);
        }
        if(looping == true){
          _instance._controller!.setLooping(looping);
        }
      }catch(_){
        _instance._initializeError();
      }
    }
  }

  // 跳转播放
  static void seekTo({required Duration position}) async{
    if(_instance._controller == null || _instance._url.isEmpty) return;
    _instance._stopPosition = true;
    await _instance._controller!.seekTo(position);
    _instance._stopPosition = false;
  }

  // 初始化结果监听，回调2个参数：1、初始化是否成功，2、播放的widget，方便setState()
  static void initializedListener({required dynamic key,required Function(bool,Widget) listener}){
    ListenerInitializeModel model = ListenerInitializeModel.fromList([key,listener]);
    _instance._initializedPool.add(model);
  }

  // 移除初始化结果监听
  static void removeInitializedListener(dynamic key){
    _instance._initializedPool.removeWhere((element) => element.key == key);
  }

  // 播放状态监听
  static void statusListener({required dynamic key,required Function(VideoPlayerState) listener}){
    ListenerStateModel model = ListenerStateModel.fromList([key,listener]);
    _instance._statusPool.add(model);
  }

  // 移除播放状态监听
  static void removeStatusListener(dynamic key){
    _instance._statusPool.removeWhere((element) => element.key == key);
  }

  // 播放进度监听
  static void positionListener({required dynamic key,required Function(int) listener}){
    ListenerPositionModel model = ListenerPositionModel.fromList([key,listener]);
    _instance._positionPool.add(model);
  }

  // 移除播放进度监听
  static void removePositionListener(dynamic key){
    _instance._positionPool.removeWhere((element) => element.key == key);
  }

  // 获取音量
  static Future<double> getVolume() async{
    return await BVUtils.volume;
  }

  // 设置音量
  static Future<void> setVolume(double volume) async{
    return await BVUtils.setVolume(volume);
  }

  // 获取亮度
  static Future<double> getBrightness() async{
    return await BVUtils.brightness;
  }

  // 设置亮度
  static Future<void> setBrightness(double brightness) async{
    return await BVUtils.setBrightness(brightness);
  }

  // 设置播放速度
  static Future<void> setSpeed(double speed) async{
    return _instance._controller!.setPlaybackSpeed(speed);
  }

  // 设置是否循环播放
  static Future<void> setLooping(bool looping) async{
    return _instance._controller!.setLooping(looping);
  }

  // 设置横屏
  static setLandscape(){
    AutoOrientation.landscapeAutoMode();
    // iOS13+横屏时，状态栏自动隐藏，可自定义：https://juejin.cn/post/7054063406579449863
    if(Platform.isAndroid){
      ///关闭状态栏，与底部虚拟操作按钮
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  // 设置竖屏
  static setPortrait(){
    AutoOrientation.portraitAutoMode();
    if(Platform.isAndroid){
      ///显示状态栏，与底部虚拟操作按钮
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
  }

  // 简单处理下时间格式化mm:ss （超过1小时可自行处理hh:mm:ss）
  static String formatDuration(int second){
    int min = second ~/ 60;
    int sec = second % 60;
    String minString = min < 10 ? "0$min" : min.toString();
    String secString = sec < 10 ? "0$sec" : sec.toString();
    return minString+":"+secString;
  }

  // 释放资源
  static dispose(){
     _instance._url = "";
    _instance._controller?.removeListener(_instance._positionListener);
    _instance._statusPool.clear();
    _instance._positionPool.clear();
    _instance._initializedPool.clear();
    _instance._initializedPool.clear();
    _instance._state = VideoPlayerState.stopped;
    _instance._isInitialized = false;
    _instance._duration = const Duration(seconds: 0);
    _instance._secondPosition = 0;
    _instance._position = const Duration(seconds: 0);
    _instance._aspectRatio = 1.0;
    _instance._stopPosition = false;
    _instance._controller = null;
  }


  ///  ---------------------  private ------------------------

  String _url = "";
  VideoPlayerController? _controller;
  VideoPlayerState _state = VideoPlayerState.stopped;
  bool _isInitialized = false;
  Duration _duration = const Duration(seconds: 0);
  int _secondPosition = 0;
  Duration _position = const Duration(seconds: 0);
  double _aspectRatio = 1.0;
  bool _stopPosition = false; // 暂停进度监听，用于seekTo跳转播放缓冲时，Slider停止

  static final VideoPlayerUtils _instance = VideoPlayerUtils._internal();
  factory VideoPlayerUtils() => _instance;
  VideoPlayerUtils._internal(){
    _statusPool = [];
    _positionPool = [];
    _initializedPool = [];
  }
  // 初始化结果监听池
  late List<ListenerInitializeModel> _initializedPool;
  // 创建播放状态监听池
  late List<ListenerStateModel> _statusPool;
  // 播放进度监听池
  late List<ListenerPositionModel> _positionPool;

  // 更新初始化结果
  void _updateInitialize(initialize){
    _isInitialized = initialize;
    for(var element in _initializedPool){
      Widget widget = const SizedBox();
      if(initialize == true){
        widget = AspectRatio(
          aspectRatio: _aspectRatio,
          child: VideoPlayer(_controller!),
        );
      }
      element.listener(initialize,widget);
    }
  }

  // 播放监听器，这里主要监听播放进度
  // 因为播放进度可能在1秒内更新几次，取个巧，进度更新超过1秒再同步更新进度状态
  void _positionListener(){
    if (_stopPosition) return;
    _position = _controller!.value.position;
    int second = _controller!.value.position.inSeconds;
    if(_controller!.value.position == _duration){ // 播放结束
      if(_state != VideoPlayerState.completed){ // 保证结束回调只会调用一次
        _updatePlayerState(VideoPlayerState.completed);
      }
    }
    // 保证1s内只会调用用一次
    if(_secondPosition == second) return;
    _secondPosition = second;
    for(var element in _positionPool){
      element.listener(second);
    }
  }

  // 更新播放状态
  void _updatePlayerState(VideoPlayerState state){
    _state = state;
    for(var element in _statusPool){
      element.listener(state);
    }
  }

  // 重置播放器
  void _resetController(){
    if(_controller != null){
      if(_controller!.value.isPlaying){
        _controller!.pause();
      }
      _controller!.removeListener(_instance._positionListener);
      _controller!.dispose();
    }
    _url = "";
    _state = VideoPlayerState.stopped;
    _stopPosition = false;
  }
  // 初始化失败
  void _initializeError(){
    _state = VideoPlayerState.stopped;
    _updateInitialize(false);
  }
}

// 初始化结果监听模型
class ListenerInitializeModel{
  late dynamic key; /// 根据key标记是谁加入的通知，一般直接传widget就好
  late Function(bool,Widget) listener;
  /// 简单写一个构造方法
  ListenerInitializeModel.fromList(List list){
    key = list.first;
    listener = list.last;
  }
}

// 播放状态监听模型
class ListenerStateModel{
  late dynamic key; /// 根据key标记是谁加入的通知，一般直接传widget就好
  late Function(VideoPlayerState) listener;
  /// 简单写一个构造方法
  ListenerStateModel.fromList(List list){
    key = list.first;
    listener = list.last;
  }
}
// 播放进度监听模型
class ListenerPositionModel{
  late dynamic key; /// 根据key标记是谁加入的通知，一般直接传widget就好
  late Function(int) listener;
  /// 简单写一个构造方法
  ListenerPositionModel.fromList(List list){
    key = list.first;
    listener = list.last;
  }
}


/// 播放状态枚举
enum VideoPlayerState{
  stopped, // 初始状态，已停止或发生错误
  playing, // 正在播放
  paused,  // 暂停
  completed // 播放结束
}


