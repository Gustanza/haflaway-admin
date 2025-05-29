import 'dart:convert';
import 'dart:io';
import 'package:haflaway/utils/helpers.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
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
  final dynamic eId;
  final Kard carddata;
  final Map<String, dynamic> mapp;
  final File xcelFile;
  const ImpPreview({
    super.key,
    required this.eId,
    required this.mapp,
    required this.carddata,
    required this.xcelFile,
  });

  @override
  State<ImpPreview> createState() => _ImpPreviewState();
}

class _ImpPreviewState extends State<ImpPreview> {
  dynamic data;
  Excel? excel;
  List chk = [];
  List<Attendee> attendees = [];
  bool isLoading = false;
  bool hasError = false;

  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    prcsXcel();
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
      int atnidx = widget.mapp['fullName']!;
      int atphnidx = widget.mapp['phone']!;
      //
      File file = widget.xcelFile;
      var bytes = file.readAsBytesSync();
      excel = Excel.decodeBytes(bytes);
      var tblKey = excel?.tables.keys.firstOrNull;
      var table = excel?.tables[tblKey];
      List<List<Data?>>? rows = table?.rows;
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
          cardId: widget.carddata.id,
          cardName: widget.carddata.type,
          cardUrl: "",
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
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: const Text("Preview"),
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (attendees.isNotEmpty) {
                crtEm();
              } else {
                showToast(isGood: false, msg: "Nothing to import");
              }
            },
            label: const Text("Import"),
            icon: const Icon(Clarity.import_line, color: secondaryColor),
          ),
        ],
      ),
      body: FutureBuilder(
        future: firestore.collection(cardcol).doc(widget.carddata.id).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            data = (snapshot.data as dynamic).data();
            if (data != null) {
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
    return !isLoading
        ? SizedBox(
          child:
              !hasError
                  ? SizedBox(
                    child:
                        attendees.isNotEmpty
                            ? buildAtList(atList: attendees)
                            : const BuildNoDt(string: "no data"),
                  )
                  : buildErr(),
        )
        : buildLoader();
  }

  buildAtList({List<Attendee>? atList}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: psm, right: psm),
      child: CupertinoListSection.insetGrouped(
        margin: const EdgeInsets.only(top: psm * 0.5),
        header: Text("Total: ${atList!.length}"),
        children: List.generate(atList.length, (index) {
          var fullname = atList[index].fullName;
          return CupertinoListTile(
            padding: const EdgeInsets.all(psm * 0.5),
            leading: CircleAvatar(
              backgroundColor: primaryColor,
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              fullname,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
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
          );
        }),
      ),
    );
  }

  crtEm() async {
    showProgress(context: context);
    List<Attendee> attendeesCpy = List.from(attendees);
    for (var attendee in attendeesCpy) {
      dynamic res;
      dynamic reqRes;
      var atRef = firestore
          .collection(ecol)
          .doc(widget.eId)
          .collection(atcol)
          .doc(generateUniqueSequence());
      try {
        dataCleaner(passcode: atRef.id, lfname: attendee.fullName);
        reqRes = await http.post(Uri.parse(rendercarl), body: jsonEncode(data));
        res = jsonDecode(reqRes.body);
        if (res["error"]) {
          popper();
          showToast(isGood: false, msg: genErrMsg);
          return;
        }
      } catch (e) {
        popper();
        showToast(isGood: false, msg: genErrMsg);
        return;
      }
      try {
        attendee.checkinStatus = chk;
        attendee.cardUrl = res['data'];
        attendee.createdAt = DateTime.now();
        await atRef.set(attendee.toMap());
        setState(() {
          attendees.remove(attendee);
        });
      } catch (e) {
        deleteCrd(url: attendee.cardUrl);
        popper();
        showToast(isGood: false, msg: genErrMsg);
        return;
      }
    }
    popper();
    showToast(isGood: true, msg: genScsMsg);
    return;
  }

  deleteCrd({url}) {
    var ref = storage.refFromURL(url);
    ref.delete();
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
    data[crdelements][crdattname][lmntvalue] = lfname;
    data[crdelements][crdtype][lmntvalue] = widget.carddata.type;
    data[crdelements][crdQrCode][lmntvalue] = passcode;
  }

  popper() {
    Navigator.of(context).pop();
  }
}
