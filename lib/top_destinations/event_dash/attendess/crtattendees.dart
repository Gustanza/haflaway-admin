import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final Kard card;
  const CreateAttendees({super.key, required this.card});

  @override
  State<CreateAttendees> createState() => _CreateAttendeesState();
}

class _CreateAttendeesState extends State<CreateAttendees> {
  dynamic data;
  List chk = [];
  bool isPhoneValid = false;
  late String phnnumber;
  late List<Map<String, dynamic>> chekstatuses;
  late TextEditingController ncont;
  late TextEditingController phncont;
  late TextEditingController emlcont;
  GlobalKey<FormState> fkey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    ncont = TextEditingController();
    phncont = TextEditingController();
    emlcont = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var crdcap = widget.card.capacity;
    return Scaffold(
      appBar: AppBar(title: const Text("Create Attendees")),
      floatingActionButton: FloatingActionButton(
        onPressed: submitForm,
        child: const Icon(Clarity.upload_cloud_line),
      ),
      body: FutureBuilder(
        future: firestore.collection(cardcol).doc(widget.card.id).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            data = (snapshot.data as dynamic).data();
            if (data != null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: psm,
                  vertical: psm * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Create $crdcap Attendee(s)", style: normalBold()),
                    const Text(
                      "The number above has been derived from the type of card you have selected, each card has been created to accomodate a given number of attendees, fill details of each personel with care.",
                    ),
                    Form(
                      key: fkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: psm * 0.5),
                          Text("Attendee Details", style: normal()),
                          const SizedBox(height: psm * 0.5),
                          buildField(filled: true, lbl: atlblname, cont: ncont),
                          const SizedBox(height: psm),
                          buildPhone(mobileCont: phncont),
                          const SizedBox(height: psm * 0.5),
                          buildField(
                            filled: true,
                            lbl: atlblemail,
                            cont: emlcont,
                            type: TextInputType.emailAddress,
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
    );
  }

  buildPhone({mobileCont}) {
    return IntlPhoneField(
      controller: mobileCont,
      decoration: const InputDecoration(
        hintText: 'Phone Number',
        filled: true,
        border: InputBorder.none,
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
            .doc(widget.card.eventId)
            .collection(atcol)
            .doc(generateUniqueSequence());
        dataCleaner(passcode: atRef.id);
        var reqRes = await http.post(
          Uri.parse(rendercarl),
          body: jsonEncode(data),
        );
        var res = jsonDecode(reqRes.body);
        if (res["error"]) {
          // poper();
          showToast(isGood: true, msg: genErrMsg);
          return;
        }

        Attendee atdt = Attendee(
          cardId: widget.card.id,
          cardName: widget.card.type,
          cardUrl: res["data"],
          checkinStatus: chk,
          createdAt: DateTime.now(),
          email: emlcont.text,
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
    for (var i = 0; i < widget.card.capacity; i++) {
      var atentry = {
        cattendeename: "Slot: ${i + 1}",
        crdChkpns: {for (var chkpnId in widget.card.clearAt) chkpnId: false},
      };
      chk.add(atentry);
    }
    data[crdelements][crdattname][lmntvalue] = ncont.text;
    data[crdelements][crdtype][lmntvalue] = widget.card.type;
    data[crdelements][crdQrCode][lmntvalue] = passcode;
  }

  poper() {
    dismissal(context: context);
  }
}
