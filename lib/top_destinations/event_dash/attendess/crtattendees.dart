import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class CreateAttendees extends StatefulWidget {
  final Event event;
  final KardType kardType;
  final Attendee? attendee;
  final String title;
  const CreateAttendees({
    super.key,
    this.attendee,
    required this.event,
    this.title = "New Invitation",
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
  bool isWritting = false;
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
              .where("purpose", isEqualTo: widget.kardType.name)
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
      appBar: appBar(
        title: "Write ${widget.title}",
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                      child: lqAssButton(
                        onPressed: () {
                          if (!isWritting) {
                            attendee == null
                                ? submitForm()
                                : submitForm(attendeeId: attendee.id);
                          }
                        },
                        label:
                            attendee == null
                                ? !isWritting
                                    ? "Create"
                                    : "Loading..."
                                : !isWritting
                                ? "Update"
                                : "Loading...",
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
      decoration: InputDecoration(
        filled: true,
        hintText: 'Phone Number',
        enabledBorder: inputBorder,
        border: inputBorder,
        focusedBorder: inputBorder,
        disabledBorder: inputBorder,
        fillColor: lqassgradBaseColor,
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
      return showOutput(msg: "Success");
      if (data == null) {
        showToast(isGood: false, msg: "Select Card Type");
        return;
      }
      safeState(() {
        isWritting = true;
      });
      try {
        var atId = attendeeId ?? generateUniqueSequence();
        dataCleaner(passcode: atId);
        Attendee atdt = Attendee(
          id: atId,
          email: '',
          messages: {},
          checkinStatus: chk,
          createdAt: DateTime.now(),
          fullName: ncont.text.trim(),
          phone: phnnumber.replaceAll('+', ''),
          cards: {},
        );
        var payload = {
          "eventId": widget.event.id,
          "attendees": [atdt.toMap()],
          "templateCard": data?.toMap(),
          "kardType": widget.kardType.name,
        };
        var source = await http.post(
          Uri.parse(crtAtCloudUrl),
          body: jsonEncode(payload),
        );
        var body = jsonDecode(source.body);
        if (body == null || !body['status']) {
          var message = body != null ? body['message'] : "Failed";
          showSnack(context: context, isGood: true, msg: "$message");
          return safeState(() {
            isWritting = false;
          });
        }

        showSnack(context: context, isGood: true, msg: "Success");
        showOutput(msg: "Success");
        return safeState(() {
          isWritting = false;
        });
      } catch (e) {
        safeState(() {
          isWritting = false;
        });
        showOutput(msg: "Action Failed");
        showSnack(context: context, isGood: true, msg: "Failed because: $e");
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
        runnable();
      });
    }
  }

  showOutput({msg}) {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: psm * 2,
              horizontal: psm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                lqAssButton(
                  label: "Stay here",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: psm * 0.75),
                lqAssButton(
                  label: "Leave page",
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  poper() {
    dismissal(context: context);
  }
}
