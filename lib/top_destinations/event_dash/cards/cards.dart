import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:haflaway/utils/styles.dart';
import 'create_card.dart';

class Cards extends StatefulWidget {
  final String eId;

  const Cards({super.key, required this.eId});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  int currenpage = 1;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dsninv)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondaryColor,
        foregroundColor: primaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return CreateCard(eId: widget.eId);
              },
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection(ecol)
                      .doc(widget.eId)
                      .collection(cardcol)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = (snapshot.data as dynamic).docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No Cards'));
                  } else {
                    List<Kard> cList =
                        docs.map<Kard>((doc) {
                          return Kard.fromMap(doc.id, doc.data());
                        }).toList();
                    return Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            itemCount: cList.length,
                            onPageChanged: (value) {
                              setState(() {
                                currenpage = value + 1;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: psm,
                                  left: psm,
                                  right: psm,
                                  bottom: psm * 0.25,
                                ),
                                child: buildCard(cList[index], () async {
                                  await cdelete(cList[index]);
                                }),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: psm),
                          child: Text(
                            "$currenpage of ${cList.length} Cards",
                            style: const TextStyle(
                              fontSize: fsm,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                } else if (snapshot.hasError) {
                  return buildErr();
                } else {
                  return buildLoader();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  cdelete(Kard kard) async {
    return await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Slow down !"),
          content: const Text(
            "Are you sure you want to delete this card?. This action can't be reversed",
          ),
          actions: [
            CupertinoButton(
              child: const Text("Delete"),
              onPressed: () async {
                try {
                  showProgress(context: context);
                  var ctref = firestore.collection(cardcol).doc(kard.id);
                  var snapshot = await ctref.get();
                  if (snapshot.exists) {
                    WriteBatch batch = firestore.batch();
                    var cref = firestore
                        .collection(ecol)
                        .doc(widget.eId)
                        .collection(cardcol)
                        .doc(kard.id);
                    var doc = snapshot.data();
                    var crl = doc![tempccurl];
                    batch.delete(ctref);
                    batch.delete(cref);
                    batch.commit();
                    var cstref = storage.refFromURL(crl);
                    await cstref.delete();
                  }
                  popper();
                  popper();
                  showToast(msg: "Success", isGood: true);
                } catch (e) {
                  showToast(msg: "$e", isGood: false);
                  popper();
                  popper();
                }
              },
            ),
            CupertinoButton(
              child: const Text("Cancel"),
              onPressed: () {
                popper();
              },
            ),
          ],
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
