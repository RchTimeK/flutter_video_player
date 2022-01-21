/// Created by RongCheng on 2022/1/20.

import 'package:flutter/material.dart';
import 'package:flutter_rc_video_player/other/temp_value.dart';


// ignore: must_be_immutable
class LockIcon extends StatefulWidget {
  LockIcon({Key? key,required this.lockCallback}) : super(key: key);
  final Function lockCallback;
  late Function(bool) opacityCallback;
  @override
  _LockIconState createState() => _LockIconState();
}

class _LockIconState extends State<LockIcon> {
  double _opacity = 1.0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.opacityCallback = (appear){
      if(TempValue.isLocked) return; // 如果当前isLocked，不会触发，防止快速点击误触
      _opacity = appear ? 1.0 : 0.0;
      if(!mounted) return;
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 250),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: (){
            TempValue.isLocked = !TempValue.isLocked;
            widget.lockCallback();
            if(!mounted) return;
            setState(() {});
          },
          icon: Icon(TempValue.isLocked?Icons.lock_outlined:Icons.lock_open_outlined,color: Colors.white,size: 25,),
        ),
      ),
    );
  }
}
