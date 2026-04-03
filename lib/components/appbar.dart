import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';

appBar({leading, title, titleWidget, actions}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight * 1.5),
    child: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 100,
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: psm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (leading != null) leading,
                        if (leading != null) const SizedBox(width: psm),
                        titleWidget ??
                            Text(
                              title ?? "",
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: fsm + 4,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                        const Spacer(),
                        if (actions != null) actions,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

uppBar({
  leading,
  lAction,
  centerTitle = true,
  title = '',
  actions = const <Widget>[],
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          backgroundColor: Colors.black.withOpacity(0.2),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: centerTitle,
          leadingWidth: 56,
          leading: leading,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          actions: actions,
        ),
      ),
    ),
  );
}

gsUppBack({context}) {
  return Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Center(
      child: gsFloatingButton(
        icon: Icons.arrow_back,
        onTap: () {
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

Widget gsFloatingButton({required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    ),
  );
}

Widget appBarActionButton({
  required IconData icon,
  required VoidCallback onTap,
  Color color = Colors.white,
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    ),
  );
}
