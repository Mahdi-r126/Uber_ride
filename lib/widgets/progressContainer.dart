import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:uber/widgets/Text.dart';

import '../brand_colors.dart';

class ProgressbarBox extends StatelessWidget {
  const ProgressbarBox();

  @override
  Widget build(BuildContext context) {
    return Container(
                    margin: const EdgeInsets.only(top: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: BrandColors.colorGreen,
                          strokeWidth: 3,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        PersianTextField(
                          text: "در حال جستجوی مکان موردنظر شما",
                          textSize: 15,
                        ),
                      ],
                    ),
                  );
  }
}