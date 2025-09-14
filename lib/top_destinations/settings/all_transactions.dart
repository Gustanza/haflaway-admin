import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/models/user_transaction.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';

class AllTransactions extends StatefulWidget {
  const AllTransactions({super.key});

  @override
  State<AllTransactions> createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "notset";
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        leading: buildActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        title: "Recent Transactions",
      ),
      body: Container(
        decoration: BoxDecoration(gradient: scagrad),
        child: FutureBuilder(
          future:
              firestore
                  .collection(userTransCol)
                  .where("authorId", isEqualTo: userId)
                  .limit(100)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var docs = (snapshot.data as dynamic).docs;
              if (docs.isEmpty) {
                return buildEmptyState();
              }
              List<UserTransaction> trns =
                  docs.map<UserTransaction>((doc) {
                    return UserTransaction.fromMap(id: doc.id, map: doc.data());
                  }).toList();
              return buildTrnsList(trns);
            } else if (snapshot.hasError) {
              return buildErrorView();
            } else {
              return Center(child: CupertinoActivityIndicator());
            }
          },
        ),
      ),
    );
  }

  buildTrnsList(List<UserTransaction> trns) {
    return ListView.builder(
      padding: EdgeInsets.all(psm),
      itemCount: trns.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: psm * 0.5),
          decoration: BoxDecoration(
            gradient: lqassgrad,
            border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
            borderRadius: BorderRadius.circular(bmd),
          ),
          child: ListTile(
            leading: Icon(Icons.money),
            title: Text("${trns[index].reason}"),
            subtitle: Text("${trns[index].createdAt}"),
            trailing: Text("${trns[index].amount.toInt()}"),
          ),
        );
      },
    );
  }
}
