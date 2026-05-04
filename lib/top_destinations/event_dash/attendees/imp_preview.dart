import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
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
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const card3   = Color(0xFF3A3A3C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1    = Color(0xFFFFFFFF);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF8E8E93);
  static const lbl4    = Color(0xFF48484A);
  static const white   = Color(0xFFFFFFFF);

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
  final List<String> labelIds;
  const ImpPreview({
    super.key,
    this.mapp,
    this.atList,
    this.xcelBytes,
    this.labelIds = const [],
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
    attendees =
        (widget.atList ?? []).map((a) {
          if (widget.labelIds.isNotEmpty) {
            final merged = {...?a.labelIds, ...widget.labelIds}.toList();
            a.labelIds = merged;
          }
          return a;
        }).toList();
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
      int atnidx = widget.mapp!['fullName']!;
      int atphnidx = widget.mapp!['phone']!;
      int? atahadiidx = widget.mapp!['ahadi'];
      int? atmchangoidx = widget.mapp!['mchango'];

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
          labelIds: List<String>.from(widget.labelIds),
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
          fullNameLower: "${namecell?.value}".toLowerCase(),
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
        body: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -80,
              child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11),
            ),
            const Positioned(
              bottom: -40,
              left: -80,
              child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  _titleBlock(),
                  if (widget.labelIds.isNotEmpty) _labelsBanner(),
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
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _T.lime,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Back',
                    style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1),
                  ),
                ],
              ),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _T.limeDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _T.lime.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Import',
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _T.lime,
                    ),
                  ),
                ),
              )
              : const Padding(
                padding: EdgeInsets.only(right: 4),
                child: CupertinoActivityIndicator(color: _T.lime),
              ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    final count = attendees.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Import Preview",
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading
                ? "Loading…"
                : "$count guest${count == 1 ? '' : 's'} ready to import",
            style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl3),
          ),
        ],
      ),
    );
  }

  Widget _labelsBanner() {
    final labels = widget.event.labels ?? [];
    final selected =
        labels.where((l) => widget.labelIds.contains(l.id)).toList();
    if (selected.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.label_rounded, color: _T.lime, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assigning to Lists",
                    style: _T.f(
                      size: 13,
                      weight: FontWeight.w700,
                      color: _T.lbl1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        selected.map((label) {
                          final c = Color(label.colorValue);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: c.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              label.name,
                              style: _T.f(
                                size: 12,
                                color: c,
                                weight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget buildAtList({required List<Attendee> atList}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: atList.length,
      itemBuilder: (context, index) {
        final attendee = atList[index];
        final fullname = attendee.fullName;
        return TweenAnimationBuilder<double>(
          key: ValueKey('prev_${attendee.phone}_$index'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(
            milliseconds: 300 + (index.clamp(0, 12) * 40),
          ),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.sep, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            style: _T.f(size: 13, weight: FontWeight.w700),
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
                              style: _T.f(size: 12, color: _T.lbl2),
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
                                          color: _T.limeDim,
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
                                          color: _T.card2,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.payments,
                                              size: 12,
                                              color: _T.lbl2,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Contribution',
                                              style: _T.f(
                                                size: 11,
                                                color: _T.lbl2,
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
                      const SizedBox(width: 32),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            attendees.removeAt(index);
                          });
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _T.card2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Clarity.close_line,
                          color: _T.lbl3,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  crtEm() async {
    safeState(() {
      isWritting = true;
    });

    HttpService client = HttpService();
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

// ─────────────────────────────────────────────────────────────────────────────

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
