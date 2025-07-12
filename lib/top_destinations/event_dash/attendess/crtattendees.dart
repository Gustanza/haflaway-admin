import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class CreateAttendees extends StatefulWidget {
  final List<Kard> cards;
  final Event event;
  const CreateAttendees({super.key, required this.cards, required this.event});

  @override
  State<CreateAttendees> createState() => _CreateAttendeesState();
}

class _CreateAttendeesState extends State<CreateAttendees> {
  dynamic data;
  List chk = [];
  Kard? selCrds;
  List? dataList;
  bool isPhoneValid = false;
  late String phnnumber;
  late List<Map<String, dynamic>> chekstatuses;
  late TextEditingController ncont;
  late TextEditingController phncont;
  late TextEditingController crdCont;
  GlobalKey<FormState> fkey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    ncont = TextEditingController();
    phncont = TextEditingController();
    crdCont = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: AppBar(title: const Text("Create Attendees")),
      floatingActionButton: FloatingActionButton(
        onPressed: submitForm,
        child: const Icon(Clarity.upload_cloud_line),
      ),
      body: Container(
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: FutureBuilder(
          future:
              firestore
                  .collection(cardcol)
                  .where('eventId', isEqualTo: widget.event.id)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              dataList = (snapshot.data as dynamic).docs;
              if (dataList != null && dataList!.isNotEmpty) {
                Map<String, String> scrdsMp = Map.fromIterable(
                  dataList as Iterable,
                  key: (e) => e.id,
                  value: (e) => e['type'],
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: psm,
                    vertical: psm * 0.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: fkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: psm * 0.5),
                            Text("Attendee Details", style: normal()),
                            const SizedBox(height: psm * 0.5),
                            buildField(
                              filled: true,
                              lbl: atlblname,
                              cont: ncont,
                            ),
                            const SizedBox(height: psm),
                            buildPhone(mobileCont: phncont),
                            const SizedBox(height: psm * 0.5),
                            bldDrdDwn(
                              lbl: "Card Type",
                              entries: scrdsMp.entries,
                              controller: crdCont,
                              onSelected: (val) {
                                safeState(() {
                                  selCrds = widget.cards.firstWhere((t) {
                                    return t.id == val;
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }

  buildPhone({mobileCont}) {
    return IntlPhoneField(
      controller: mobileCont,
      decoration: const InputDecoration(
        hintText: 'Phone Number',
        border: OutlineInputBorder(),
      ),
      initialCountryCode: 'TZ',
      onChanged: (phone) {
        phnnumber = phone.completeNumber;
      },
    );
  }

  submitForm() async {
    var isValid = fkey.currentState?.validate() ?? false;
    if (isValid && validatePhone()) {
      try {
        showProgress(context: context);
        var atRef = firestore
            .collection(ecol)
            .doc(widget.event.id)
            .collection(atcol)
            .doc(generateUniqueSequence());
        dataCleaner(passcode: atRef.id);
        var reqRes = await http.post(
          Uri.parse(rendercarl),
          body: jsonEncode(data),
        );
        var res = jsonDecode(reqRes.body);
        if (res["error"]) {
          showToast(isGood: true, msg: genErrMsg);
          return;
        }

        Attendee atdt = Attendee(
          cardId: selCrds?.id ?? "",
          cardName: selCrds?.type ?? "unknown",
          cardUrl: res["data"],
          checkinStatus: chk,
          createdAt: DateTime.now(),
          email: crdCont.text,
          fullName: ncont.text,
          phone: phnnumber.substring(1),
          messages: {},
        );

        await atRef.set(atdt.toMap());
        poper();

        showToast(isGood: true, msg: "Success");
      } catch (e) {
        poper();

        showToast(isGood: true, msg: "Failed: $e");
      }
      poper();
    }
  }

  validatePhone() {
    if (phncont.text.isEmpty) {
      showToast(isGood: false, msg: "Phone number is required");
      return false;
    }
    return true;
  }

  dataCleaner({passcode}) {
    String type = selCrds?.type ?? "unknown";
    int cap = selCrds?.capacity ?? 1;
    List clearAt = selCrds?.clearAt ?? [];
    for (var i = 0; i < cap; i++) {
      var atentry = {
        cattendeename: "Slot: ${i + 1}",
        crdChkpns: {for (var chkpnId in clearAt) chkpnId: false},
      };
      chk.add(atentry);
    }
    data[crdelements][crdattname][lmntvalue] = ncont.text;
    data[crdelements][crdtype][lmntvalue] = type;
    data[crdelements][crdQrCode][lmntvalue] = passcode;
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  poper() {
    dismissal(context: context);
  }
}
