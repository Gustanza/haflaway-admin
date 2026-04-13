import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/wsap_templates.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/urls.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:flutter/cupertino.dart';

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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _T.bg,
          body: Stack(
            children: [
              // Ambient Orbs
              const Positioned(
                top: -100,
                right: -100,
                child: _GusOrb(size: 300, color: _T.lime, opacity: 0.08),
              ),
              const Positioned(
                bottom: -50,
                left: -100,
                child: _GusOrb(size: 250, color: _T.lime, opacity: 0.05),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _topBar(),
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
                              return BuildNoDt(string: "No Templates Found");
                            }
                          }
                          if (snapshot.hasError) {
                            return buildErr();
                          } else {
                            return Center(
                              child: CupertinoActivityIndicator(color: _T.lime),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Dispatch Bar (UX Fixed with Positioned)
              _buildFloatingConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _handleExit();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Complete Sending",
                  style: _T.f(size: 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _T.lime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  color: _T.lime,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECIPIENTS",
                      style: _T.f(
                        size: 10,
                        weight: FontWeight.w700,
                        color: _T.grey2,
                      ),
                    ),
                    Text(
                      "Total Count: ${widget.senderList.length}",
                      style: _T.f(
                        size: 14,
                        color: _T.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: _T.white.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _T.lime),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Select a template for this campaign",
                  style: _T.f(size: 13, color: _T.grey1),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: temps.length + 1,
      itemBuilder: (context, index) {
        if (index == temps.length) {
          // Bottom spacer that only appears when a template is selected to give room for the floating bar
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: groupValue != null ? 120 : 20,
          );
        }
        final isSelected = groupValue == temps[index].id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  groupValue = temps[index].id;
                  wsapTemplate = temps[index];
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? _T.lime.withOpacity(0.03) : _T.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _T.lime : _T.white.withOpacity(0.05),
                    width: isSelected ? 1.0 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with selection indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? _T.lime.withOpacity(0.08)
                                : _T.white.withOpacity(0.02),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: isSelected ? 1.1 : 1.0,
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isSelected ? _T.lime : _T.grey2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Template ${index + 1}",
                            style: _T.f(
                              size: 14,
                              weight: FontWeight.w600,
                              color: isSelected ? _T.lime : _T.white,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _T.lime,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "SELECTED",
                                style: _T.f(
                                  size: 10,
                                  color: Colors.black,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Content preview
                    Padding(
                      padding: const EdgeInsets.all(12),
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
    bool isSel = groupValue != null;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      bottom: isSel ? 20 : -140, // Animates from outside the screen
      left: 16,
      right: 16,
      child: glassDialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: confirmSend,
                child: Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _T.lime,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _T.lime.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Send Message Now",
                        style: _T.f(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  confirmSend() async {
    if (groupValue == null) {
      showToast(isGood: false, msg: "Please Select a Template");
      return;
    }
    return showPopap();
  }

  showPopap() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: 28,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Confirm Action",
                  style: _T.f(size: 22, weight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to send this message to ${widget.senderList.length} people?",
                  textAlign: TextAlign.center,
                  style: _T.f(size: 15, color: _T.grey1),
                ),
                const SizedBox(height: 24),
                buildPrimaryButton(
                  label: "Send Now",
                  iconData: Icons.send_rounded,
                  onTap: () async {
                    List inviteesIds =
                        widget.senderList.map((e) {
                          return e.id;
                        }).toList();
                    showProgress(context: context);
                    HttpService client = HttpService();
                    try {
                      dynamic response;
                      if (widget.isWhatsApp && groupValue != null) {
                        var _url = sendWspInv;
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
                      showNotifier(msg: "Failed due to: $e");
                    }
                    client.close();
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => popper(),
                  child: Text(
                    "Cancel",
                    style: _T.f(
                      size: 15,
                      color: _T.grey2,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.lime.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 32,
                    color: _T.lime,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Information",
                  style: _T.f(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  "$msg",
                  textAlign: TextAlign.center,
                  style: _T.f(size: 15, color: _T.grey1),
                ),
                const SizedBox(height: 24),
                lqAssButton(
                  label: "Close",
                  onPressed: () {
                    _handleExit();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _handleExit() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(messagesSent);
    }
  }

  popper() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens & Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

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
        color: color.withOpacity(opacity),
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
