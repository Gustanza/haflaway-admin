import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'plans.dart';

class CreateEvent extends StatefulWidget {
  final Event? event;
  const CreateEvent({super.key, this.event});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  XFile? picha;
  EventPlan? plan;
  DateTime? evstdt;
  DateTime? evenddt;
  String phnnumber = '';
  bool isLoading = false;
  String fEventCatId = '';
  String fEventCatLevel = '';
  List<EventPlan> eventPlans = [];
  List<EventCategory> catsList = [];
  List<EventCalendar> eventDays = [];
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DateFormat dformtr = DateFormat('EEEE, d\'th\', MMMM, yyyy, HH:mm');
  final DateFormat tformtr = DateFormat('HH:mm');
  TextEditingController fEventTitleCon = TextEditingController();
  TextEditingController fEventDescCon = TextEditingController();
  TextEditingController fEventCatCon = TextEditingController();
  TextEditingController fEventBillCon = TextEditingController();
  TextEditingController phncont = TextEditingController();
  TextEditingController stdtcont = TextEditingController();
  TextEditingController enddtcont = TextEditingController();
  TextEditingController fEventLocationCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      bindData();
    }
    getCatsList();
  }

  bindData() async {
    Event? event = widget.event;
    if (event == null) return;
    phnnumber = event.supportPhone ?? "";
    fEventTitleCon.text = event.title ?? "";
    fEventDescCon.text = event.description ?? "";
    fEventLocationCon.text = event.location ?? "";
    phncont.text = event.supportPhone!.substring(3);
    evstdt = DateTime.parse(
      event.startDate ?? DateTime.now().toIso8601String(),
    );
    stdtcont.text = dformtr.format(evstdt!);
    evenddt = DateTime.parse(event.endDate ?? DateTime.now().toIso8601String());
    enddtcont.text = dformtr.format(evenddt!);
    eventDays = event.calendar!;
  }

  @override
  Widget build(BuildContext context) {
    Event? event = widget.event;
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: event == null ? 'Create Event' : 'Edit Event',
        leading: appBarActionButton(
          onTap: () {
            Navigator.of(context).pop();
          },
          icon: Icons.arrow_back,
        ),
        actions: Row(
          children: [
            appBarActionButton(
              onTap: () {
                saver();
              },
              icon: Icons.save,
            ),
          ],
        ),
      ),
      body:
          !isLoading
              ? Form(
                key: globalKey,
                child: Container(
                  decoration: BoxDecoration(gradient: scagrad),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: psm,
                          right: psm,
                          top: spaceTiles,
                          bottom: psm,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const Text(
                              'Add thumbnail',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            Stack(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: lqassgrad,
                                    border: Border.all(
                                      color: lqassbdrColor,
                                      width: bdrWidthGen,
                                    ),
                                    borderRadius: BorderRadius.circular(bmd),
                                    image:
                                        picha != null
                                            ? DecorationImage(
                                              image: FileImage(
                                                File(picha!.path),
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : event != null
                                            ? DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                event.eventThumbnail ?? "",
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  left: psm,
                                  bottom: psm,
                                  child: IconButton.outlined(
                                    onPressed: () async {
                                      picha = await ImagePicker().pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (picha != null) {
                                        safeState(() {});
                                      }
                                    },
                                    icon: const Icon(Icons.image),
                                  ),
                                ),
                                if (picha != null)
                                  Positioned(
                                    right: psm,
                                    bottom: psm,
                                    child: IconButton.outlined(
                                      onPressed: () {
                                        safeState(() {
                                          picha = null;
                                        });
                                      },
                                      icon: Icon(Icons.delete),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Add event title',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(lbl: eptitle, cont: fEventTitleCon),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Add event category',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(
                              isReadOnly: true,
                              showCursor: false,
                              cont: fEventCatCon,
                              lbl: epcategory,
                              isTapped: () {
                                showSelectCats();
                              },
                            ),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Add event description',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(lbl: epdescription, cont: fEventDescCon),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Add event location',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(
                              lbl: eplocation,
                              cont: fEventLocationCon,
                            ),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Select event plan',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(
                              isReadOnly: true,
                              showCursor: false,
                              cont: fEventBillCon,
                              lbl: epbilolan,
                              isTapped: () async {
                                plan = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BillScreen(),
                                  ),
                                );
                                if (plan != null) {
                                  setState(() {
                                    fEventBillCon.text = plan!.name;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'Phone number',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildPhone(mobileCont: phncont),
                            const Text(
                              'Start date & time',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(
                              isReadOnly: true,
                              showCursor: false,
                              cont: stdtcont,
                              lbl: "Event start date",
                              isTapped: () async {
                                try {
                                  evstdt = await dtPicker(context: context);
                                  if (evstdt != null) {
                                    setState(() {
                                      stdtcont.text = dformtr.format(evstdt!);
                                    });
                                  }
                                } catch (e) {
                                  showToast(isGood: false, msg: "$e");
                                }
                              },
                            ),
                            const SizedBox(height: spaceTiles),
                            const Text(
                              'End date & time',
                              style: TextStyle(
                                fontSize: fsm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: spaceTiles),
                            buildField(
                              isReadOnly: true,
                              showCursor: false,
                              cont: enddtcont,
                              lbl: "Event end date",
                              isTapped: () async {
                                try {
                                  evenddt = await dtPicker(context: context);
                                  if (evenddt != null) {
                                    setState(() {
                                      enddtcont.text = dformtr.format(evenddt!);
                                    });
                                  }
                                } catch (e) {
                                  showToast(isGood: false, msg: "$e");
                                }
                              },
                            ),
                            // ListTile(
                            //   contentPadding: const EdgeInsets.only(left: 0, right: 0),
                            //   title: const Text(
                            //     'Add days of event',
                            //     style: TextStyle(
                            //       fontSize: fsm,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            //   trailing: IconButton(
                            //     onPressed: () async {
                            //       EventCalendar? evd = await dtPicky(context: context);
                            //       if (evd != null) {
                            //         setState(() {
                            //           eventDays.add(evd);
                            //         });
                            //       }
                            //     },
                            //     icon: const Icon(Clarity.plus_circle_line),
                            //   ),
                            // ),
                            // if (eventDays.isNotEmpty)
                            //   Column(
                            //     children: List.generate(eventDays.length, (idx) {
                            //       var edt = dformtr.format(eventDays[idx].eventDate);
                            //       var est = tformtr.format(eventDays[idx].startTime);
                            //       var eet = tformtr.format(eventDays[idx].endTime);
                            //       return Container(
                            //         padding: EdgeInsets.only(left: psm, right: psm),
                            //         decoration: BoxDecoration(
                            //           gradient: secscagrad,
                            //           border: Border.all(
                            //             color: lqassbdrColor,
                            //             width: bdrWidthGen,
                            //           ),
                            //           borderRadius: BorderRadius.circular(bsm),
                            //         ),
                            //         child: ListTile(
                            //           title: Text(edt),
                            //           contentPadding: EdgeInsets.zero,
                            //           tileColor: lqassgradBaseColor,
                            //           shape: RoundedRectangleBorder(
                            //             side: BorderSide(color: lqassgradBaseColor),
                            //             borderRadius: BorderRadiusGeometry.circular(
                            //               bmd,
                            //             ),
                            //           ),
                            //           subtitle: Text("$est - $eet"),
                            //           trailing: IconButton(
                            //             onPressed: () {
                            //               setState(() {
                            //                 eventDays.removeAt(idx);
                            //               });
                            //             },
                            //             icon: const Icon(Icons.close),
                            //           ),
                            //         ),
                            //       );
                            //     }),
                            //   ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : buildLoader(),
    );
  }

  buildPhone({mobileCont}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntlPhoneField(
          controller: mobileCont,
          decoration: InputDecoration(
            hintText: 'Phone Number',
            filled: true,
            fillColor: lqassgradBaseColor,
            border: inputBorder,
            focusedBorder: inputBorder,
            enabledBorder: inputBorder,
            disabledBorder: inputBorder,
          ),
          initialCountryCode: 'TZ',
          onChanged: (phone) {
            phnnumber = phone.completeNumber.replaceAll('+', '');
          },
        ),
      ],
    );
  }

  showSelectCats() {
    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(bmd),
          topRight: Radius.circular(bmd),
        ),
      ),
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: modalBtmSheet(bdrdm: bmd, child: buildSheetBody()),
        );
      },
    );
  }

  getCatsList() async {
    safeState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> catSnaps =
          await firestore.collection(ecatcol).get();

      if (catSnaps.docs.isEmpty) {
        showToast(isGood: false, msg: "Failed to get categories");
      }

      catsList =
          catSnaps.docs.map<EventCategory>((doc) {
            return EventCategory.fromMap(doc.id, doc.data());
          }).toList();
      if (widget.event != null) {
        EventCategory? catItself = catsList.firstWhere((tst) {
          return tst.id == widget.event?.categoryId;
        });
        fEventCatId = catItself.id;
        fEventCatLevel = catItself.level;
        fEventCatCon.text = catItself.name;
      }
      // doing plans here
      QuerySnapshot<Map<String, dynamic>> planSnaps =
          await firestore
              .collection(eplancol)
              .orderBy('rank', descending: false)
              .get();
      if (planSnaps.docs.isEmpty) {
        showToast(isGood: false, msg: "Failed to map plan");
      }
      eventPlans =
          planSnaps.docs.map<EventPlan>((e) {
            return EventPlan.fromMap(e.id, e.data());
          }).toList();
      if (widget.event != null) {
        plan = eventPlans.firstWhere((tst) {
          return tst.id == widget.event?.eventPlanId;
        });
        fEventBillCon.text = plan!.name;
      }
    } catch (e) {
      return showToast(isGood: false, msg: "Failed to get data");
    }
    safeState(() {
      isLoading = false;
    });
  }

  buildSheetBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(psm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: psm),
          Text(
            "Select Category",
            style: TextStyle(fontSize: fsm + 6, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: psm * 1.5),
          Divider(color: lqassbdrColor, height: 0),
          SizedBox(height: psm),
          ...List.generate(catsList.length, (index) {
            bool isSelected = fEventCatId == catsList[index].id;
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              checkboxScaleFactor: .75,
              checkboxShape: CircleBorder(),
              selected: isSelected,
              activeColor: primaryColor,
              value: isSelected,
              onChanged: (_) {
                setState(() {
                  fEventCatId = catsList[index].id;
                  fEventCatLevel = catsList[index].level;
                  fEventCatCon.text = catsList[index].name;
                });
                popper();
              },
              title: Text(
                catsList[index].name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }

  saver() async {
    Event? eventt = widget.event;
    bool currenformstate = globalKey.currentState?.validate() ?? false;
    if (tvalidator() && currenformstate) {
      showProgress(context: context);

      try {
        String dwnURL = defThumb;

        if (picha != null) {
          var imageId =
              "${FirebaseAuth.instance.currentUser?.uid}?=${DateTime.now().toString()}?=${picha!.name}";
          final storageRef = FirebaseStorage.instance.ref();
          final eventImagesRef = storageRef.child("Event-Thumbnails/$imageId");
          var p0 = await eventImagesRef.putFile(File(picha!.path));
          dwnURL = await p0.ref.getDownloadURL();
        } else if (eventt != null) {
          dwnURL = eventt.eventThumbnail ?? defThumb;
        }

        WriteBatch batch = firestore.batch();

        var evRef =
            eventt == null
                ? firestore.collection(ecol).doc()
                : firestore.collection(ecol).doc(widget.event?.id);

        if (eventt == null) {
          var chkpnRef =
              firestore
                  .collection(ecol)
                  .doc(evRef.id)
                  .collection(echecksub)
                  .doc();
          CheckPoint checkPoint = CheckPoint(
            id: chkpnRef.id,
            name: echecknameVal,
          );
          batch.set(chkpnRef, checkPoint.toMap());
        }

        String estatus = eventt == null ? 'Draft' : 'Published';

        Event event = Event(
          id: evRef.id,
          title: fEventTitleCon.text.trim(),
          authorId: eventt == null ? uid! : null,
          adminsIds: eventt == null ? [uid!] : null,
          usersIds: eventt == null ? [] : null,
          status: estatus,
          supportPhone: phnnumber,
          categoryId: fEventCatId,
          categoryLevel: fEventCatLevel,
          createdAt: eventt == null ? DateTime.now() : null,
          updatedAt: DateTime.now(),
          description: fEventDescCon.text.trim(),
          eventPlanId: plan?.id ?? null,
          eventThumbnail: dwnURL,
          // calendar: eventDays,
          location: fEventLocationCon.text.trim(),
          startDate: evstdt?.toIso8601String(),
          endDate: evenddt?.toIso8601String(),
        );
        batch.set(evRef, event.toMap(), SetOptions(merge: true));
        batch.commit();
        popper();
        popper();
      } catch (e) {
        popper();
        debugPrint("shida_ni: $e");
        showToast(isGood: false, msg: gErrMsg);
      }
    }
  }

  popper() {
    dismissal(context: context);
  }

  tvalidator() {
    if (picha == null && widget.event == null) {
      showToast(isGood: false, msg: "Thumbnail is required");
      return false;
    }
    // else if (eventDays.isEmpty) {
    //   showToast(isGood: false, msg: "Calendar for event required");
    //   return false;
    // }
    else {
      return true;
    }
  }

  fvalidator({label, value}) {
    switch (label) {
      case eptitle:
        if (value.isEmpty) {
          return "$eptitle is required";
        } else {
          return null;
        }
      case epcategory:
        if (value.isEmpty) {
          return "$epcategory is required";
        } else {
          return null;
        }

      case epdescription:
        if (value.isEmpty) {
          return "$epdescription is required";
        } else {
          return null;
        }
      case eplocation:
        if (value.isEmpty) {
          return "$eplocation is required";
        } else {
          return null;
        }
      case epbilolan:
        if (value.isEmpty) {
          return "$epbilolan is required";
        } else {
          return null;
        }

      default:
        return null;
    }
  }

  safeState(Function() runnbale) {
    if (mounted) {
      setState(() {
        runnbale();
      });
    }
  }
}
