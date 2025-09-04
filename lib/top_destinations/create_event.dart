import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:icons_plus/icons_plus.dart';
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
  String phnnumber = '';
  String fEventCatId = '';
  String fEventCatLevel = '';
  List<EventCalendar> eventDays = [];
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DateFormat dformtr = DateFormat('EEEE, d\'th\', MMMM, yyyy');
  final DateFormat tformtr = DateFormat('HH:mm');
  TextEditingController fEventTitleCon = TextEditingController();
  TextEditingController fEventDescCon = TextEditingController();
  TextEditingController fEventCatCon = TextEditingController();
  TextEditingController fEventBillCon = TextEditingController();
  TextEditingController phncont = TextEditingController();
  TextEditingController fEventLocationCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    bindData();
  }

  bindData() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: 'Create Event',
        leading: buildActionButton(
          onTap: () {
            Navigator.of(context).pop();
          },
          icon: Icons.arrow_back,
        ),
        actions: Row(
          children: [
            buildActionButton(
              onTap: () {
                saver();
              },
              icon: Icons.save,
            ),
          ],
        ),
      ),
      body: Form(
        key: globalKey,
        child: Container(
          decoration: BoxDecoration(gradient: scagrad),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(psm),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Add thumbnail',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
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
                                  image: FileImage(File(picha!.path)),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          picha = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picha != null) {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Clarity.plus_circle_solid),
                      ),
                    ),
                    const SizedBox(height: psm),
                    const Text(
                      'Add event title',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
                    buildField(lbl: eptitle, cont: fEventTitleCon),
                    const SizedBox(height: psm),
                    const Text(
                      'Add event category',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
                    buildField(
                      isReadOnly: true,
                      showCursor: false,
                      cont: fEventCatCon,
                      lbl: epcategory,
                      isTapped: () {
                        showSelectCats();
                      },
                    ),
                    const SizedBox(height: psm),
                    const Text(
                      'Add event description',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
                    buildField(lbl: epdescription, cont: fEventDescCon),
                    const SizedBox(height: psm),
                    const Text(
                      'Add event location',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
                    buildField(lbl: eplocation, cont: fEventLocationCon),
                    const SizedBox(height: psm),
                    const Text(
                      'Select event plan',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
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
                    const SizedBox(height: psm * 0.70),
                    const Text(
                      'Phone number',
                      style: TextStyle(
                        fontSize: fsm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: psm * 0.3),
                    buildPhone(mobileCont: phncont),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 0, right: 0),
                      title: const Text(
                        'Add days of event',
                        style: TextStyle(
                          fontSize: fsm,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          EventCalendar? evd = await dtPicky(context: context);
                          if (evd != null) {
                            setState(() {
                              eventDays.add(evd);
                            });
                          }
                        },
                        icon: const Icon(Clarity.plus_circle_line),
                      ),
                    ),
                    eventDays.isNotEmpty
                        ? Column(
                          children: List.generate(eventDays.length, (idx) {
                            var edt = dformtr.format(eventDays[idx].eventDate);
                            var est = tformtr.format(eventDays[idx].startTime);
                            var eet = tformtr.format(eventDays[idx].endTime);
                            return ListTile(
                              title: Text(edt),
                              contentPadding: EdgeInsets.zero,
                              tileColor: lqassgradBaseColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: lqassgradBaseColor),
                                borderRadius: BorderRadiusGeometry.circular(
                                  bmd,
                                ),
                              ),
                              leading: const Icon(Clarity.clock_line),
                              subtitle: Text("$est - $eet"),
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    eventDays.removeAt(idx);
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                            );
                          }),
                        )
                        : const SizedBox(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
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
            phnnumber = phone.completeNumber;
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

  buildSheetBody() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(ecatcol).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<EventCategory> data =
              (snapshot.data as dynamic).docs.map<EventCategory>((doc) {
                return EventCategory.fromMap(doc.id, doc.data());
              }).toList();
          if (data.isEmpty) {
            return const Center(child: Text("Categories not available"));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(psm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: psm),
                Text(
                  "Select Category",
                  style: TextStyle(
                    fontSize: fsm + 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: psm * 1.5),
                Divider(color: lqassbdrColor, height: 0),
                SizedBox(height: psm),
                ...List.generate(data.length, (index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      setState(() {
                        fEventCatId = data[index].id;
                        fEventCatLevel = data[index].level;
                        fEventCatCon.text = data[index].name;
                      });
                      popper();
                    },
                    title: Text(
                      data[index].name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.add, color: primaryWhite),
                  );
                }),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  saver() async {
    bool currenformstate = globalKey.currentState?.validate() ?? false;
    if (tvalidator() && currenformstate) {
      showProgress(context: context);
      var imageId =
          "${FirebaseAuth.instance.currentUser?.uid}?=${DateTime.now().toString()}?=${picha!.name}";
      final storageRef = FirebaseStorage.instance.ref();
      final eventImagesRef = storageRef.child("Event-Thumbnails/$imageId");

      try {
        var p0 = await eventImagesRef.putFile(File(picha!.path));
        WriteBatch batch = firestore.batch();
        var evRef = firestore.collection(ecol).doc();
        var chkpnRef =
            firestore
                .collection(ecol)
                .doc(evRef.id)
                .collection(echecksub)
                .doc();
        var dwnURL = await p0.ref.getDownloadURL();
        Event event = Event(
          id: evRef.id,
          title: fEventTitleCon.text,
          authorId: uid!,
          adminsIds: [uid!],
          usersIds: [],
          status: 'Draft',
          supportPhone: phnnumber,
          categoryId: fEventCatId,
          categoryLevel: fEventCatLevel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          description: fEventDescCon.text,
          eventPlanId: plan!.id,
          eventThumbnail: dwnURL,
          location: fEventLocationCon.text,
          calendar: eventDays,
        );
        batch.set(evRef, event.toMap());
        CheckPoint checkPoint = CheckPoint(
          id: chkpnRef.id,
          name: echecknameVal,
        );
        batch.set(chkpnRef, checkPoint.toMap());
        batch.commit();
        popper();
        popper();
      } catch (e) {
        debugPrint("Comes 3st$e");
        popper();
        showToast(isGood: false, msg: gErrMsg);
      }
    }
  }

  popper() {
    dismissal(context: context);
  }

  tvalidator() {
    if (picha == null) {
      showToast(isGood: false, msg: "Thumbnail is required");
      return false;
    } else if (eventDays.isEmpty) {
      showToast(isGood: false, msg: "Calendar for event required");
      return false;
    } else {
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
}
