import 'package:flutter/material.dart';

class PersianTextField extends StatelessWidget {
  String text;
  double? textSize;
  FontWeight? fontWeight;
  Color? color;
  PersianTextField(
      {required this.text, this.textSize, this.fontWeight, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(
          fontFamily: 'vazir',
          fontWeight: fontWeight,
          fontSize: textSize,
          color: color),
    );
  }
}
