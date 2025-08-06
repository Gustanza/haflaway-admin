import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:http/http.dart' as http;
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
  final Event event;
  final KardType kardType;
  final Attendee? attendee;
  const CreateAttendees({
    super.key,
    this.attendee,
    required this.event,
    required this.kardType,
  });

  @override
  State<CreateAttendees> createState() => _CreateAttendeesState();
}

class _CreateAttendeesState extends State<CreateAttendees> {
  List chk = [];
  List? dataList;
  bool isLoading = false;
  bool hasError = false;
  CardConfig? data;
  bool isPhoneValid = false;
  late String phnnumber;
  Map<String, String> scrdsMp = {};
  late List<Map<String, dynamic>> chekstatuses;
  TextEditingController ncont = TextEditingController();
  TextEditingController phncont = TextEditingController();
  TextEditingController crdCont = TextEditingController();
  GlobalKey<FormState> fkey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  fetch() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      var source =
          await firestore
              .collection(cardcol)
              .where('eventId', isEqualTo: widget.event.id)
              .get();
      dataList = source.docs;

      scrdsMp = Map.fromIterable(
        dataList as Iterable,
        key: (e) => e.id ?? "",
        value: (e) => e['type'] ?? "unknown",
      );
      Attendee? attendee = widget.attendee;
      if (attendee != null) {
        ncont.text = attendee.fullName;
        phnnumber = attendee.phone;
        phncont.text = attendee.phone.replaceFirst(RegExp(r'^255'), '');
        for (var atcard in attendee.cards.entries) {
          if (atcard.key == widget.kardType.name) {
            AttributeCard attrCrd = AttributeCard.fromMap(map: atcard.value);
            for (var dItem in dataList ?? []) {
              var dItemMap = dItem.data();
              CardConfig crdConfig = CardConfig.fromMap(dItem.id, dItemMap);
              if (crdConfig.type == attrCrd.name) {
                data = crdConfig;
                crdCont.text = crdConfig.type;
                break;
              }
            }
            break;
          }
        }
      }
      safeState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    Attendee? attendee = widget.attendee;
    if (isLoading) {
      return Ccafold(child: buildLoader());
    }
    if (hasError) {
      return Ccafold(child: buildErr());
    }
    return Scaffold(
      backgroundColor: scaback,
      appBar: AppBar(title: const Text("Create Attendees")),
      body: Ccafold(
        child: SingleChildScrollView(
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
                    buildField(filled: true, lbl: atlblname, cont: ncont),
                    const SizedBox(height: psm),
                    buildPhone(mobileCont: phncont),
                    const SizedBox(height: psm * 0.5),
                    bldDrdDwn(
                      lbl: "Card Type",
                      entries: scrdsMp.entries,
                      controller: crdCont,
                      onSelected: (val) {
                        safeState(() {
                          var dt = dataList?.firstWhere((d) {
                            return d.id == val;
                          });
                          data = CardConfig.fromMap(dt.id, dt.data());
                        });
                      },
                    ),
                    const SizedBox(height: psm * 2),
                    SizedBox(
                      width: double.maxFinite,
                      child: MaterialButton(
                        color: Colors.blue,
                        height: kToolbarHeight * 0.8,
                        onPressed: () {
                          attendee == null
                              ? submitForm()
                              : submitForm(attendeeId: attendee.id);
                        },
                        child: Text(attendee == null ? "Create" : "Update"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  submitForm({attendeeId}) async {
    var isValid = fkey.currentState?.validate() ?? false;
    if (isValid && validatePhone()) {
      if (data == null) {
        showToast(isGood: false, msg: "Select Card Type");
        return;
      }
      try {
        showProgress(context: context);
        var atRef = firestore
            .collection(ecol)
            .doc(widget.event.id)
            .collection(atcol)
            .doc(attendeeId ?? generateUniqueSequence());
        dataCleaner(passcode: atRef.id);
        var reqRes = await http.post(
          Uri.parse(rendercarl),
          body: jsonEncode(data?.toMap()),
        );
        var res = jsonDecode(reqRes.body);
        if (res["error"]) {
          showToast(isGood: true, msg: genErrMsg);
          return;
        }
        AttributeCard attCard = AttributeCard(
          name: data?.type,
          url: res['data'],
          issuedAt: DateTime.now().toIso8601String(),
        );
        Attendee atdt = Attendee(
          email: '',
          messages: {},
          fullName: ncont.text,
          checkinStatus: chk,
          createdAt: DateTime.now(),
          phone: phnnumber.replaceAll('+', ''),
          cards: {data?.purpose: attCard.toMap()},
        );
        await atRef.set(atdt.toMap(), SetOptions(merge: true));
        poper();
        showToast(isGood: true, msg: "Success");
      } catch (e) {
        poper();
        print("Abject: ${e}");
        showToast(isGood: true, msg: "Failed: $e");
      }
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
    String type = data?.type ?? "unknown";
    int cap = data?.capacity ?? 1;
    List clearAt = data?.clearAt ?? [];
    for (var i = 0; i < cap; i++) {
      var atentry = {
        cattendeename: "Slot: ${i + 1}",
        crdChkpns: {for (var chkpnId in clearAt) chkpnId: false},
      };
      chk.add(atentry);
    }
    data?.elements[crdattname][lmntvalue] = ncont.text;
    data?.elements[crdtype][lmntvalue] = type;
    data?.elements[crdQrCode][lmntvalue] = passcode;
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        debugPrint("Abject: Just Ran");
        runnable();
      });
    }
  }

  poper() {
    dismissal(context: context);
  }
}
