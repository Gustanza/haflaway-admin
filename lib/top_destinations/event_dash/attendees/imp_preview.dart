import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/models/mchango.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xcl;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class ImpPreview extends StatefulWidget {
  final Event event;

  final KardType kardType;
  final List<Attendee>? atList;
  final String templateCardId;
  final Map<String, dynamic>? mapp;
  final Uint8List? xcelBytes;
  const ImpPreview({
    super.key,
    this.mapp,
    this.atList,
    this.xcelBytes,
    required this.event,
    required this.templateCardId,
    required this.kardType,
  });

  @override
  State<ImpPreview> createState() => _ImpPreviewState();
}

class _ImpPreviewState extends State<ImpPreview> {
  xcl.Excel? excel;
  List chk = [];
  List<Attendee> attendees = [];
  bool isLoading = false;
  bool hasError = false;
  bool isWritting = false;

  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.xcelBytes != null) {
      manouverExcel();
    } else {
      setAtList();
    }
  }

  setAtList() {
    if (mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    attendees = widget.atList ?? [];
    if (mounted) {
      setState(() {
        isLoading = false;
        hasError = false;
      });
    }
  }

  manouverExcel() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          hasError = false;
        });
      }
      //
      int atnidx = widget.mapp!['fullName']!;
      int atphnidx = widget.mapp!['phone']!;
      int? atahadiidx = widget.mapp!['ahadi'];
      int? atmchangoidx = widget.mapp!['mchango'];
      //
      //
      var bytes = widget.xcelBytes;
      excel = xcl.Excel.decodeBytes(bytes!);
      var tblKey = excel?.tables.keys.firstOrNull;
      var table = excel?.tables[tblKey];
      List<List<xcl.Data?>>? rows = table?.rows;
      if (rows == null || rows.isEmpty) {
        return;
      }
      for (var i = 0; i < rows.length; i++) {
        if (i == 0) {
          continue;
        }
        var namecell = rows[i][atnidx];
        var phonecell = rows[i][atphnidx];
        var ahadicell = atahadiidx != null ? rows[i][atahadiidx] : null;
        var mchangocell = atmchangoidx != null ? rows[i][atmchangoidx] : null;
        var phoneItself = transformNumber("${phonecell?.value}");
        Attendee attendee = Attendee(
          cards: {},
          checkinStatus: [],
          createdAt: DateTime.now(),
          email: '',
          phone: phoneItself,
          messages: {},
          pledgedAmount:
              widget.kardType == KardType.contribution
                  ? double.tryParse("${ahadicell?.value}") ?? 0.0
                  : null,
          paidAmount:
              widget.kardType == KardType.contribution
                  ? double.tryParse("${mchangocell?.value}") ?? 0.0
                  : null,
          fullName: "${namecell?.value}".toUpperCase(),
        );
        attendees.add(attendee);
      }
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: uppBar(
        title: "Kihakiki cha Kupakia Data",
        leading: gsUppBack(context: context),
        actions: <Widget>[
          !isWritting
              ? gsFloatingButton(
                icon: Clarity.import_solid,
                onTap: () {
                  if (attendees.isNotEmpty) {
                    crtEm();
                  } else {
                    showToast(isGood: false, msg: "Nothing to import");
                  }
                },
              )
              : Text("Inapakia..."),
          SizedBox(width: psm),
        ],
      ),

      body: FutureBuilder(
        future:
            firestore
                .collection(ecol)
                .doc(widget.event.id)
                .collection(cardcol)
                .doc(widget.templateCardId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var source = (snapshot.data as dynamic).data();
            if (source != null) {
              return bady();
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

  Widget bady() {
    if (isLoading) {
      return buildLoader();
    }
    if (hasError) {
      return buildErr();
    }
    if (attendees.isEmpty) {
      return BuildNoDt(string: "no data");
    }
    return buildAtList(atList: attendees);
  }

  buildAtList({required List<Attendee> atList}) {
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(gradient: scagrad),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: psm, right: psm),
        child: Column(
          children: [
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(top: psm, left: psm, bottom: psm * 0.65),
              child: Text(
                "Total Count: ${atList.length}",
                style: TextStyle(
                  fontSize: fsm + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(atList.length, (index) {
              var attendee = atList[index];
              var fullname = attendee.fullName;
              // nicer card-like row with aligned columns
              return Container(
                margin: EdgeInsets.only(bottom: psm * 0.5),
                decoration: BoxDecoration(
                  gradient: lqassgrad,
                  borderRadius: BorderRadius.circular(bsm),
                  border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: psm * 0.8,
                    vertical: psm * 0.6,
                  ),
                  child: Stack(
                    children: [
                      // main horizontal content
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // compact index pill with subtle shadow
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: lqassgradBaseColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: psm * 0.6),
                          // main details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // name (single line)
                                Text(
                                  fullname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fsm + 0.6,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: psm * 0.25),
                                // phone (own line, muted)
                                Text(
                                  attendee.phone,
                                  style: TextStyle(
                                    fontSize: fsm - 2,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                SizedBox(height: psm * 0.5),
                                // amounts: separate lines with subtle label + value layout
                                if (widget.kardType == KardType.contribution)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          // small label box
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: psm * 0.45,
                                              vertical: psm * 0.18,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.04,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(bsm),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.favorite,
                                                  size: 12,
                                                  color: Colors.white70,
                                                ),
                                                SizedBox(width: psm * 0.35),
                                                Text(
                                                  'Ahadi',
                                                  style: TextStyle(
                                                    fontSize: fsm - 4,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: psm * 0.5),
                                          // value
                                          Expanded(
                                            child: Text(
                                              (attendee.pledgedAmount ?? 0) == 0
                                                  ? '-'
                                                  : formatMoney(
                                                    currency: "TZS",
                                                    attendee.pledgedAmount,
                                                    decimals: 0,
                                                  ),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: fsm - 3,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: psm * 0.35),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: psm * 0.45,
                                              vertical: psm * 0.18,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.02,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(bsm),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.payments,
                                                  size: 12,
                                                  color: Colors.white70,
                                                ),
                                                SizedBox(width: psm * 0.35),
                                                Text(
                                                  'Mchango',
                                                  style: TextStyle(
                                                    fontSize: fsm - 4,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: psm * 0.5),
                                          Expanded(
                                            child: Text(
                                              (attendee.paidAmount ?? 0) == 0
                                                  ? '-'
                                                  : formatMoney(
                                                    currency: "TZS",
                                                    attendee.paidAmount,
                                                    decimals: 0,
                                                  ),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: fsm - 3,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // delete button overlayed top-right so it doesn't consume layout width
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          iconSize: 18,
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                attendees.removeAt(index);
                              });
                            }
                          },
                          icon: const Icon(Clarity.close_line),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  crtEm() async {
    safeState(() {
      isWritting = true;
    });

    HttpService client = HttpService();
    // Create a copy to iterate while modifying the original list
    List<Attendee> attendeesCpy = List.from(attendees);

    for (var i = 0; i < attendeesCpy.length; i += 5) {
      int end = (i + 5 < attendeesCpy.length) ? i + 5 : attendeesCpy.length;
      List<Attendee> batch = attendeesCpy.sublist(i, end);

      List<Map<String, dynamic>> batchPayload = [];
      for (var attendee in batch) {
        var atId = attendee.id ?? generateUniqueSequence();
        attendee.id = atId;
        attendee.cards = {};
        attendee.checkinStatus = chk;
        attendee.createdAt = DateTime.now();
        batchPayload.add(attendee.toMap());
      }

      try {
        var payload = {
          "eventId": widget.event.id,
          "attendees": batchPayload,
          "usepng": widget.event.usepng,
          "kardType": widget.kardType.name,
          "templateCardId": widget.templateCardId,
        };

        var source = await client.post(
          Uri.parse(crtAtCloudUrl),
          body: jsonEncode(payload),
        );

        var body = jsonDecode(source.body);
        if (body != null && body['status']) {
          var results = body['data'] as List;
          for (var res in results) {
            if (res['status']) {
              var atId = res['attendeeId'];
              // Find attendee in batch to get paidAmount
              var attendee = batch.firstWhere(
                (a) => a.id == atId,
                orElse: () => batch[0],
              );
              setMchango(amount: attendee.paidAmount, atId: atId);

              safeState(() {
                attendees.removeWhere((test) => test.id == atId);
              });
            } else {
              showToast(
                isGood: false,
                msg: res['message'] ?? "Failed for one item",
              );
            }
          }
          showToast(isGood: true, msg: body['message'] ?? "Batch Success");
        } else {
          var message = body != null ? body['message'] : "Batch Failed";
          showToast(isGood: false, msg: "$message");
        }
      } catch (e) {
        showToast(isGood: false, msg: "Batch Error: $e");
      }
    }

    client.close();
    safeState(() {
      isWritting = false;
    });
  }

  setMchango({amount, atId}) {
    Mchango mchango = Mchango(
      amount: amount ?? 0,
      createdAt: DateTime.now().toIso8601String(),
    );
    CollectionReference<Map<String, dynamic>> mchColRef = firestore
        .collection(ecol)
        .doc(widget.event.id)
        .collection(atcol)
        .doc(atId)
        .collection(atPaySub);

    var mchId = mchColRef.doc().id;

    mchColRef
        .doc(mchId)
        .set(mchango.toMap(), SetOptions(merge: true))
        .catchError((onError) {
          showToast(isGood: false, msg: "${onError}");
        });
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  popper() {
    Navigator.of(context).pop();
  }
}
