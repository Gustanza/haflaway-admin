import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

import 'search.dart';

class Users extends StatefulWidget {
  final String eId;
  const Users({super.key, required this.eId});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: JpSDelegate(eId: widget.eId),
              );
            },
            icon: const Icon(Clarity.add_line),
          ),
          const SizedBox(width: psm * 0.5),
        ],
      ),
      body: StreamBuilder(
        stream: firestore.collection(ecol).doc(widget.eId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = (snapshot.data);
            if (data!.exists) {
              Event event = Event.fromMap(data.id, data.data()!);
              return usersList(event.authorId, event.adminsIds, event.usersIds);
            } else {
              return const BuildNoDt(string: "no data");
            }
          } else if (snapshot.hasError) {
            return buildErr();
          } else {
            return buildLoader();
          }
        },
      ),
    );
  }

  usersList(String oId, List adlist, List ulist) {
    return ListView(
      padding: const EdgeInsets.only(left: psm, right: psm, bottom: psm),
      children: [
        if (adlist.isNotEmpty)
          CupertinoListSection.insetGrouped(
            header: const Text("Admins", style: TextStyle(fontSize: fsm + 1.5)),
            margin: EdgeInsets.zero,
            children: List.generate(adlist.length, (index) {
              return UserTile(
                oId: oId,
                eId: widget.eId,
                where: 'adminsIds',
                firestore: firestore,
                userId: adlist[index],
              );
            }),
          ),
        if (ulist.isNotEmpty)
          CupertinoListSection.insetGrouped(
            header: const Text(
              "Scanning Team",
              style: TextStyle(fontSize: fsm + 1.5),
            ),
            margin: EdgeInsets.zero,
            children: List.generate(ulist.length, (index) {
              return UserTile(
                oId: oId,
                eId: widget.eId,
                where: 'usersIds',
                firestore: firestore,
                userId: ulist[index],
              );
            }),
          ),
      ],
    );
  }
}

class UserTile extends StatefulWidget {
  final String oId;
  final String eId;
  final String where;
  final FirebaseFirestore firestore;
  final String userId;
  const UserTile({
    super.key,
    required this.eId,
    required this.oId,
    required this.userId,
    required this.where,
    required this.firestore,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.firestore.collection(ucol).doc(widget.userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data;
          if (data!.exists) {
            Userr userr = Userr.fromMap(data.id, data.data()!);
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userr.profileImage),
              ),
              title: Text("${userr.firstName} ${userr.lastName}"),
              trailing:
                  widget.oId != widget.userId
                      ? SizedBox(
                        child: IconButton(
                          onPressed: () async {
                            await showDelete();
                          },
                          icon: const Icon(Clarity.trash_line),
                        ),
                      )
                      : const Text("Super Admin"),
            );
          } else {
            return const ListTile(
              leading: CircleAvatar(),
              title: Text("Data unavailable"),
            );
          }
        } else if (snapshot.hasError) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text("Data unavailable"),
          );
        } else {
          return const ListTile(
            leading: CircleAvatar(child: CupertinoActivityIndicator()),
            title: Text("Loading please wait..."),
          );
        }
      },
    );
  }

  Future<void> showDelete() async {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Remove User", style: TextStyle(fontSize: fsm + 2)),
          actions: [
            CupertinoButton(
              child: const Text("Remove"),
              onPressed: () {
                widget.firestore.collection(ecol).doc(widget.eId).update({
                  widget.where: FieldValue.arrayRemove([widget.userId]),
                });
                popper();
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
