import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
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
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class ImpPreview extends StatefulWidget {
  final Event event;
  final Kard carddata;
  final KardType kardType;
  final List<Attendee>? atList;
  final Map<String, dynamic>? mapp;
  final File? xcelFile;
  const ImpPreview({
    super.key,
    this.mapp,
    this.atList,
    this.xcelFile,
    required this.event,
    required this.kardType,
    required this.carddata,
  });

  @override
  State<ImpPreview> createState() => _ImpPreviewState();
}

class _ImpPreviewState extends State<ImpPreview> {
  CardConfig? data;
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
    if (widget.xcelFile != null) {
      prcsXcel();
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

  prcsXcel() async {
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
      //
      File? file = widget.xcelFile;
      var bytes = file?.readAsBytesSync();
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
        var phoneItself = transformNumber("${phonecell?.value}");
        Attendee attendee = Attendee(
          cards: {},
          checkinStatus: [],
          createdAt: DateTime.now(),
          email: '',
          fullName: "${namecell?.value}",
          phone: phoneItself,
          messages: {},
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
      appBar: appBar(
        title: 'Import Previewer',
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions:
            !isWritting
                ? appBarActionButton(
                  icon: Clarity.import_solid,
                  onTap: () {
                    if (attendees.isNotEmpty) {
                      crtEm();
                    } else {
                      showToast(isGood: false, msg: "Nothing to import");
                    }
                  },
                )
                : CupertinoActivityIndicator(),
      ),

      body: FutureBuilder(
        future: firestore.collection(cardcol).doc(widget.carddata.id).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var source = (snapshot.data as dynamic).data();
            if (source != null) {
              data = CardConfig.fromMap(widget.carddata.id, source);
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

  bady() {
    if (isLoading) {
      return buildLoader();
    }
    if (hasError) {
      return buildErr()();
    }
    if (attendees.isEmpty) {
      BuildNoDt(string: "no data");
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
              var fullname = atList[index].fullName;
              return Container(
                margin: EdgeInsets.only(bottom: psm * 0.5),
                decoration: BoxDecoration(
                  gradient: lqassgrad,
                  borderRadius: BorderRadius.circular(bsm),
                  border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: psm * 0.7,
                  ),

                  leading: CircleAvatar(
                    backgroundColor: lqassgradBaseColor,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(fullname),
                  subtitle: Text(
                    atList[index].phone,
                    style: const TextStyle(fontSize: fsm - 2),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          attendees.removeAt(index);
                        });
                      }
                    },
                    icon: const Icon(Clarity.close_line),
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
    List<Attendee> attendeesCpy = List.from(attendees);
    HttpService client = HttpService();
    for (var attendee in attendeesCpy) {
      var atId = attendee.id ?? generateUniqueSequence();
      var atRef = firestore
          .collection(ecol)
          .doc(widget.event.id)
          .collection(atcol)
          .doc(atId);
      dataCleaner(passcode: atRef.id, lfname: attendee.fullName);
      try {
        attendee.cards = {};
        attendee.checkinStatus = chk;
        attendee.id = attendee.id ?? atId;
        attendee.createdAt = DateTime.now();
        var payload = {
          "eventId": widget.event.id,
          "attendees": [attendee.toMap()],
          "templateCard": data?.toMap(),
          "usepng": widget.event.usepng,
          "kardType": widget.kardType.name,
        };
        var source = await client.post(
          Uri.parse(crtAtCloudUrl),
          body: jsonEncode(payload),
        );
        var message = "Failed";
        var body = jsonDecode(source.body);
        if (body == null || !body['status']) {
          message = body != null ? body['message'] : "Failed";
          showToast(isGood: false, msg: "$message");
        } else {
          message = body['message'] ?? "Success";
          showToast(isGood: true, msg: "$message");
          safeState(() {
            try {
              var atte = body['data'][0];
              if (atte['status']) {
                attendees.removeWhere((test) {
                  return test.id == atte['attendeeId'];
                });
              }
            } catch (e) {}
          });
        }
      } catch (e) {
        showToast(isGood: false, msg: genErrMsg);
      }
    }
    client.close();
    safeState(() {
      isWritting = false;
    });
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  dataCleaner({passcode, lfname}) {
    chk = [];
    for (var i = 0; i < widget.carddata.capacity; i++) {
      var atentry = {
        cattendeename: "Slot ${i + 1}",
        crdChkpns: {
          for (var chkpnId in widget.carddata.clearAt) chkpnId: false,
        },
      };

      chk.add(atentry);
    }
    data?.elements[crdattname][lmntvalue] = lfname;
    data?.elements[crdtype][lmntvalue] = widget.carddata.type;
    data?.elements[crdQrCode][lmntvalue] = passcode;
  }

  popper() {
    Navigator.of(context).pop();
  }
}
