import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/wsap_templates.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:haflaway/utils/urls.dart';

class SendPreviewer extends StatefulWidget {
  final Event event;
  final String campaignId;
  final bool isWhatsApp;
  final KardType? kardType;
  final List<Attendee> senderList;
  SendPreviewer({
    super.key,
    required this.event,
    this.isWhatsApp = true,
    required this.senderList,
    this.kardType = KardType.invitation,
    required this.campaignId,
  });

  @override
  State<SendPreviewer> createState() => SendPreviewerState();
}

class SendPreviewerState extends State<SendPreviewer> {
  String? groupValue;
  bool? messagesSent;
  WsapTemplate? wsapTemplate;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    var path =
        widget.campaignId == contrCampId
            ? firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "matrimony-contributions")
                .where("language", isEqualTo: widget.event.language)
                .get()
            : widget.campaignId == invCampId
            ? firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "whatsapp-wedding-invitations")
                .where("language", isEqualTo: widget.event.language)
                .get()
            : widget.campaignId == invRemCampId
            ? firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: invRemCampId)
                .where("language", isEqualTo: widget.event.language)
                .get()
            : firestore
                .collection("messageTemplates")
                .where('category', isEqualTo: "whatsapp-wedding-save-the-date")
                .where("language", isEqualTo: widget.event.language)
                .get();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        appBar: appBar(
          title: "Kamilisha kutuma",
          leading: buildActionButton(
            icon: Icons.arrow_back,
            onTap: () {
              _handleExit();
            },
          ),
        ),
        backgroundColor: scaback,
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(gradient: scagrad),
          child: Column(
            children: [
              // Modern Header Section
              _buildHeaderSection(),
              // Templates List
              Expanded(
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
                                  WsapTemplate wsapTemplate =
                                      WsapTemplate.fromMap(
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

              // Floating Action Button Area
              if (groupValue != null) _buildFloatingConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: EdgeInsets.all(spaceTiles),
      padding: EdgeInsets.symmetric(horizontal: psm, vertical: psm * 0.75),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(bmd),
        gradient: lqassgrad,
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              SizedBox(width: psm * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Walengwa",
                      style: TextStyle(
                        fontSize: fsm - 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Idadi ya Jumla: ${widget.senderList.length}",
                      style: TextStyle(
                        fontSize: fsm + 2,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: psm * 0.5),
          Divider(height: 1, thickness: 0.20),
          SizedBox(height: psm * 0.5),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              SizedBox(width: psm * 0.5),
              Expanded(
                child: Text(
                  "Chagua template ya campaign hii",
                  style: TextStyle(fontSize: fsm, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTemplates(List<WsapTemplate> temps) {
    List<TextEditingController> conts = List.generate(temps.length, (idx) {
      return TextEditingController(text: temps[idx].content);
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: spaceTiles,
        vertical: psm * 0.5,
      ),
      itemCount: temps.length,
      itemBuilder: (context, index) {
        final isSelected = groupValue == temps[index].id;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: spaceTiles),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  groupValue = temps[index].id;
                  wsapTemplate = temps[index];
                });
              },
              borderRadius: BorderRadius.circular(bmd),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(bmd),
                  border: Border.all(
                    color: isSelected ? Colors.green : lqassbdrColor,
                    width: bdrWidthGen,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? Colors.green.withOpacity(0.15)
                              : Colors.black.withOpacity(0.03),
                      blurRadius: isSelected ? 12 : 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with selection indicator
                    Container(
                      padding: EdgeInsets.all(psm * 0.75),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.green.withOpacity(0.08)
                                : lqassgradBaseColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(bmd - 2),
                          topRight: Radius.circular(bmd - 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.green
                                        : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          SizedBox(width: psm * 0.5),
                          Text(
                            "Template ${index + 1}",
                            style: TextStyle(
                              fontSize: fsm + 1,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.green[700] : primaryWhite,
                            ),
                          ),
                          Spacer(),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Imechaguliwa",
                                style: TextStyle(
                                  fontSize: fsm - 3,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content preview
                    Padding(
                      padding: EdgeInsets.all(psm * 0.75),
                      child: buildField(
                        cont: conts[index],
                        isReadOnly: true,
                        showCursor: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingConfirmButton() {
    return Container(
      padding: EdgeInsets.all(psm),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        border: Border(top: BorderSide(color: lqassgradBaseColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: confirmSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: psm * 0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(bmd),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 20),
                    SizedBox(width: psm * 0.25),
                    Text(
                      "Tuma Ujumbe",
                      style: TextStyle(
                        fontSize: fsm + 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  confirmSend() async {
    if (groupValue == null) {
      showToast(isGood: false, msg: "Chagua Template");
      return;
    }
    return showPopap();
  }

  showPopap() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
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
              // Icon indicator
              Center(
                child: Container(
                  padding: EdgeInsets.all(psm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: psm),
              Text(
                "Thibitisha Kitendo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fsm + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: psm * 0.5),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: psm),
                child: Text(
                  "Je, una uhakika unataka kutuma ujumbe huu kwa watu ${widget.senderList.length}?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fsm, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: psm * 1.5),
              lqAssButton(
                label: "Tuma Sasa",
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
                              : widget.campaignId == invCampId ||
                                  widget.campaignId == invRemCampId
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
                    messagesSent = true;
                    _handleExit();
                    _handleExit();
                    showNotifier(msg: "${res['message']}");
                  } catch (e) {
                    messagesSent = false;
                    _handleExit();
                    _handleExit();
                    showNotifier(msg: "Imefeli kwa sababu: $e");
                  }
                  client.close();
                },
              ),
              const SizedBox(height: spaceTiles),
              lqAssButton(
                label: "Sitisha",
                onPressed: () {
                  _handleExit();
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
                Container(
                  padding: EdgeInsets.all(psm * 0.75),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 32, color: Colors.blue),
                ),
                SizedBox(height: psm * 0.75),
                Text(
                  "Taarifa",
                  style: TextStyle(
                    fontSize: fsm + 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(thickness: 0.25),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: psm * 0.5),
                  child: Text(
                    "$msg",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fsm + 1),
                  ),
                ),
                Divider(thickness: 0.25),
                SizedBox(height: psm * 0.25),
                lqAssButton(
                  label: "Funga",
                  onPressed: () {
                    _handleExit();
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

  _handleExit() {
    Navigator.of(context).pop(messagesSent);
  }
}
