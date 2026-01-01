import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/index.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/sms/eventTools.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class AdminPanel extends StatefulWidget {
  final Event eventO;
  final bool isAdmin;
  const AdminPanel({super.key, required this.eventO, required this.isAdmin});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  Event? event;
  bool isLoading = false;
  bool hasError = false;
  int invsCount = 0;
  int contsCount = 0;
  int adminsCount = 0;
  int scannersCount = 0;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      DocumentReference<Map<String, dynamic>> eventRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id);
      CollectionReference<Map<String, dynamic>> attsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(atcol);
      var result = await Future.wait([eventRef.get(), attsRef.get()]);
      var eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
      var attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
      invsCount =
          attsSnapshot.docs.where((t) {
            Attendee attendee = Attendee.fromMap(t.id, t.data());
            return attendee.cards.containsKey(KardType.invitation.name);
          }).length;

      contsCount =
          attsSnapshot.docs.where((t) {
            Attendee attendee = Attendee.fromMap(t.id, t.data());
            return attendee.cards.containsKey(KardType.contribution.name);
          }).length;

      event = Event.fromMap(eventSnapshot.id, eventSnapshot.data()!);
      adminsCount = event?.adminsIds?.length ?? 0;
      scannersCount = event?.usersIds?.length ?? 0;
      safeState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint("Error is: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Kituo cha Udhibiti",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: Row(
          children: [
            buildActionButton(
              icon: Icons.share,
              onTap: () async {
                String link =
                    "https://haflaway.com/#/cards/${widget.eventO.id}";
                String message = "Kadi za ${widget.eventO.title}";
                SharePlus.instance.share(
                  ShareParams(text: link, title: message),
                );
              },
            ),
            const SizedBox(width: spaceTiles),
            buildActionButton(
              icon: Icons.edit_document,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CreateEvent(event: event);
                    },
                  ),
                );
                loadData();
              },
            ),
          ],
        ),
      ),
      body: Ccafold(
        child:
            !hasError && isLoading
                ? buildLoader()
                : !hasError && !isLoading
                ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: spaceTiles)),
                    _buildEventImageCard(),
                    _buildAdminToolsSection(),
                    const SliverPadding(padding: EdgeInsets.only(bottom: psm)),
                  ],
                )
                : buildErrorView(),
      ),
    );
  }

  // Mirror-like event image card
  SliverToBoxAdapter _buildEventImageCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(psm, 0, psm, spaceTiles + 1.2),
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(p20),
            boxShadow: [
              BoxShadow(color: Colors.white),
              // BoxShadow(color: Colors.white.withOpacity(0.5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(p20),
            child: Stack(
              children: [
                // Background image
                CachedNetworkImage(
                  imageUrl: event?.eventThumbnail ?? "",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: primaryColor,
                        highlightColor: primaryColor.withValues(alpha: 0.85),
                        child: Container(color: primaryColor),
                      ),
                  errorWidget:
                      (context, url, error) => const Icon(Clarity.error_line),
                ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Title text at the bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Text(
                    event?.title ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminToolsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: psm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildGlassCard(
              child: Column(
                children: [
                  buildGlassListItem(
                    title: "Events Toolkit",
                    subtitle: "Manage event's notifications",
                    icon: Clarity.notification_solid,
                    gradient: [
                      const Color(0xFF4CAF50),
                      const Color(0xFF45A047),
                    ],
                    onTap: () async {
                      try {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventTools(event: event!),
                          ),
                        );
                        loadData();
                      } catch (e) {
                        showToast(isGood: false, msg: e.toString());
                      }
                    },
                  ),

                  buildActionItem(
                    title: "Mialiko ya Digital",
                    children: [
                      ActionItem(
                        figure: "$invsCount",
                        icon: Clarity.email_line,
                        subtitle: "Kadi Zote",
                        onPressed: () async {
                          try {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return Attendees(
                                    edata: event!,
                                    kardType: KardType.invitation,
                                  );
                                },
                              ),
                            );
                            loadData();
                          } catch (e) {
                            showToast(isGood: false, msg: e.toString());
                          }
                        },
                      ),
                      ActionItem(
                        figure: "$invsCount",
                        icon: Clarity.qr_code_line,
                        subtitle: "Skani Kadi",
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CheckPoints(edata: widget.eventO),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: spaceTiles),
                  buildActionItem(
                    title: "Contacts",
                    children: [
                      ActionItem(
                        figure: "0",
                        icon: Clarity.printer_line,
                        subtitle: "Printed Order",
                        onPressed: () {},
                      ),
                      ActionItem(
                        figure: "$contsCount",
                        icon: Clarity.users_line,
                        subtitle: "People reached",
                        onPressed: () async {
                          try {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => Attendees(
                                      edata: event!,
                                      title: "Contributors",
                                      kardType: KardType.contribution,
                                    ),
                              ),
                            );
                            loadData();
                          } catch (e) {
                            showToast(isGood: false, msg: e.toString());
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: spaceTiles),
                  buildActionItem(
                    title: "Users",
                    children: [
                      ActionItem(
                        figure: "$scannersCount",
                        icon: Clarity.qr_code_line,
                        subtitle: "Cards Scanners",
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Users(eId: event?.id ?? ""),
                            ),
                          );
                          loadData();
                        },
                      ),
                      ActionItem(
                        figure: "$adminsCount",
                        icon: Clarity.users_line,
                        subtitle: "Total Admins",
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Users(eId: event?.id ?? ""),
                            ),
                          );
                          loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  popper() {
    Navigator.of(context).pop();
  }
}

class ChkpnForm extends StatefulWidget {
  final String eId;
  const ChkpnForm({super.key, required this.eId});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Kard> fcards =
              (snapshot.data as dynamic).docs.map<Kard>((doc) {
                return Kard.fromMap(doc.id, doc.data());
              }).toList();

          return Form(
            key: key,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: psm,
                vertical: 16,
              ),
              children: [
                const Text(
                  "Checkpoint Name",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter checkpoint name",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      color: Colors.grey[600],
                    ),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? "Name is required"
                              : null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                if (fcards.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 24,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Accepted Cards",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(fcards.length, (idx) {
                        bool isSelected = selCrdsIds.contains(fcards[idx].id);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? secondaryColor.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? secondaryColor.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isSelected ? 0.15 : 0.1,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              fcards[idx].type,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            secondary: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  isSelected
                                      ? secondaryColor
                                      : Colors.grey[600],
                              size: 28,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (isSelected) {
                                  selCrdsIds.remove(fcards[idx].id);
                                } else {
                                  selCrdsIds.add(fcards[idx].id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  )
                else
                  _buildEmptyCardsState(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      !isLoading
                          ? () async {
                            if (key.currentState?.validate() ?? false) {
                              await crtActn(selCrdsIds: selCrdsIds);
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        const Icon(Icons.save_rounded, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isLoading ? "Saving..." : "Save Checkpoint",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center();
        }
        return Center();
      },
    );
  }

  Widget _buildEmptyCardsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Cards Available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> crtActn({selCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      WriteBatch batch = firestore.batch();
      var chkpnRef =
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(echecksub)
              .doc();
      List<DocumentReference<Map<String, dynamic>>> crdRefs = [];
      for (var selCrdsId in selCrdsIds) {
        var tmp = firestore
            .collection(ecol)
            .doc(widget.eId)
            .collection(cardcol)
            .doc(selCrdsId);
        crdRefs.add(tmp);
      }
      CheckPoint checkPoint = CheckPoint(
        id: chkpnRef.id,
        name: controller.text,
      );
      batch.set(chkpnRef, checkPoint.toMap());
      for (var crdRef in crdRefs) {
        batch.update(crdRef, {
          crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
        });
      }
      await batch.commit();
      setState(() => isLoading = false);
      Navigator.pop(context);
      showToast(isGood: true, msg: "Checkpoint created successfully");
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: "$e");
    }
  }
}
