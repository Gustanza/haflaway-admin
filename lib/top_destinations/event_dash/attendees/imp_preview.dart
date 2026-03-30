import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/models/mchango.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xcl;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/urls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const card2 = Color(0xFF1A1A1A);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

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
              (widget.kardType == KardType.contribution ||
                      widget.kardType == KardType.contact)
                  ? double.tryParse("${ahadicell?.value}") ?? 0.0
                  : null,
          paidAmount:
              (widget.kardType == KardType.contribution ||
                      widget.kardType == KardType.contact)
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child:
                    widget.templateCardId == "contact"
                        ? bady()
                        : FutureBuilder(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Import Preview',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w500,
                    color: _T.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          !isWritting
              ? GestureDetector(
                onTap: () {
                  if (attendees.isNotEmpty) {
                    crtEm();
                  } else {
                    showToast(isGood: false, msg: "Nothing to import");
                  }
                },
                child: Text(
                  'Import',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w500,
                    color: _T.lime,
                  ),
                ),
              )
              : const CupertinoActivityIndicator(color: _T.lime),
        ],
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
      color: _T.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          children: [
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.only(top: 16, left: 8, bottom: 10),
              child: Text(
                "Total Count: ${atList.length}",
                style: _T.f(size: 18, weight: FontWeight.bold),
              ),
            ),
            ...List.generate(atList.length, (index) {
              var attendee = atList[index];
              var fullname = attendee.fullName;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _T.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _T.card2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${index + 1}",
                                style: _T.f(size: 14, weight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fullname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _T.f(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  attendee.phone,
                                  style: _T.f(size: 12, color: _T.grey1),
                                ),
                                if (widget.kardType == KardType.contribution ||
                                    widget.kardType == KardType.contact) ...[
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _T.lime.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  size: 12,
                                                  color: _T.lime,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Pledge',
                                                  style: _T.f(
                                                    size: 11,
                                                    color: _T.lime,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                              style: _T.f(
                                                size: 13,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _T.white.withOpacity(0.04),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.payments,
                                                  size: 12,
                                                  color: _T.grey1,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Contribution',
                                                  style: _T.f(
                                                    size: 11,
                                                    color: _T.grey1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                              style: _T.f(
                                                size: 13,
                                                weight: FontWeight.w600,
                                                color: _T.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
                          color: _T.grey1,
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

    for (var i = 0; i < attendeesCpy.length; i += 2) {
      int end = (i + 2 < attendeesCpy.length) ? i + 2 : attendeesCpy.length;
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
