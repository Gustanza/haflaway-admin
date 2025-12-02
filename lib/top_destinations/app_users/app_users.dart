import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class AppUsersScreen extends StatefulWidget {
  const AppUsersScreen({super.key});

  @override
  State<AppUsersScreen> createState() => _AppUsersScreenState();
}

class _AppUsersScreenState extends State<AppUsersScreen> {
  int pageSize = 6;
  List<Userr> users = [];
  bool isLoading = false;
  String selectedStatus = 'All';
  String selectedClearance = 'All';
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController scrollController = ScrollController();

  popper() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent) {
      if (!isLoading) {
        loadMoreUsers();
      }
    }
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  loadUsers() async {
    safeState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> res =
          await firestore
              .collection(ucol)
              .orderBy('registrationDate', descending: true)
              .limit(pageSize)
              .get();
      lastDocument = res.docs.last;
      users =
          res.docs.map<Userr>((e) {
            return Userr.fromMap(e.id, e.data());
          }).toList();
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  loadMoreUsers() async {
    safeState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> res =
          await firestore
              .collection(ucol)
              .orderBy('registrationDate', descending: true)
              .startAfterDocument(lastDocument!)
              .limit(pageSize)
              .get();
      lastDocument = res.docs.last;
      List<Userr> tmpusers =
          res.docs.map<Userr>((e) {
            return Userr.fromMap(e.id, e.data());
          }).toList();
      users.addAll(tmpusers);
    } catch (e) {
      showToast(isGood: false, msg: "$e");
    }
    safeState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Users List",
        leading: appBarActionButton(
          onTap: () {
            popper();
          },
          icon: Icons.arrow_back,
        ),
        actions: Row(
          children: [
            appBarActionButton(
              icon: Icons.add,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return Msajili();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Ccafold(
        child:
            users.isEmpty && isLoading
                ? buildLoader()
                : users.isEmpty && !isLoading
                ? BuildNoDt(
                  string: "No Users Found",
                  isRefreshed: () async {
                    await loadUsers();
                  },
                )
                : ListView.builder(
                  itemCount: users.length + 1,
                  padding: EdgeInsets.all(psm),
                  controller: scrollController,
                  itemBuilder: (context, index) {
                    if (index == users.length && isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    } else if (index == users.length && !isLoading) {
                      return const SizedBox.shrink();
                    }
                    final user = users[index];
                    return _buildUserCard(userr: user);
                  },
                ),
      ),
    );
  }

  Widget _buildUserCard({required Userr userr}) {
    final isActive = userr.isActive ?? false;
    final statusColor = lqassgradBaseColor;
    final clearanceColor = lqassgradBaseColor;

    return Container(
      margin: const EdgeInsets.only(bottom: psm * 0.75),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        border: Border.all(width: bdrWidthGen, color: lqassbdrColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${userr.firstName} ${userr.lastName}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      userr.phoneNumber ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      userr.email ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: IconButton.outlined(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Msajili(userr: userr);
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(
                isActive,
                statusColor,
                isActive ? "Active" : "Suspended",
                userr,
              ),
              const SizedBox(width: 8),
              _buildBalanceChip(userr, lqassgradBaseColor),
              const SizedBox(width: 8),
              _buildClearanceChip("${userr.clearanceLevel}", clearanceColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    bool isActive,
    Color? color,
    String label,
    Userr userr,
  ) {
    return GestureDetector(
      onTap: () {
        alterStatus(userr: userr);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: color!.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: primaryWhite,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearanceChip(String clearance, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, size: 16, color: primaryWhite),
          const SizedBox(width: 4),
          Text(
            clearance,
            style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(Userr userr, Color color) {
    return GestureDetector(
      onTap: () {
        alterBalance(userr: userr);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Text(
              "TZS",
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "${userr.balance?.toInt()}",
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  alterStatus({required Userr userr}) {
    bool isActive = userr.isActive ?? false;
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: StatefulBuilder(
            builder: (context, settState) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: psm,
                  right: psm,
                  top: p20,
                  bottom: p20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${userr.firstName} ${userr.lastName}",
                      style: TextStyle(
                        fontSize: fsm + 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(thickness: 0.1),
                    SwitchListTile(
                      title: Text("Account Status"),
                      value: isActive,
                      onChanged: (v) {
                        settState(() {
                          isActive = v;
                        });
                      },
                    ),
                    const SizedBox(height: psm * 0.5),
                    lqAssButton(
                      label: "Save Changes",
                      onPressed: () {
                        firestore
                            .collection(ucol)
                            .doc(userr.id)
                            .set({
                              "isActive": isActive,
                            }, SetOptions(merge: true))
                            .then((o) {
                              showToast(isGood: true, msg: "Success");
                            });
                        popper();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  alterBalance({required Userr userr}) {
    bool overwriteSgn = false;
    GlobalKey<FormState> key = GlobalKey<FormState>();
    TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: StatefulBuilder(
            builder: (context, settState) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: psm,
                  right: psm,
                  top: p20,
                  bottom: p20,
                ),
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${userr.firstName} ${userr.lastName}",
                        style: TextStyle(
                          fontSize: fsm + 6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(thickness: 0.1),
                      const SizedBox(height: psm * 0.5),
                      buildField(
                        lbl: "1000",
                        filled: true,
                        cont: controller,
                        type: TextInputType.number,
                      ),
                      SwitchListTile(
                        value: overwriteSgn,
                        title: Text("Overwrite existing"),
                        subtitle: Text(
                          "Current: TZS ${userr.balance?.toInt()}",
                        ),
                        onChanged: (v) {
                          settState(() {
                            overwriteSgn = v;
                          });
                        },
                      ),
                      lqAssButton(
                        label: "Save Changes",
                        onPressed: () {
                          bool isValid = key.currentState?.validate() ?? false;
                          if (!isValid) return;
                          try {
                            double balanc =
                                double.tryParse(controller.text) ?? 0.00;
                            firestore
                                .collection(ucol)
                                .doc(userr.id)
                                .set({
                                  "balance":
                                      overwriteSgn
                                          ? balanc
                                          : FieldValue.increment(balanc),
                                }, SetOptions(merge: true))
                                .then((o) {
                                  showToast(isGood: true, msg: "Success");
                                });
                            popper();
                          } catch (e) {
                            showToast(isGood: false, msg: "$e");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
