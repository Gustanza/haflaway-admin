import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/components/templates.dart' hide buildActionButton;
import 'package:haflaway/models/campaign.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/generales/wsap.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/errorstrs.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:icons_plus/icons_plus.dart';

class AdminCampaigns extends StatefulWidget {
  final Event event;
  final String title;
  final KardType kardType;
  const AdminCampaigns({
    super.key,
    required this.event,
    required this.title,
    required this.kardType,
  });

  @override
  State<AdminCampaigns> createState() => _AdminCampaignsState();
}

class _AdminCampaignsState extends State<AdminCampaigns> {
  TextEditingController controller = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "${widget.title}",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: Row(
          children: [
            appBarActionButton(
              icon: Icons.add,
              onTap: () {
                showSelectCard();
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: StreamBuilder(
          stream:
              firestore
                  .collection(ecol)
                  .doc(widget.event.id)
                  .collection(campcol)
                  .where("type", isEqualTo: widget.kardType.name)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var docs = (snapshot.data as dynamic).docs;
              if (docs.isEmpty) {
                return buildEmptyState();
              }
              List<Campaign> campList =
                  docs.map<Campaign>((d) {
                    return Campaign.fromMap(id: d.id, map: d.data());
                  }).toList();
              return buildBody(campList: campList);
            }
            if (snapshot.hasError) {
              return buildErrorView();
            } else {
              return buildLoader();
            }
          },
        ),
      ),
    );
  }

  buildBody({required List<Campaign> campList}) {
    return ListView.builder(
      padding: EdgeInsets.all(psm),
      itemCount: campList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPress: () {
            showSelectCard(campaign: campList[index]);
          },
          child: buildListItemCard(
            title: "${campList[index].name}",
            subtitle: "${campList[index].createdAt}",
            icon: Clarity.chat_bubble_solid_badged,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return InvitesIssuers(
                      event: widget.event,
                      kardType: widget.kardType,
                      campaignId: campList[index].id ?? "randy",
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  showSelectCard({Campaign? campaign}) {
    String flabel = "Campaign name";
    String blabel = campaign == null ? "Create" : "Save";
    String tlabel = campaign == null ? "New Campaign" : "Edit Campaign";
    if (campaign != null) controller.text = campaign.name ?? "";
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: psm,
              vertical: psm * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tlabel,
                  style: TextStyle(
                    fontSize: fsm + 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: psm),
                buildField(lbl: flabel, cont: controller),
                const SizedBox(height: psm * 1.5),
                lqAssButton(
                  label: blabel,
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      showToast(isGood: false, msg: "Name is required");
                      return;
                    }
                    if (campaign == null) {
                      createCamp();
                    } else {
                      editCamp(id: campaign.id ?? "unknown");
                    }
                    controller.clear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  createCamp() {
    Campaign campaign = Campaign(
      name: controller.text.trim(),
      type: widget.kardType.name,
      createdAt: DateTime.now().toIso8601String(),
    );
    firestore
        .collection(ecol)
        .doc(widget.event.id)
        .collection(campcol)
        .add(campaign.toMap())
        .then((v) {
          showToast(isGood: true, msg: "Success");
        })
        .catchError((e) {
          showToast(isGood: false, msg: genErrMsg);
        });
  }

  editCamp({required String id}) {
    Campaign campaign = Campaign(
      name: controller.text.trim(),
      type: widget.kardType.name,
      updatedAt: DateTime.now().toIso8601String(),
    );
    firestore
        .collection(ecol)
        .doc(widget.event.id)
        .collection(campcol)
        .doc(id)
        .set(campaign.toMap(), SetOptions(merge: true))
        .then((v) {
          showToast(isGood: true, msg: "Success");
        })
        .catchError((e) {
          showToast(isGood: false, msg: genErrMsg);
        });
  }
}
