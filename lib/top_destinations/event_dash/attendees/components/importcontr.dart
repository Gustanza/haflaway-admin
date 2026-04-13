import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/imp_preview.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:string_similarity/string_similarity.dart';

class ImportContributor extends StatefulWidget {
  final Event event;
  final Kard kard;
  final bool isContactImport;
  final List<AttendeeLabel> availableLabels;
  const ImportContributor({
    super.key,
    required this.event,
    required this.kard,
    this.isContactImport = false,
    this.availableLabels = const [],
  });

  @override
  State<ImportContributor> createState() => _ImportContributorState();
}

class _ImportContributorState extends State<ImportContributor> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore
              .collection(ecol)
              .doc(widget.event.id)
              .collection(atcol)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var source = (snapshot.data as dynamic).docs;
          if (source.isEmpty) {
            return buildEmptyState(onPressed: () {});
          } else {
            List<Attendee> atList =
                source
                    .where((el) {
                      Attendee att = Attendee.fromMap(el.id, el.data());
                      bool hasInvitation =
                          att.cards[KardType.invitation.name] != null;
                      bool hasTargetType =
                          widget.isContactImport
                              ? att.cards[KardType.contact.name] != null
                              : att.cards[KardType.contribution.name] != null;
                      return (!hasInvitation && hasTargetType);
                    })
                    .map<Attendee>((e) {
                      return Attendee.fromMap(e.id, e.data());
                    })
                    .toList();
            return buildContrList(
              list: atList,
              kard: widget.kard,
              event: widget.event,
              kardType: KardType.invitation,
              isContactImport: widget.isContactImport,
              availableLabels: widget.availableLabels,
            );
          }
        } else if (snapshot.hasError) {
          return buildErrorView();
        } else {
          return Center(child: CircularProgressIndicator(color: primaryWhite));
        }
      },
    );
  }
}

Widget buildContrList({
  required List<Attendee> list,
  required Event event,
  required KardType kardType,
  required Kard kard,
  bool isContactImport = false,
  List<AttendeeLabel> availableLabels = const [],
}) {
  TextEditingController controller = TextEditingController();
  List<Attendee> selectList = [];
  List<String> selectedLabelIds = [];

  if (list.isEmpty) {
    return buildEmptyState();
  }
  return StatefulBuilder(
    builder: (context, setState) {
      if (controller.text.isNotEmpty && list.isNotEmpty) {
        list.sort((a, b) {
          var bm1 = StringSimilarity.compareTwoStrings(
            controller.text,
            a.fullName,
          );
          var bm2 = StringSimilarity.compareTwoStrings(
            controller.text,
            b.fullName,
          );
          return bm2.compareTo(bm1);
        });
      }
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: psm),
        children: [
          const SizedBox(height: psm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isContactImport
                  ? "Import from Contacts"
                  : "Import from Contributors",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("DES: ${kard.type}"),
            trailing: TextButton(
              onPressed: () {
                if (selectList.isEmpty) {
                  showToast(isGood: false, msg: "Nothing is selected");
                  return;
                }
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return ImpPreview(
                        event: event,
                        templateCardId: kard.id,
                        atList: selectList,
                        kardType: kardType,
                        labelIds: selectedLabelIds,
                      );
                    },
                  ),
                );
              },
              child: Text("Next Step"),
            ),
          ),
          // ── List (Label) Selection ──
          if (availableLabels.isNotEmpty) ...[
            const SizedBox(height: psm * 0.5),
            Text(
              "Assign to Lists",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: psm * 0.5),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableLabels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final label = availableLabels[i];
                  final isSelected = selectedLabelIds.contains(label.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedLabelIds.remove(label.id);
                        } else {
                          selectedLabelIds.add(label.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Color(label.colorValue).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Color(label.colorValue)
                                  : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        label.name,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected
                                  ? Color(label.colorValue)
                                  : Colors.white.withOpacity(0.6),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: psm * 0.5),
          ],
          buildField(
            cont: controller,
            lbl: "Search here",
            isChanged: () {
              setState(() {});
            },
          ),
          const SizedBox(height: psm),
          if (list.isEmpty) buildEmptyState(),
          if (list.isNotEmpty)
            ...List.generate(list.length, (index) {
              bool contains = selectList.any((e) {
                return e.id == list[index].id;
              });
              return cstmLqCheckTile(
                onChanged: (p0) {
                  if (!contains) {
                    selectList.add(list[index]);
                  } else {
                    selectList.remove(list[index]);
                  }
                  setState(() {});
                },
                str: "${list[index].fullName}",
                value: contains,
              );
            }),
        ],
      );
    },
  );
}

cstmLqCheckTile({
  required bool value,
  required void Function(bool?)? onChanged,
  required String str,
}) {
  return CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    checkColor: primaryWhite,
    checkboxScaleFactor: 0.8,
    activeColor: lqassgradBaseColor,
    checkboxShape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(50),
    ),
    value: value,
    onChanged: onChanged,
    title: Text("$str", style: TextStyle(fontWeight: FontWeight.w600)),
  );
}
