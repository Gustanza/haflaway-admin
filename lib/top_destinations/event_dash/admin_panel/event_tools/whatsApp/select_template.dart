import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/wsap_templates.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class SelectTemplate extends StatefulWidget {
  final Event event;
  final String campaignId;
  final bool isWhatsApp;
  final KardType? kardType;
  final List<Attendee> senderList;
  SelectTemplate({
    super.key,
    required this.event,
    this.isWhatsApp = true,

    required this.senderList,
    this.kardType = KardType.invitation,
    required this.campaignId,
  });

  @override
  State<SelectTemplate> createState() => SelectTemplateState();
}

class SelectTemplateState extends State<SelectTemplate> {
  String? groupValue;
  WsapTemplate? wsapTemplate;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    var path =
        widget.campaignId == contrCampId
            ? firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "matrimony-contributions")
                .get()
            : widget.campaignId == invCampId
            ? firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "whatsapp-wedding-invitations")
                .get()
            : firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "whatsapp-wedding-save-the-date")
                .get();
    return Scaffold(
      backgroundColor: scaback,
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: FutureBuilder(
          future:
              widget.isWhatsApp
                  ? path
                  : firestore
                      .collection('events')
                      .doc(widget.event.id)
                      .collection("messageTemplates")
                      .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var dt = (snapshot.data as dynamic).docs;
              if (dt != null && dt.isNotEmpty) {
                List<WsapTemplate> wtemps =
                    dt
                        .where((tdt) {
                          WsapTemplate wsapTemplate = WsapTemplate.fromMap(
                            id: tdt.id,
                            map: tdt.data(),
                          );
                          return wsapTemplate.usepng;
                        })
                        .map<WsapTemplate>((tdt) {
                          return WsapTemplate.fromMap(
                            id: tdt.id,
                            map: tdt.data(),
                          );
                        })
                        .toList();
                return buildTemplates(wtemps);
              } else {
                return BuildNoDt(string: "no data");
              }
            }
            if (snapshot.hasError) {
              return buildErr();
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  buildTemplates(List<WsapTemplate> temps) {
    List<TextEditingController> conts = List.generate(temps.length, (idx) {
      return TextEditingController(text: temps[idx].content);
    });
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: psm, right: psm, bottom: psm),
      child: Column(
        children: [
          Text(
            "Recipients: (${widget.senderList.length})",
            style: TextStyle(
              fontSize: fsm + 2,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Select a template to use in this campaign",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: fsm + 2, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: psm),
          Column(
            children: List.generate(temps.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: psm),
                child: Row(
                  children: [
                    Radio(
                      value: temps[index].id,
                      groupValue: groupValue,
                      onChanged: (value) {
                        setState(() {
                          groupValue = value;
                          wsapTemplate = temps[index];
                        });
                      },
                    ),
                    Expanded(
                      child: buildField(cont: conts[index], isReadOnly: true),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  confirmSend() async {
    if (groupValue == null) {
      showToast(isGood: false, msg: "Select template");
      return;
    }
    return showPopap();
  }

  showPopap() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(bmd),
          topRight: Radius.circular(bmd),
        ),
      ),
      builder: (context) {
        return modalBtmSheet(
          bdrdm: bmd,
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: psm),
              Text(
                "Complete Action",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fsm + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: psm),
              lqAssButton(
                label: "Send Now",
                onPressed: () async {
                  List inviteesIds =
                      widget.senderList.map((e) {
                        return e.id;
                      }).toList();
                  showProgress(context: context);
                  HttpService client = HttpService();
                  try {
                    dynamic response;
                    if (widget.isWhatsApp && groupValue != null) {
                      var _url =
                          widget.campaignId == contrCampId
                              ? sendWspContr
                              : widget.campaignId == invCampId
                              ? sendWspInv
                              : sendWspSvDt;
                      response = await client.post(
                        Uri.parse(_url),
                        body: jsonEncode({
                          "templateId": groupValue,
                          "type": widget.campaignId,
                          "eventId": widget.event.id,
                          "attendeesIds": inviteesIds,
                          "kardType": widget.kardType?.name,
                        }),
                      );
                    } else if (wsapTemplate != null) {
                      response = await client.post(
                        Uri.parse(sendSMSrl),
                        body: jsonEncode({
                          "content": wsapTemplate?.content,
                          "type": widget.campaignId,
                          "eventId": widget.event.id,
                          "attendeesIds": inviteesIds,
                          "kardType": widget.kardType?.name,
                        }),
                      );
                    }

                    var res = jsonDecode(response.body);

                    // showSnack(
                    //   context: context,
                    //   isGood: true,
                    //   msg: "${res['message']}",
                    // );
                    popper();
                    popper();
                    showNotifier(msg: "${res['message']}");
                  } catch (e) {
                    popper();
                    popper();
                    // showSnack(context: context, isGood: false, msg: "$e");
                    showNotifier(msg: "Failed due to: $e");
                  }
                  client.close();
                  // popper();
                },
              ),
              const SizedBox(height: spaceTiles),
              lqAssButton(
                label: "Cancel",
                onPressed: () {
                  popper();
                },
              ),
              const SizedBox(height: psm),
            ],
          ),
        );
      },
    );
  }

  showNotifier({msg}) {
    showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.all(psm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Information",
                  style: TextStyle(
                    fontSize: fsm + 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(thickness: 0.25),
                Text("$msg", textAlign: TextAlign.center),
                Divider(thickness: 0.25),
                lqAssButton(
                  label: "Dismiss",
                  onPressed: () {
                    popper();
                  },
                ),
                const SizedBox(height: psm * 0.5),
              ],
            ),
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
