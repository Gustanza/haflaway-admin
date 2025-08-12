import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class JpSDelegate extends SearchDelegate {
  final String eId;

  JpSDelegate({required this.eId});
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  InputDecorationTheme? get searchFieldDecorationTheme =>
      const InputDecorationTheme(
        hintStyle: TextStyle(fontSize: fsm + 2),
        border: InputBorder.none,
      );

  @override
  TextStyle? get searchFieldStyle => const TextStyle(fontSize: fsm);

  @override
  String? get searchFieldLabel => 'Search email';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isNotEmpty) {
            query = '';
          } else {
            close(context, null);
          }
        },
        icon: const Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    String sqry = query.toLowerCase().trim();
    return FutureBuilder(
      future: firestore.collection(ucol).where("email", isEqualTo: sqry).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var docs = (snapshot.data as dynamic).docs;
          if (docs.isEmpty) {
            return const BuildNoDt(string: "no data");
          } else {
            List<Userr> users =
                docs.map<Userr>((doc) {
                  return Userr.fromMap(doc.id, doc.data());
                }).toList();
            return SearchResults(
              firestore: firestore,
              users: users,
              eId: eId,
              onFinish: () {
                close(context, null);
              },
            );
          }
        }
        if (snapshot.hasError) {
          return buildErr();
        } else {
          return buildLoader();
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center();
  }
}

class SearchResults extends StatefulWidget {
  final String eId;
  final List<Userr> users;
  final Function() onFinish;
  final FirebaseFirestore firestore;
  const SearchResults({
    super.key,
    required this.onFinish,
    required this.eId,
    required this.users,
    required this.firestore,
  });

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(psm),
      children: [
        CupertinoListSection.insetGrouped(
          margin: EdgeInsets.zero,
          children: List.generate(widget.users.length, (index) {
            Userr userr = widget.users[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userr.profileImage),
                  ),
                  title: Text(
                    "${userr.firstName} ${userr.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(userr.email),
                ),
                Row(
                  children: [
                    Expanded(
                      child: MaterialButton(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(bmd),
                          ),
                        ),
                        color: primaryColor,
                        onPressed: () {
                          widget.firestore
                              .collection(ecol)
                              .doc(widget.eId)
                              .update({
                                'adminsIds': FieldValue.arrayUnion([userr.id]),
                              });
                          widget.onFinish();
                        },
                        child: const Text(
                          "Add as Admin",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: psm * 0.25),
                    Expanded(
                      child: MaterialButton(
                        color: primaryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(bmd),
                          ),
                        ),
                        onPressed: () {
                          widget.firestore
                              .collection(ecol)
                              .doc(widget.eId)
                              .update({
                                'usersIds': FieldValue.arrayUnion([userr.id]),
                              });
                          widget.onFinish();
                        },
                        child: const Text(
                          "Add as Scanner",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
