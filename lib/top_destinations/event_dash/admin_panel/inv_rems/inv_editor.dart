import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/logs.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:icons_plus/icons_plus.dart';

class InvEditor extends StatefulWidget {
  final String eId;
  const InvEditor({super.key, required this.eId});

  @override
  State<InvEditor> createState() => _InvEditorState();
}

class _InvEditorState extends State<InvEditor> {
  bool isSaving = false;
  GlobalKey<FormState> key = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(compinv),
        actions: [
          IconButton(
            onPressed: () async {
              await showCreate();
            },
            icon: Icon(Clarity.plus_line),
          ),
        ],
      ),
      body: StreamBuilder(
        stream:
            firestore
                .collection(ecol)
                .doc(widget.eId)
                .collection(eMsgTmpCol)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.docs.isNotEmpty) {
              var docs = (snapshot.data as dynamic).docs;
              List<MessageTemplate> messageLogs =
                  docs.map<MessageTemplate>((e) {
                    return MessageTemplate.fromMap(e.id, e.data());
                  }).toList();
              return buildBody(messageLogs);
            } else {
              return const BuildNoDt(string: "Data not found");
            }
          }
          if (snapshot.hasError) {
            return buildErr();
          } else {
            return buildLoader();
          }
        },
      ),
    );
  }

  buildBody(List<MessageTemplate> msgTmps) {
    List<TextEditingController> controllers = [];
    for (var lmnt in msgTmps) {
      controllers.add(TextEditingController(text: lmnt.content));
    }
    return ListView.builder(
      padding: EdgeInsets.all(psm),
      itemCount: msgTmps.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            buildField(cont: controllers[index]),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await showCreate(msgTmp: msgTmps[index]);
                  },
                  icon: Icon(Clarity.edit_line, size: icnmd - 2),
                  label: Text("Edit"),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await showDelete(id: msgTmps[index].id);
                  },
                  icon: Icon(
                    Clarity.trash_line,
                    color: destructiveColor,
                    size: icnmd - 2,
                  ),
                  label: Text(
                    "Delete",
                    style: TextStyle(color: destructiveColor),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  showCreate({MessageTemplate? msgTmp}) async {
    TextEditingController cnt = TextEditingController(
      text: msgTmp != null ? msgTmp.content : "",
    );
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Template"),
          content: buildField(cont: cnt),
          actions: [
            MaterialButton(
              elevation: 0,
              color: primaryColor.withValues(alpha: 0.2),
              child: Text("Cancel"),
              onPressed: () {
                popper();
              },
            ),
            MaterialButton(
              elevation: 0,
              color: primaryColor,
              child: Text("Create", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (cnt.text.isEmpty) {
                  //popper();
                }
                if (msgTmp != null) {
                  firestore
                      .collection(ecol)
                      .doc(widget.eId)
                      .collection(eMsgTmpCol)
                      .doc(msgTmp.id)
                      .update({'content': cnt.text});
                } else {
                  MessageTemplate msgTemp = MessageTemplate(
                    id: 'id',
                    category: 'sms_invitation_messages',
                    content: cnt.text,
                    language: 'en',
                  );
                  firestore
                      .collection(ecol)
                      .doc(widget.eId)
                      .collection(eMsgTmpCol)
                      .add(msgTemp.toMap());
                }
                popper();
              },
            ),
          ],
        );
      },
    );
  }

  showDelete({String? id}) async {
    return await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Confirm Delete"),
          actions: [
            MaterialButton(
              elevation: 0,
              color: primaryColor.withValues(alpha: 0.2),
              child: Text("Cancel"),
              onPressed: () {
                popper();
              },
            ),
            MaterialButton(
              elevation: 0,
              color: destructiveColor,
              child: Text("Delete", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(eMsgTmpCol)
                    .doc(id)
                    .delete();
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
