import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';

class PopClickers {
  Widget leading;
  Widget title;
  Function() onTap;

  PopClickers({
    required this.leading,
    required this.title,
    required this.onTap,
  });
}

bildPopupMenu({required Icon icon, required List<PopClickers> popItems}) {
  return PopupMenuButton(
    icon: icon,
    color: Colors.black.withOpacity(0.75),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(bsm * 2),
      side: BorderSide(width: bdrWidthGen, color: lqassbdrColor),
    ),
    itemBuilder: (context) {
      return List.generate(popItems.length, (index) {
        return PopupMenuItem(
          onTap: popItems[index].onTap,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.only(left: psm * 2),
                leading: popItems[index].leading,
                title: popItems[index].title,
              ),
              if (index < popItems.length - 1) Divider(thickness: 0.35),
            ],
          ),
        );
      });
    },
  );
}
