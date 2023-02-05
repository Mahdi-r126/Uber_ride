import 'package:flutter/material.dart';

import '../brand_colors.dart';

class TaxiButton extends StatelessWidget {
  final String title;
  final Color color;
  final void Function()? onPressed;
  const TaxiButton(
      {required this.title, this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      minWidth: double.infinity,
      height: 50,
      color: color,
      textColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Text(title, style: const TextStyle(fontFamily: "vazir")),
    );
  }
}
