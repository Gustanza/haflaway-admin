import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/sheets.dart';

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

bildPopupMenu({required Widget icon, required List<PopClickers> popItems}) {
  return Builder(
    builder: (context) {
      return GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return modalBtmSheet(
                bdrdm: 20,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pull handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ...List.generate(popItems.length, (index) {
                        final item = popItems[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: IconTheme(
                                  data: const IconThemeData(
                                    color: Color(0xFFC9A84C),
                                    size: 22,
                                  ),
                                  child: item.leading,
                                ),
                                title: DefaultTextStyle(
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  child: item.title,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  item.onTap();
                                },
                              ),
                            ),
                            if (index < popItems.length - 1)
                              Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1,
                                thickness: 0.5,
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: IconTheme(
            data: const IconThemeData(color: Color(0xFFC9A84C), size: 22),
            child: icon,
          ),
        ),
      );
    },
  );
}
