import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
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
      appBar: AppBar(),
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
                  if (isJPrime(string: value)) {
                    var pstr = parseJPrl(value);
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

  isJPrime({String? string}) {
    if (string!.startsWith(hfweb)) {
      return true;
    } else {
      return false;
    }
  }

  parseJPrl(String url) {
    List parts = url.split('/lv0/');
    if (parts.length > 1) {
      List dparts = parts.last.split('/');
      return dparts;
    } else {
      return null;
    }
  }

  fAttendee({attId}) {
    var docRef = firestore
        .collection(ecol)
        .doc(widget.eId)
        .collection(atcol)
        .doc(attId);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: psm * 4,
        left: psm,
        right: psm,
        bottom: psm,
      ),
      child: StreamBuilder(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = (snapshot.data as dynamic).data();
            if (data != null) {
              Attendee attendee = Attendee.fromMap(attId, data);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Scan Results",
                    style: TextStyle(
                      fontSize: fsm * 1.75,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: psm * 1.5),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(
                      top: psm * 1.5,
                      left: psm * 0.5,
                      right: psm * 0.5,
                      bottom: psm * 1.5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(bsm),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: psm * 2.5,
                          child: Brand(Brands.instagram_verification_badge),
                        ),
                        const SizedBox(height: psm),
                        Text(
                          attendee.fullName,
                          style: const TextStyle(
                            fontSize: fsm,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: psm * 0.5),
                        Text(
                          attendee.cardName,
                          style: const TextStyle(
                            fontSize: fsm,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: psm),
                        CupertinoListSection.insetGrouped(
                          margin: EdgeInsets.zero,
                          children: List.generate(attendee.checkinStatus.length, (
                            idx,
                          ) {
                            var atSts = attendee.checkinStatus[idx];
                            var actlStatus =
                                atSts[crdChkpns][widget.chckpntId] ?? false;
                            return CupertinoListTile(
                              padding: const EdgeInsets.only(left: psm),
                              title: Text(
                                "${atSts[cattendeename]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  text: "Status: ",
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  ),
                                  children: [
                                    actlStatus
                                        ? const TextSpan(
                                          text: "Checkedin",
                                          style: TextStyle(color: Colors.green),
                                        )
                                        : TextSpan(
                                          text: "Not Checkedin",
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  if (!actlStatus) {
                                    attendee.checkinStatus[idx][crdChkpns][widget
                                            .chckpntId] =
                                        true;
                                    docRef.update({
                                      "checkinStatus": attendee.checkinStatus,
                                    });
                                  } else {
                                    await showCheckout(
                                      idx: idx,
                                      attendee: attendee,
                                      docRef: docRef,
                                    );
                                  }
                                },
                                child: Text(
                                  !actlStatus ? "Checkin" : 'Checked-in',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: psm * 2),
                  SizedBox(
                    width: double.maxFinite,
                    child: MaterialButton(
                      onPressed: () async {
                        await controller.start();
                      },
                      color: primaryColor,
                      height: kToolbarHeight * 0.8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(bsm),
                      ),
                      child: const Text(
                        "Continue Scanning",
                        style: TextStyle(fontSize: fsm, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return buildErr();
            }
          } else if (snapshot.hasError) {
            return buildErr();
          } else {
            return buildLoader();
          }
        },
      ),
    );
  }

  showCheckout({idx, docRef, attendee}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Checkout"),
          content: const Text("Are you sure you want to checkout?"),
          actions: [
            CupertinoButton(
              color: primaryColor,
              onPressed: () {
                attendee.checkinStatus[idx][crdChkpns][widget.chckpntId] =
                    false;
                docRef.update({"checkinStatus": attendee.checkinStatus});
                Navigator.pop(context);
              },
              child: const Text(
                "Checkout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
