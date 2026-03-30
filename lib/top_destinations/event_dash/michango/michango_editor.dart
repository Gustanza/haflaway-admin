import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/mchango.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'dart:ui' as ui;

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
      backgroundColor: scaback,
      appBar: uppBar(
        leading: gsUppBack(context: context),
        title: "${widget.attendee.fullName}",
        centerTitle: false,
        actions: <Widget>[
          gsFloatingButton(
            icon: Icons.edit,
            onTap: () {
              showMoneyInput(
                title: "Record Pledge",
                controller: ahadiController,
                label: "Pledge Amount",
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
          const SizedBox(width: psm),
        ],
      ),
      body: Ccafold(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                width: double.maxFinite,
                child: buildAhadi(),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: lqassgrad,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      showMoneyInput(
                        title: "Record Contribution",
                        controller: mchangoController,
                        label: "Contribution Amount",
                        onPressed: () {
                          bool condition =
                              key.currentState?.validate() ?? false;
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
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "Add Contribution",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 16),
                      child: Text(
                        "Historia ya Michango",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StreamBuilder(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildMichango(List<Mchango> michango) {
    return Column(
      children:
          michango.map((mchango) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                // color: Colors.white,
                gradient: lqassgrad,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showMoneyInput(
                      title: "Record Contribution",
                      controller: mchangoController,
                      label: "Contribution Amount",
                      initialAmount: mchango.amount,
                      onPressed: () {
                        bool condition = key.currentState?.validate() ?? false;
                        try {
                          if (condition) {
                            double amount = double.parse(
                              mchangoController.text,
                            );
                            setMchango(amount: amount, id: mchango.id);
                            popper();
                          }
                        } catch (e) {
                          debugPrint("Shida: $e");
                        }
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tsh ${mchango.amount?.toStringAsFixed(0) ?? '0'}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  // color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(mchango.createdAt),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (mchango.method == PayMethod.manual)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    showMoneyInput(
                                      title: "Record Contribution",
                                      controller: mchangoController,
                                      label: "Contribution Amount",
                                      initialAmount: mchango.amount,
                                      onPressed: () {
                                        bool condition =
                                            key.currentState?.validate() ??
                                            false;
                                        try {
                                          if (condition) {
                                            double amount = double.parse(
                                              mchangoController.text,
                                            );
                                            setMchango(
                                              amount: amount,
                                              id: mchango.id,
                                            );
                                            popper();
                                          }
                                        } catch (e) {
                                          debugPrint("Shida: $e");
                                        }
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    confirmDel(mchango: mchango);
                                  },
                                  icon: Icon(
                                    Icons.delete_forever,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Haijulikani';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Haijulikani';
    }
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
              padding: const EdgeInsets.all(psm * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade500, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: lqassgradBaseColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lqassbdrColor,
                        width: bdrWidthGen,
                      ),
                    ),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: label,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        labelStyle: TextStyle(
                          // color: Colors.grey.shade600,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza kiasi';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Tafadhali ingiza namba halali';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade500,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onPressed,
                              child: const Center(
                                child: Text(
                                  "Tunza Rekodi",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red.shade500, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Thibitisha Kitendo",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  "You are about to delete a contribution record of TZS ${mchango.amount}. Confirm to proceed.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red.shade500, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              firestore
                                  .collection(ecol)
                                  .doc(widget.eventId)
                                  .collection(atcol)
                                  .doc(widget.attendee.id)
                                  .collection(atPaySub)
                                  .doc(mchango.id)
                                  .delete()
                                  .then((onValue) {
                                    showToast(isGood: true, msg: "Imefanikiwa");
                                  })
                                  .catchError((onError) {
                                    showToast(isGood: false, msg: "${onError}");
                                  });
                              popper();
                            },
                            child: const Center(
                              child: Text(
                                "Futa Rekodi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              popper();
                            },
                            child: Center(
                              child: Text(
                                "Sitisha",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  buildAhadi() {
    String ahadi = "Pledge: TZS";
    String mchango = "Contribution: TZS";
    return Container(
      decoration: BoxDecoration(gradient: lqassgrad),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: StreamBuilder(
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
                                const Text(
                                  "Muhtasari wa Michango",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: bdrWidthGen,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ahadi,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${pledgedAmount?.toStringAsFixed(0) ?? '0'}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 60,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: psm,
                                        ),
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mchango,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${paidAmount?.toStringAsFixed(0) ?? '0'}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          showToast(isGood: true, msg: "Imefanikiwa");
          mchangoController.clear();
        })
        .catchError((onError) {
          showToast(isGood: false, msg: "${onError}");
        });
  }

  popper() {
    Navigator.of(context).pop();
  }
}
