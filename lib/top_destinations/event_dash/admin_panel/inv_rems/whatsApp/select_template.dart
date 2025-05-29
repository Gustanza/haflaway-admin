import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/wsap_templates.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:http/http.dart' as http;

class SelectTemplate extends StatefulWidget {
  final Event event;
  final EventPlan eventPlan;
  final String campaignId;
  final bool isWhatsApp;
  final List<Attendee> senderList;
  const SelectTemplate({
    super.key,
    required this.event,
    this.isWhatsApp = true,
    required this.eventPlan,
    required this.senderList,
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
    return Scaffold(
      body: FutureBuilder(
        future:
            widget.isWhatsApp
                ? firestore.collection("messageTemplates").get()
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
                  dt.map<WsapTemplate>((tdt) {
                    return WsapTemplate.fromMap(id: tdt.id, map: tdt);
                  }).toList();
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
            "Resulting costs: (${widget.senderList.length * widget.eventPlan.winvmsgprice})",
            style: TextStyle(
              fontSize: fsm + 2,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: psm),
          Text(
            "Select a template to use in this campaign",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: fsm + 2, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: psm * 1.65),
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
    return await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            "Completing this action may cause a significant impact on your wallet's current balance, please be sure before tapping anymore stuff",
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () async {
                List invitees =
                    widget.senderList.map((e) => e.toMap()).toList();
                showProgress(context: context);
                try {
                  dynamic response;
                  if (widget.isWhatsApp && groupValue != null) {
                    response = await http.post(
                      Uri.parse(sendWsAprl),
                      body: jsonEncode({
                        "templateId": groupValue,
                        "type": widget.campaignId,
                        "event": widget.event.toMap(),
                        "attendees": invitees,
                      }),
                    );
                  } else if (wsapTemplate != null) {
                    response = await http.post(
                      Uri.parse(sendSMSrl),
                      body: jsonEncode({
                        "content": wsapTemplate?.content,
                        "type": widget.campaignId,
                        "event": widget.event.toMap(),
                        "attendees": invitees,
                      }),
                    );
                  }
                  if (response != null) {
                    var res = jsonDecode(response.body);
                    showToast(isGood: true, msg: res['data']);
                  }
                } catch (e) {
                  showToast(isGood: false, msg: "$e");
                }
                popper();
                popper();
              },
              child: Text("Complete Action"),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              popper();
            },
            child: Text("Cancel Action"),
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
