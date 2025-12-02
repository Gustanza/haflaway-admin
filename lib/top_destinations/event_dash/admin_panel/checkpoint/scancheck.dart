import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/resolver.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/unidenifyd.dart';

class Scanner extends StatefulWidget {
  final List acIds;
  final String chckpntId;
  final String eId;

  const Scanner({
    super.key,
    required this.eId,
    required this.acIds,
    required this.chckpntId,
  });

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  late MobileScannerController controller;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ValueNotifier<String?> urlNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: ValueListenableBuilder<String?>(
              valueListenable: urlNotifier,
              builder: (context, value, child) {
                if (value == null) {
                  return const Center(child: CupertinoActivityIndicator());
                } else {
                  if (isHWay(string: value)) {
                    var pstr = parseHFrl(value);
                    if (pstr != null) {
                      return fAttendee(attId: pstr.last);
                    } else {
                      return UnIndenifyd(
                        onTap: () async {
                          await controller.start();
                        },
                      );
                    }
                  } else {
                    return UnIndenifyd(
                      onTap: () async {
                        await controller.start();
                      },
                    );
                  }
                }
              },
            ),
          ),
          MobileScanner(
            controller: controller,
            placeholderBuilder: (p0, p1) {
              return const Center(child: CircularProgressIndicator());
            },

            onDetect: (capture) async {
              Barcode? barcode = capture.barcodes.firstOrNull;
              if (barcode != null) {
                urlNotifier.value = barcode.rawValue;
                await controller.stop();
              }
            },
          ),
        ],
      ),
    );
  }

  isHWay({required String string}) {
    if (string.startsWith(hfweb)) {
      return true;
    } else {
      return false;
    }
  }

  parseHFrl(String url) {
    List parts = url.split('/lv0/');
    if (parts.length > 1) {
      List dparts = parts.last.split('/');
      return dparts;
    } else {
      return null;
    }
  }

  fAttendee({attId}) {
    return AttendeeCheckInView(
      attId: attId,
      chckpntId: widget.chckpntId,
      eId: widget.eId,
      onPressed: () async {
        await controller.start();
      },
    );
  }
}
