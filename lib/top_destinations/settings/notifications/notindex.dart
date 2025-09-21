import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/models/notication.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:timeago/timeago.dart' as timeago;

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Notifications",
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            popper();
          },
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Ccafold(
          child: SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  dividerHeight: 0,
                  isScrollable: true,
                  labelColor: primaryWhite,
                  labelStyle: TextStyle(
                    fontSize: fsm,
                    fontWeight: FontWeight.bold,
                  ),
                  indicatorColor: primaryWhite,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.only(bottom: psm * 1.35),
                  tabs: [Tab(text: "General"), Tab(text: "For you")],
                ),

                Expanded(
                  child: TabBarView(
                    children: [GeneralNotifications(), ForYouNotification()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}

class GeneralNotifications extends StatefulWidget {
  const GeneralNotifications({super.key});

  @override
  State<GeneralNotifications> createState() => _GeneralNotificationsState();
}

class _GeneralNotificationsState extends State<GeneralNotifications> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection(notifCol)
              .where('userId', isEqualTo: "haflaway")
              .limit(10)
              .snapshots(),
      builder: (context, snapshots) {
        if (snapshots.hasData) {
          var docs = (snapshots.data as dynamic).docs;
          if (docs.isEmpty) {
            return buildEmptyState();
          }
          List<Nottification> notList =
              docs.map<Nottification>((e) {
                return Nottification.fromMap(id: e.id, map: e.data());
              }).toList();
          return buildNottsList(dalist: notList);
        } else if (snapshots.hasError) {
          return buildErrorView();
        } else {
          return Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  buildNottsList({required List<Nottification> dalist}) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 2, left: psm, right: psm, bottom: psm),
      itemCount: dalist.length,
      itemBuilder: (context, index) {
        Nottification nott = dalist[index];

        return nottTile(nott);
      },
    );
  }
}

// For you screens

class ForYouNotification extends StatefulWidget {
  const ForYouNotification({super.key});

  @override
  State<ForYouNotification> createState() => _ForYouNotificationState();
}

class _ForYouNotificationState extends State<ForYouNotification> {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "_id";
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection(notifCol)
              .where('userId', isEqualTo: userId)
              .limit(10)
              .snapshots(),
      builder: (context, snapshots) {
        if (snapshots.hasData) {
          var docs = (snapshots.data as dynamic).docs;
          if (docs.isEmpty) {
            return buildEmptyState();
          }
          List<Nottification> notList =
              docs.map<Nottification>((e) {
                return Nottification.fromMap(id: e.id, map: e.data());
              }).toList();
          return buildNottsList(dalist: notList);
        } else if (snapshots.hasError) {
          return buildErrorView();
        } else {
          return Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  buildNottsList({required List<Nottification> dalist}) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 2, left: psm, right: psm, bottom: psm),
      itemCount: dalist.length,
      itemBuilder: (context, index) {
        Nottification nott = dalist[index];
        return nottTile(nott);
      },
    );
  }
}

nottTile(Nottification nott) {
  String notTStr = nott.createdAt ?? DateTime.now().toIso8601String();
  DateTime? dateTime = DateTime.tryParse(notTStr);
  String currenTStr = 'not set';
  if (dateTime != null) {
    currenTStr = timeago.format(dateTime, locale: 'en_short');
  }
  return Container(
    width: double.maxFinite,
    padding: EdgeInsets.only(
      top: psm * 0.25,
      left: psm * 1.5,
      right: psm * 1.5,
      bottom: psm * 1.5,
    ),
    margin: EdgeInsets.only(bottom: psm),
    decoration: BoxDecoration(
      gradient: lqassgrad,
      borderRadius: BorderRadius.circular(bmd),
      border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: Icon(Icons.verified),
          title: Text(
            "${nott.senderName}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: psm,
              vertical: psm * 0.25,
            ),
            decoration: BoxDecoration(
              gradient: lqassgrad,
              borderRadius: BorderRadius.circular(bsm),
            ),
            child: Text("$currenTStr"),
          ),
        ),
        Text(
          "${nott.title}",
          style: TextStyle(fontSize: fsm + 2, fontWeight: FontWeight.bold),
        ),
        Text("${nott.description}", style: TextStyle(fontSize: fsm)),
      ],
    ),
  );
}
