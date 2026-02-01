import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class MichangoEditor extends StatefulWidget {
  final Attendee attendee;
  final String eventId;
  final Function(String) onStatusChange;
  const MichangoEditor({
    super.key,
    required this.attendee,
    required this.eventId,
    required this.onStatusChange,
  });

  @override
  State<MichangoEditor> createState() => _MichangoEditorState();
}

class _MichangoEditorState extends State<MichangoEditor> {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  double? pledgedAmount;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController ahadiControler = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Ccafold(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: lqassgradBaseColor,
              expandedHeight: kToolbarHeight * 3,
              flexibleSpace: FlexibleSpaceBar(title: buildAhadi()),
              actions: [
                TextButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text("Hariri"),
                  onPressed: () {
                    showAhadiInput();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  showAhadiInput() {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Form(
            key: key,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: psm * 2,
                horizontal: psm * 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Hariri Ahadi",
                    style: TextStyle(
                      fontSize: fsm + 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spaceTiles),
                  buildField(
                    filled: true,
                    lbl: "Kiasi cha ahadi",
                    cont: ahadiControler,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: spaceTiles * 2),
                  lqAssButton(
                    label: "Tunza",
                    onPressed: () {
                      bool condition = key.currentState?.validate() ?? false;
                      try {
                        if (condition) {
                          setPledge();
                          popper();
                        }
                      } catch (e) {
                        debugPrint("Shida: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  buildAhadi() {
    String ahadi = "Ahadi: Tsh";
    return StreamBuilder(
      stream:
          firestore
              .collection(ecol)
              .doc(widget.eventId)
              .collection(atcol)
              .doc(widget.attendee.id)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          try {
            var freshAtData = snapshot.data;
            var freshAttendee = Attendee.fromMap(
              freshAtData!.id,
              freshAtData.data()!,
            );
            pledgedAmount = freshAttendee.pledgedAmount;
            return Text("$ahadi ${pledgedAmount}");
          } catch (e) {
            return Text("$ahadi e0");
          }
        } else {
          return Text("$ahadi ~0");
        }
      },
    );
  }

  setPledge() {
    firestore
        .collection(ecol)
        .doc(widget.eventId)
        .collection(atcol)
        .doc(widget.attendee.id)
        .set({
          "pledgedAmount": double.tryParse(ahadiControler.text) ?? 0,
        }, SetOptions(merge: true))
        .then((onValue) {
          showToast(isGood: true, msg: "Imefanikiwa");
        })
        .catchError((onError) {
          showToast(isGood: false, msg: "${onError}");
        });
  }

  popper() {
    Navigator.of(context).pop();
  }
}
