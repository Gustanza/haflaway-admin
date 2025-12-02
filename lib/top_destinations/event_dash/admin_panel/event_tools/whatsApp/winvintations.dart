import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/attendee_message.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/reusables/stuff.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:string_similarity/string_similarity.dart';

class WInvSender extends StatefulWidget {
  final Event event;
  final String campaignId;
  final KardType kardType;
  final Function(List<Attendee>) onChanged;

  const WInvSender({
    super.key,
    required this.event,
    required this.kardType,
    required this.campaignId,
    required this.onChanged,
  });

  @override
  State<WInvSender> createState() => _WInvSenderState();
}

class _WInvSenderState extends State<WInvSender> {
  int cost = 0;
  List<Attendee> senderList = [];
  WspDStates grpState = WspDStates.unsent;
  SenderChannels grpChnl = SenderChannels.all;
  TextEditingController scont = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: psm * 0.5, left: psm, right: psm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  SenderChannels.values.map((e) {
                    bool isSelected = e == grpChnl;
                    return Padding(
                      padding: const EdgeInsets.only(right: psm * 0.75),
                      child: FilterChip(
                        label: Text(e.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              grpChnl = e;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  WspDStates.values.map((e) {
                    bool isSelected = e == grpState;
                    return Padding(
                      padding: const EdgeInsets.only(right: psm * 0.75),
                      child: FilterChip(
                        label: Text(e.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              grpState = e;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: psm * 0.5),
          Expanded(
            child: StreamBuilder(
              stream:
                  firestore
                      .collection(ecol)
                      .doc(widget.event.id)
                      .collection(atcol)
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Attendee> docs =
                      (snapshot.data as dynamic).docs
                          .where((doc) {
                            try {
                              return doc['cards'][widget.kardType.name] != null;
                            } catch (e) {
                              return false;
                            }
                          })
                          .map<Attendee>((doc) {
                            return Attendee.fromMap(doc.id, doc.data());
                          })
                          .toList();
                  if (docs.isEmpty) {
                    return const BuildNoDt(string: "No Attendees Found");
                  } else {
                    if (scont.text.isNotEmpty) {
                      docs.sort((a, b) {
                        var bm1 = StringSimilarity.compareTwoStrings(
                          scont.text,
                          a.fullName,
                        );
                        var bm2 = StringSimilarity.compareTwoStrings(
                          scont.text,
                          b.fullName,
                        );
                        return bm2.compareTo(bm1);
                      });
                    }
                    return buildAttList(docs);
                  }
                } else if (snapshot.hasError) {
                  return buildErr();
                } else {
                  return buildLoader();
                }
              },
            ),
          ),
          const SizedBox(height: psm * 0.5),
        ],
      ),
    );
  }

  buildAttList(List<Attendee> attArgs) {
    List<Attendee> attendees =
        attArgs.where((oneAttendee) {
          var msgs = oneAttendee.messages;
          List<AttendeeMessage> messages =
              msgs.entries.map<AttendeeMessage>((entry) {
                return AttendeeMessage.fromMap(id: entry.key, map: entry.value);
              }).toList();
          if (messages.isEmpty && grpState == WspDStates.unsent) {
            return true;
          }

          List<AttendeeMessage> targetMessages =
              messages.where((tstMsg) {
                bool cndtn1 = false;
                if (tstMsg.type == widget.campaignId) {
                  if (grpChnl.name == SenderChannels.all.name) {
                    cndtn1 =
                        tstMsg.channel == SenderChannels.whatsapp.name ||
                        tstMsg.channel == SenderChannels.sms.name;
                  } else if (grpChnl.name == SenderChannels.whatsapp.name) {
                    cndtn1 = tstMsg.channel == SenderChannels.whatsapp.name;
                  } else if (grpChnl.name == SenderChannels.sms.name) {
                    cndtn1 = tstMsg.channel == SenderChannels.sms.name;
                  }
                }
                return cndtn1;
                // tstMsg.channel == SenderChannels.whatsapp.name &&
                //     tstMsg.type == widget.campaignId;
              }).toList();
          if (targetMessages.isEmpty && grpState == WspDStates.unsent) {
            return true;
          }
          return targetMessages.any((tst) {
            return tst.status == grpState.name;
          });
        }).toList();
    return Column(
      children: [
        buildField(
          cont: scont,
          filled: true,
          lbl: "Search Attendee",
          isChanged: () {
            setState(() {});
          },
        ),
        if (attendees.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MaterialButton(
                onPressed: () {
                  if (senderList.length != attendees.length) {
                    senderList = [];
                    senderList.addAll(attendees);
                  } else {
                    senderList = [];
                  }
                  widget.onChanged(senderList);
                },
                child: Text(
                  senderList.length != attendees.length
                      ? "Select All"
                      : "Remove All",
                ),
              ),
              if (senderList.isNotEmpty)
                MaterialButton(
                  onPressed: () {},
                  child: Text("Total (${senderList.length})"),
                ),
            ],
          ),

        Expanded(
          child: SingleChildScrollView(
            child:
                attendees.isNotEmpty
                    ? Column(
                      children: List.generate(attendees.length, (index) {
                        Attendee rdata = attendees[index];
                        bool containz = senderList.any((item) {
                          return item.id == rdata.id;
                        });
                        return buildInvite(
                          containz: containz,
                          rdata: rdata,
                          kardType: widget.kardType,
                          eventId: widget.event.id,
                          onChanged: (change) {
                            onCheckTap(rdata: rdata, containz: containz);
                          },
                        );
                      }),
                    )
                    : const BuildNoDt(string: "No Data"),
          ),
        ),
      ],
    );
  }

  onCheckTap({rdata, containz}) {
    if (containz) {
      List<Attendee> tmp =
          senderList.where((test) {
            return test.id != rdata.id;
          }).toList();
      senderList = tmp;
    } else {
      senderList.add(rdata);
    }
    widget.onChanged(senderList);
  }
}
