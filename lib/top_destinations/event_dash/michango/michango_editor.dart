import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/mchango.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class MichangoEditor extends StatefulWidget {
  final Attendee attendee;
  final String eventId;
  const MichangoEditor({
    super.key,
    required this.attendee,
    required this.eventId,
  });

  @override
  State<MichangoEditor> createState() => _MichangoEditorState();
}

class _MichangoEditorState extends State<MichangoEditor> {
  GlobalKey<FormState> key = GlobalKey<FormState>();
  double? pledgedAmount;
  double? paidAmount;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController ahadiController = TextEditingController();
  TextEditingController mchangoController = TextEditingController();
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
                  label: Text("Ongeza Ahadi"),
                  onPressed: () {
                    showMoneyInput(
                      title: "Rekodi Ahadi",
                      controller: ahadiController,
                      label: "Kiasi cha Ahadi",
                      initialAmount: pledgedAmount,
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
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsetsGeometry.all(spaceTiles),
              sliver: SliverToBoxAdapter(
                child: lqAssButton(
                  label: "Ongeza Mchango",
                  onPressed: () {
                    showMoneyInput(
                      title: "Rekodi Mchango",
                      controller: mchangoController,
                      label: "Kiasi cha Mchango",
                      onPressed: () {
                        bool condition = key.currentState?.validate() ?? false;
                        try {
                          if (condition) {
                            double amount = double.parse(
                              mchangoController.text,
                            );
                            setMchango(amount: amount);
                            popper();
                          }
                        } catch (e) {
                          debugPrint("Shidar: $e");
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsetsGeometry.only(
                left: spaceTiles,
                right: spaceTiles,
                bottom: spaceTiles,
              ),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder(
                  stream:
                      firestore
                          .collection(ecol)
                          .doc(widget.eventId)
                          .collection(atcol)
                          .doc(widget.attendee.id)
                          .collection(atPaySub)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var docs = (snapshot.data as dynamic).docs;
                      if (docs.isEmpty) return buildEmptyState();
                      List<Mchango> michangoList =
                          docs.map<Mchango>((e) {
                            return Mchango.fromMap(e.id, e.data());
                          }).toList();
                      return buildMichango(michangoList);
                    }
                    if (snapshot.hasError) {
                      return buildErrorView(onPressed: () {});
                    } else {
                      return buildLoader();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildMichango(List<Mchango> michango) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: michango.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(bsm),
          child: Container(
            margin: EdgeInsets.only(bottom: spaceTiles),
            child: CupertinoListTile(
              leading: Icon(Icons.graphic_eq),
              // padding: EdgeInsets.all(spaceTiles),
              additionalInfo: IconButton.outlined(
                onPressed: () {
                  showMoneyInput(
                    title: "Rekodi Mchango",
                    controller: mchangoController,
                    label: "Kiasi cha Mchango",
                    initialAmount: michango[index].amount,
                    onPressed: () {
                      bool condition = key.currentState?.validate() ?? false;
                      try {
                        if (condition) {
                          double amount = double.parse(mchangoController.text);
                          setMchango(amount: amount, id: michango[index].id);
                          popper();
                        }
                      } catch (e) {
                        debugPrint("Shida: $e");
                      }
                    },
                  );
                },
                icon: Icon(Icons.edit, color: Colors.green),
              ),
              trailing: IconButton.outlined(
                onPressed: () {
                  confirmDel(mchango: michango[index]);
                },
                icon: Icon(Icons.delete_forever, color: Colors.red),
              ),
              backgroundColor: lqassgradBaseColor,
              title: Text("${michango[index].amount}"),
            ),
          ),
        );
      },
    );
  }

  showMoneyInput({initialAmount, title, controller, label, onPressed}) {
    if (initialAmount != null) controller.text = initialAmount.toString();
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
                    "$title",
                    style: TextStyle(
                      fontSize: fsm + 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spaceTiles),
                  buildField(
                    filled: true,
                    lbl: "$label",
                    cont: controller,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: spaceTiles * 2),
                  lqAssButton(label: "Tunza Rekodi", onPressed: onPressed),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  confirmDel({required Mchango mchango}) {
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
                    "Thibitisha Kitendo",
                    style: TextStyle(
                      fontSize: fsm + 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spaceTiles),
                  Text(
                    "Unaelekea kufuta rekodi ya kiasi cha Tsh ${mchango.amount}, Thibitisha ili kufanikisha",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // fontSize: fsm ,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: spaceTiles * 2),
                  lqAssButton(
                    label: "Futa Rekodi",
                    onPressed: () {
                      firestore
                          .collection(ecol)
                          .doc(widget.eventId)
                          .collection(atcol)
                          .doc(widget.attendee.id)
                          .collection(atPaySub)
                          .doc(mchango.id)
                          .delete()
                          .then((onValue) {
                            reconMchango();
                            showToast(isGood: true, msg: "Imefanikiwa");
                          })
                          .catchError((onError) {
                            showToast(isGood: false, msg: "${onError}");
                          });
                      popper();
                    },
                  ),
                  const SizedBox(height: spaceTiles),
                  lqAssButton(
                    label: "Sitisha",
                    onPressed: () {
                      popper();
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
    String mchango = "Mchango: Tsh";
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
            paidAmount = freshAttendee.paidAmount;
            pledgedAmount = freshAttendee.pledgedAmount;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text("$ahadi ${pledgedAmount}"),
                  subtitle: Text("$mchango ${paidAmount}"),
                ),
              ],
            );
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
          "pledgedAmount": double.tryParse(ahadiController.text) ?? 0,
        }, SetOptions(merge: true))
        .then((onValue) {
          showToast(isGood: true, msg: "Imefanikiwa");
          ahadiController.clear();
        })
        .catchError((onError) {
          showToast(isGood: false, msg: "${onError}");
        });
  }

  setMchango({amount, id}) {
    Mchango mchango = Mchango(
      amount: amount ?? 0,
      createdAt: DateTime.now().toIso8601String(),
    );
    CollectionReference<Map<String, dynamic>> mchColRef = firestore
        .collection(ecol)
        .doc(widget.eventId)
        .collection(atcol)
        .doc(widget.attendee.id)
        .collection(atPaySub);

    var mchId = id ?? mchColRef.doc().id;

    mchColRef
        .doc(mchId)
        .set(mchango.toMap(), SetOptions(merge: true))
        .then((onValue) {
          reconMchango();
          mchangoController.clear();
        })
        .catchError((onError) {
          showToast(isGood: false, msg: "${onError}");
        });
  }

  reconMchango() {
    try {
      return firestore
          .collection(ecol)
          .doc(widget.eventId)
          .collection(atcol)
          .doc(widget.attendee.id)
          .collection(atPaySub)
          .get()
          .then((snapshot) {
            var michDocs = snapshot.docs;
            var michango = michDocs.map((e) {
              return Mchango.fromMap(e.id, e.data());
            });
            double total = 0.0;
            for (var mchango in michango) {
              total += mchango.amount ?? 0.0;
            }
            firestore
                .collection(ecol)
                .doc(widget.eventId)
                .collection(atcol)
                .doc(widget.attendee.id)
                .set({"paidAmount": total}, SetOptions(merge: true))
                .then((onValue) {
                  showToast(isGood: true, msg: "Imefanikiwa");
                });
          });
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
  }

  popper() {
    Navigator.of(context).pop();
  }
}
