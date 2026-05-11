import 'dart:typed_data';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/urls.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/services/plan_service.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class CreateEvent extends StatefulWidget {
  final Event? event;
  const CreateEvent({super.key, this.event});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  XFile? picha;
  Uint8List? pichaBytes;
  EventPlan? plan;
  String? eventPlanId;
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
    eventPlanId = event.eventPlanId;
    stdtcont.text = dformtr.format(evstdt!);
    evenddt = DateTime.parse(event.endDate ?? DateTime.now().toIso8601String());
    enddtcont.text = dformtr.format(evenddt!);
    eventDays = event.calendar!;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              right: -100,
              child: _GusOrb(size: 300, color: _T.lime, opacity: 0.08),
            ),
            const Positioned(
              bottom: -50,
              left: -100,
              child: _GusOrb(size: 250, color: _T.lime, opacity: 0.05),
            ),

            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child:
                        !isLoading
                            ? Form(
                              key: globalKey,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate([
                                        _titleBlock(),
                                        const SizedBox(height: 8),
                                        _sectionThumbnail(),
                                        const SizedBox(height: 24),
                                        _sectionBasicInfo(),
                                        const SizedBox(height: 24),
                                        _sectionDateTime(),
                                        const SizedBox(height: 24),
                                        _sectionAdditionalInfo(),
                                        const SizedBox(
                                          height: 40,
                                        ), // Bottom padding
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Center(
                              child: CupertinoActivityIndicator(color: _T.lime),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title Block ─────────────────────────────────────────────────────────
  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event == null ? 'Create Event' : 'Edit Event',
            style: _T.f(
              size: 28,
              weight: FontWeight.w800,
              color: _T.white,
              letterSpacing: -0.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.event == null
                ? 'Fill in the details below to get started.'
                : 'Update your event details below.',
            style: _T.f(size: 13, color: _T.lbl3, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Section: Thumbnail ──────────────────────────────────────────────────
  Widget _sectionThumbnail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel('EVENT THUMBNAIL'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            picha = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (picha != null) {
              pichaBytes = await picha!.readAsBytes();
              safeState(() {});
            }
          },
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.sep),
              image:
                  pichaBytes != null
                      ? DecorationImage(
                        image: MemoryImage(pichaBytes!),
                        fit: BoxFit.cover,
                      )
                      : widget.event != null
                      ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          widget.event!.eventThumbnail ?? defThumb,
                        ),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                pichaBytes == null && widget.event?.eventThumbnail == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _T.lime,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Thumbnail',
                          style: _T.f(size: 13, color: _T.lbl2),
                        ),
                      ],
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  // ── Section: Basic Info ──────────────────────────────────────────────────
  Widget _sectionBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('BASIC INFORMATION'),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: fEventTitleCon,
            label: 'Event Title',
            hint: 'e.g. Gatsby Night',
            validator: (v) => fvalidator(label: eptitle, value: v),
          ),
          const SizedBox(height: 20),
          _buildPremiumField(
            controller: fEventCatCon,
            label: 'Category',
            hint: 'Select category',
            readOnly: true,
            onTap: showSelectCats,
            suffix: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _T.lime,
            ),
          ),
          const SizedBox(height: 20),
          _buildPremiumField(
            controller: fEventDescCon,
            label: 'Description',
            hint: 'Tell us more about the event...',
            maxLines: 4,
            validator: (v) => fvalidator(label: epdescription, value: v),
          ),
        ],
      ),
    );
  }

  // ── Section: Date & Time ──────────────────────────────────────────────────
  Widget _sectionDateTime() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('DATE & TIME'),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: stdtcont,
            label: 'Start Date',
            hint: 'Select start date',
            readOnly: true,
            onTap: () async {
              evstdt = await dtPicker(context: context);
              if (evstdt != null) {
                safeState(() {
                  stdtcont.text = dformtr.format(evstdt!);
                });
              }
            },
            suffix: const Icon(
              Icons.calendar_today_rounded,
              color: _T.lime,
              size: 18,
            ),
          ),
          const SizedBox(height: 20),
          _buildPremiumField(
            controller: enddtcont,
            label: 'End Date',
            hint: 'Select end date',
            readOnly: true,
            onTap: () async {
              evenddt = await dtPicker(context: context);
              if (evenddt != null) {
                safeState(() {
                  enddtcont.text = dformtr.format(evenddt!);
                });
              }
            },
            suffix: const Icon(
              Icons.calendar_today_rounded,
              color: _T.lime,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Additional Info ──────────────────────────────────────────────
  Widget _sectionAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel('ADDITIONAL DETAILS'),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: fEventLocationCon,
            label: 'Location',
            hint: 'e.g. Mlimani City Hall',
            validator: (v) => fvalidator(label: eplocation, value: v),
          ),
          const SizedBox(height: 20),
          _inputLabel('SUPPORT NUMBER'),
          const SizedBox(height: 12),
          buildPhone(mobileCont: phncont),
          const SizedBox(height: 20),
          _inputLabel('EVENT PLAN'),
          const SizedBox(height: 12),
          DropdownMenu(
            initialSelection: eventPlanId,
            width: MediaQuery.of(context).size.width - 64,
            textStyle: _T.f(color: _T.white),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _T.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _T.sep),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _T.sep),
              ),
            ),
            onSelected: (value) {
              safeState(() {
                eventPlanId = value ?? "";
              });
            },
            dropdownMenuEntries: List.generate(eventPlans.length, (idx) {
              EventPlan evPln = eventPlans[idx];
              return DropdownMenuEntry(
                leadingIcon: const Icon(
                  Icons.star_outline_rounded,
                  color: _T.lime,
                ),
                value: evPln.id,
                label: "${evPln.name}",
                style: MenuItemButton.styleFrom(foregroundColor: _T.white),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Premium UI Helpers ────────────────────────────────────────────────────

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: _T.f(
        size: 10,
        weight: FontWeight.w700,
        color: _T.lbl3,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl2),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          validator: validator,
          textCapitalization: TextCapitalization.sentences,
          style: _T.f(size: 15, color: _T.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _T.f(size: 15, color: _T.lbl4),
            filled: true,
            fillColor: _T.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _T.sep),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _T.sep),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _T.lime, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  buildPhone({mobileCont}) {
    return IntlPhoneField(
      controller: mobileCont,
      style: _T.f(size: 15, color: _T.white),
      dropdownTextStyle: _T.f(size: 15, color: _T.white),
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: _T.f(size: 15, color: _T.lbl4),
        filled: true,
        fillColor: _T.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _T.sep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _T.sep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _T.lime, width: 1.5),
        ),
      ),
      initialCountryCode: 'TZ',
      onChanged: (phone) {
        phnnumber = phone.completeNumber.replaceAll('+', '');
      },
    );
  }

  showSelectCats() {
    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return modalBtmSheet(bdrdm: 32, child: buildSheetBody());
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

  IconData _getCatIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('wedding')) return Icons.favorite_rounded;
    if (name.contains('birthday')) return Icons.cake_rounded;
    if (name.contains('corporate') || name.contains('meeting'))
      return Icons.work_rounded;
    if (name.contains('party') || name.contains('celebration'))
      return Icons.celebration_rounded;
    if (name.contains('concert') || name.contains('music'))
      return Icons.music_note_rounded;
    if (name.contains('sports')) return Icons.sports_basketball_rounded;
    if (name.contains('dinner')) return Icons.restaurant_rounded;
    return Icons.star_rounded;
  }

  buildSheetBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Grabber
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: _T.lbl3.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Choose Category",
                style: _T.f(size: 18, weight: FontWeight.w800, color: _T.white),
              ),
              IconButton(
                onPressed: popper,
                icon: Icon(Icons.close_rounded, color: _T.lbl2, size: 24),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: _T.lbl3.withValues(alpha: 0.3), height: 1),
        ),
        const SizedBox(height: 16),

        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: catsList.length,
            itemBuilder: (context, index) {
              final cat = catsList[index];
              final isSelected = fEventCatId == cat.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    safeState(() {
                      fEventCatId = cat.id;
                      fEventCatLevel = cat.level;
                      fEventCatCon.text = cat.name;
                    });
                    popper();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? _T.lime.withValues(alpha: 0.15)
                              : _T.card2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? _T.lime : _T.sep,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: _T.lime.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                ),
                              ]
                              : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? _T.lime.withValues(alpha: 0.12)
                                    : _T.card3,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCatIcon(cat.name),
                            color: isSelected ? _T.lime : _T.lbl2,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: _T.f(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: isSelected ? _T.lime : _T.lbl1,
                                ),
                              ),
                              if (isSelected)
                                Text(
                                  "Selected",
                                  style: _T.f(
                                    size: 12,
                                    color: _T.lbl3,
                                    height: 1.35,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _T.lbl4,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _T.lime,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Back',
                    style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => saver(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _T.limeDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _T.lime.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.event == null ? 'Create' : 'Save',
                style: _T.f(size: 13, weight: FontWeight.w700, color: _T.lime),
              ),
            ),
          ),
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
          var p0 = await eventImagesRef.putData(pichaBytes!);
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
          titleLower: fEventTitleCon.text.trim().toLowerCase(),
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
          eventPlanId: eventPlanId ?? null,
          eventThumbnail: dwnURL,
          // calendar: eventDays,
          location: fEventLocationCon.text.trim(),
          startDate: evstdt?.toIso8601String(),
          endDate: evenddt?.toIso8601String(),
          locations: eventt?.locations,
          usepng: eventt == null ? true : eventt.usepng,
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

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens  ·  Apple-dark, not pitch-black
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg    = Color(0xFF111114);
  static const card  = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const card3 = Color(0xFF3A3A3C);
  static const sep   = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
  static const lbl2  = Color(0xFFAEAEB2);
  static const lbl3  = Color(0xFF8E8E93);
  static const lbl4  = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = lbl1,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class _GusOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GusOrb({required this.size, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
