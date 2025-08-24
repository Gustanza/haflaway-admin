// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:haflaway/models/wsap_templates.dart';
// import 'package:haflaway/providers/balance_provider.dart';
// import 'package:haflaway/models/attendee.dart';
// import 'package:haflaway/models/event.dart';
// import 'package:haflaway/models/logs.dart';
// import 'package:haflaway/services/balance_service.dart';
// import 'package:haflaway/services/bm_service.dart';
// import 'package:haflaway/services/plan_service.dart';
// import 'package:haflaway/utils/dimensions.dart';
// import 'package:haflaway/utils/errorstrs.dart';
// import 'package:haflaway/utils/globalfns.dart';
// import 'package:haflaway/utils/globalwids.dart';
// import 'package:haflaway/utils/styles.dart';
// import 'package:http/http.dart' as http;
// import 'package:haflaway/utils/urls.dart';
// import 'package:provider/provider.dart';

// class SendWsAp extends StatefulWidget {
//   final Event event;
//   // final LogType logType;
//   final WsapTemplate wsapTemplate;
//   final List<Attendee> senderList;
//   const SendWsAp({
//     super.key,
//     required this.event,
//     required this.wsapTemplate,
//     required this.senderList,
//     // required this.logType,
//   });

//   @override
//   State<SendWsAp> createState() => SendWsApState();
// }

// class SendWsApState extends State<SendWsAp> {
//   late String eId;
//   BalanceProvider? provider;
//   bool isSaving = false;
//   List<Attendee> sentList = [];
//   String cuserId = FirebaseAuth.instance.currentUser!.uid;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   TextEditingController controller = TextEditingController();
//   @override
//   void initState() {
//     setState(() {
//       eId = widget.event.id;
//       provider = Provider.of<BalanceProvider>(context, listen: false);
//     });
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(psm),
//       height: MediaQuery.of(context).size.height * 0.66,
//       decoration: BoxDecoration(
//         border: Border.all(),
//         borderRadius: BorderRadius.circular(psm * 0.75),
//       ),
//       child: StreamBuilder(
//         stream: firestore.collection(ecol).doc(widget.event.id).snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             if (snapshot.data!.exists) {
//               // String txt = '';
//               // var doc = (snapshot.data as dynamic).data();
//               // Event data = Event.fromMap(widget.event.id, doc);
//               // if (widget.logType == LogType.invitationMessage) {
//               //   txt = data.invitationMessage;
//               // } else if (widget.logType == LogType.reminderMessage) {
//               //   txt = data.reminderMessage;
//               // } else {
//               //   txt = data.reminderMessage;
//               // }
//               // controller.text = txt;
//               return buildBody();
//             } else {
//               return const BuildNoDt(string: "Data not found");
//             }
//           }
//           if (snapshot.hasError) {
//             return buildErr();
//           } else {
//             return buildLoader();
//           }
//         },
//       ),
//     );
//   }

//   execend() async {
//     List invitees = widget.senderList.map((e) => e.toMap()).toList();
//     try {
//       var response = await http.post(
//         Uri.parse(sendWsAprl),
//         body: jsonEncode({
//           "language": "en",
//           "type": "wsapinv",
//           "event": widget.event.toMap(),
//           "attendees": invitees,
//         }),
//       );
//       print("response: ${response.body}");
//     } catch (e) {
//       // Will handle error
//     }

//     // var client = http.Client();
//     // String? adminId = provider?.userId;
//     // EventPlan? eventPlan = provider?.eventPlan;
//     // double? cost = 0;
//     // if (widget.logType == LogType.invitationMessage) {
//     //   cost = eventPlan?.invitationMessagePrice;
//     // } else if (widget.logType == LogType.reminderMessage) {
//     //   cost = eventPlan?.reminderMessagePrice;
//     // } else {
//     //   cost = eventPlan?.gratitudeMessagePrice;
//     // }
//     // //
//     // showProgress(context: context);
//     // for (Attendee senderItem in widget.senderList) {
//     //   try {
//     //     var pcode = senderItem.id;
//     //     var phn = senderItem.phone;
//     //     var fname = senderItem.fullName;
//     //     var crdlink = "$hfweb/#/$eId/$pcode";
//     //     bmBody['message'] = craftInv(
//     //       logType: widget.logType,
//     //       fullName: fname,
//     //       passcode: pcode,
//     //       cardUrl: crdlink,
//     //       message: controller.text,
//     //     );
//     //     bmBody['recipients'] = [
//     //       {'recipient_id': pcode, 'dest_addr': phn},
//     //     ];

//     //     var resp = await client.post(
//     //       bmsendrl,
//     //       headers: bmHeaders,
//     //       body: jsonEncode(bmBody),
//     //     );
//     //     await Future.delayed(const Duration(milliseconds: 500));

//     //     var stcode = resp.statusCode;
//     //     var body = jsonDecode(resp.body);
//     //     if (stcode == 200) {
//     //       await BalanceService().alterBalance(
//     //         adminId!,
//     //         cost ?? 0.0,
//     //         "MEDIUM Charges",
//     //         cuserId,
//     //         TransactionType.decrease,
//     //       );
//     //       var logRef = firestore
//     //           .collection(msglogcol)
//     //           .doc("${body['request_id']}");
//     //       MessageLog messageLog = MessageLog(
//     //         id: "",
//     //         failureCount: 0,
//     //         message: bmBody['message'],
//     //         eventId: widget.eId,
//     //         attendeeId: pcode ?? 'none',
//     //         type: widget.logType,
//     //         phoneNumber: phn,
//     //         smsStatus: SMSStatus.PENDING,
//     //         timestamp: DateTime.now(),
//     //       );
//     //       logRef.set(messageLog.toMap(), SetOptions(merge: true));
//     //       showToast(isGood: true, msg: "${body['message']}");
//     //     } else {
//     //       showToast(isGood: false, msg: "Code $stcode, $genErrMsg");
//     //     }
//     //   } catch (e) {
//     //     showToast(msg: "$e", isGood: false);
//     //   }
//     // }
//     // popper();
//     // client.close();
//   }

//   craftInv({logType, fullName, passcode, cardUrl, message}) {
//     var newMsg = message.replaceAll("@username", fullName);
//     if (logType == LogType.invitationMessage) {
//       newMsg = newMsg.replaceAll("@passcode", passcode);
//       newMsg = newMsg.replaceAll("@card", cardUrl);
//     }
//     return newMsg;
//   }

//   buildBody() {
//     return ListView(
//       padding: EdgeInsets.zero,
//       children: [
//         RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: "Content ",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).textTheme.bodyMedium?.color,
//                 ),
//               ),
//               const TextSpan(
//                 text: "*",
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: psm * 0.5),
//         buildField(
//           filled: true,
//           isReadOnly: true,
//           cont: controller,
//           showCursor: false,
//         ),
//         const SizedBox(height: psm * 2),
//         if (widget.senderList.isNotEmpty)
//           CupertinoListSection.insetGrouped(
//             margin: EdgeInsets.zero,
//             children: List.generate(widget.senderList.length, (index) {
//               return CheckboxListTile(
//                 value: true,
//                 title: Text(widget.senderList[index].fullName),
//                 onChanged: (change) {},
//               );
//             }),
//           ),
//       ],
//     );
//   }

//   popper() {
//     dismissal(context: context);
//   }
// }
