import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/hfhttp/clientelle.dart';
import 'package:haflaway/utils/attstates.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/urls.dart';

class CreateAttendees extends StatefulWidget {
  final Event event;
  final KardType kardType;
  final Attendee? attendee;
  final String title;
  const CreateAttendees({
    super.key,
    this.attendee,
    required this.event,
    this.title = "Invitation",
    required this.kardType,
  });

  @override
  State<CreateAttendees> createState() => _CreateAttendeesState();
}

class _CreateAttendeesState extends State<CreateAttendees> {
  List chk = [];
  List? dataList;
  bool isLoading = false;
  bool hasError = false;
  bool isPhoneValid = false;
  late String phnnumber;
  bool isWritting = false;
  String templateCardId = "_";
  Map<String, String> scrdsMp = {};
  late List<Map<String, dynamic>> chekstatuses;
  List<String> chkLabels = []; // Added for label selection
  TextEditingController ncont = TextEditingController();
  TextEditingController phncont = TextEditingController();
  TextEditingController crdCont = TextEditingController();
  GlobalKey<FormState> fkey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  fetch() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      var source =
          await firestore
              .collection(ecol)
              .doc(widget.event.id)
              .collection(cardcol)
              .where("purpose", isEqualTo: widget.kardType.name)
              .get();
      dataList = source.docs;
      scrdsMp = Map.fromIterable(
        dataList as Iterable,
        key: (e) => e.id ?? "",
        value: (e) => e['type'] ?? "unknown",
      );
      Attendee? attendee = widget.attendee;
      if (attendee != null) {
        ncont.text = attendee.fullName;
        phnnumber = attendee.phone;
        phncont.text = attendee.phone.replaceFirst(RegExp(r'^255'), '');
        for (var atcard in attendee.cards.entries) {
          if (atcard.key == widget.kardType.name) {
            AttributeCard attrCrd = AttributeCard.fromMap(map: atcard.value);
            for (var dItem in dataList ?? []) {
              var dItemMap = dItem.data();
              CardConfig crdConfig = CardConfig.fromMap(dItem.id, dItemMap);
              if (crdConfig.type == attrCrd.name) {
                crdCont.text = crdConfig.type;
                templateCardId = dItem.id; // PRE-LOAD: Sync the card ID
                break;
              }
            }
            break;
          }
        }
        chkLabels = List<String>.from(attendee.labelIds ?? []);
      }
      safeState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _T.bg,
          body: Center(child: buildLoader()),
        ),
      );
    }
    if (hasError) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _T.bg,
          body: Center(child: buildErr()),
        ),
      );
    }
    final attendee = widget.attendee;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBarUI(),
                  _titleBlock(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Form(
                        key: fkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerSection(
                              icon: Icons.person_outline_rounded,
                              title: "Attendee Details",
                              subtitle: "Basic identification info",
                            ),
                            const SizedBox(height: 20),
                            _buildPremiumField(
                              controller: ncont,
                              label: "Full Name",
                              hint: "e.g. JOHN DOE",
                              validator:
                                  (v) => validator(lbl: "Name", value: v),
                            ),
                            const SizedBox(height: 20),
                            _buildPremiumField(
                              controller: phncont,
                              label: "Phone Number",
                              hint: "Phone Number",
                              isPhone: true,
                              onPhoneChanged: (phone) {
                                phnnumber = phone.completeNumber;
                              },
                            ),
                            const SizedBox(height: 32),

                            if (widget.kardType != KardType.contact) ...[
                              _headerSection(
                                icon: Icons.card_membership_rounded,
                                title: "Assignment",
                                subtitle: "Choose a card template",
                              ),
                              const SizedBox(height: 20),
                              _inputLabel("CHOOSE CARD TEMPLATE"),
                              const SizedBox(height: 12),
                              DropdownMenu<String>(
                                initialSelection:
                                    templateCardId != "_"
                                        ? templateCardId
                                        : null,
                                width: MediaQuery.of(context).size.width - 40,
                                textStyle: _T.f(size: 15, color: _T.white),
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: _T.bg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _T.sep),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _T.sep),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSelected: (val) {
                                  if (val != null) {
                                    safeState(() => templateCardId = val);
                                  }
                                },
                                dropdownMenuEntries:
                                    scrdsMp.entries.map((entry) {
                                      return DropdownMenuEntry<String>(
                                        value: entry.key,
                                        label: entry.value,
                                        style: MenuItemButton.styleFrom(
                                          foregroundColor: _T.white,
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 32),
                            ],

                            if (widget.event.labels != null &&
                                widget.event.labels!.isNotEmpty) ...[
                              _headerSection(
                                icon: Icons.label_outline_rounded,
                                title: "Lists",
                                subtitle: "Assign to guest lists",
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    widget.event.labels!.map((label) {
                                      final isSelected = chkLabels.contains(
                                        label.id,
                                      );
                                      final color = Color(label.colorValue);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              chkLabels.remove(label.id);
                                            } else {
                                              chkLabels.add(label.id);
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? color.withValues(
                                                      alpha: 0.15,
                                                    )
                                                    : _T.card,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? color
                                                      : _T.sep,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            label.name,
                                            style: _T.f(
                                              size: 13,
                                              color:
                                                  isSelected ? color : _T.lbl2,
                                              weight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 32),
                            ],

                            const SizedBox(height: 20),
                            buildPrimaryButton(
                              onTap: () {
                                if (!isWritting) {
                                  attendee == null
                                      ? submitForm()
                                      : submitForm(attendeeId: attendee.id);
                                }
                              },
                              isLoading: isWritting,
                              iconData:
                                  attendee == null
                                      ? Icons.add_rounded
                                      : Icons.save_as_rounded,
                              label:
                                  attendee == null
                                      ? "Create Attendee"
                                      : "Update Details",
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _topBarUI() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.sep, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
                  const SizedBox(width: 4),
                  Text('Back', style: _T.f(size: 14, weight: FontWeight.w500, color: _T.lbl1)),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (widget.attendee != null)
            GestureDetector(
              onTap: _confirmDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('Delete', style: _T.f(size: 14, weight: FontWeight.w500, color: Colors.redAccent)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        widget.attendee == null
            ? "New ${widget.title}"
            : "Edit ${widget.title}",
        style: _T.f(size: 28, weight: FontWeight.w800, color: _T.lbl1, letterSpacing: -0.8),
      ),
    );
  }

  Widget _headerSection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _T.lime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: _T.f(size: 11, weight: FontWeight.w700, color: _T.lbl3, letterSpacing: 1.3),
        ),
      ],
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
    bool isPhone = false,
    void Function(PhoneNumber)? onPhoneChanged,
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
        isPhone
            ? IntlPhoneField(
              controller: controller,
              style: _T.f(size: 15, color: _T.white),
              dropdownTextStyle: _T.f(size: 15, color: _T.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: _T.f(size: 15, color: _T.lbl4),
                filled: true,
                fillColor: _T.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _T.sep),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _T.sep),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _T.lime, width: 1.5),
                ),
                counterText: '',
              ),
              initialCountryCode: 'TZ',
              onChanged: onPhoneChanged,
            )
            : TextFormField(
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
                  borderSide: const BorderSide(color: _T.sep),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _T.sep),
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

  submitForm({attendeeId}) async {
    var isValid = fkey.currentState?.validate() ?? false;
    if (isValid && validatePhone()) {
      String finalTemplateId =
          widget.kardType == KardType.contact ? "contact" : templateCardId;

      if (widget.kardType != KardType.contact && finalTemplateId == "_") {
        showToast(isGood: false, msg: "Select Card Type");
        return;
      }

      safeState(() {
        isWritting = true;
      });
      HttpService client = HttpService();

      try {
        var atId = attendeeId ?? generateUniqueSequence();
        Attendee atdt = Attendee(
          id: atId,
          cards: {},
          email: '',
          messages: {},
          checkinStatus: chk,
          createdAt: DateTime.now(),
          attendanceStatus: atnotconfstate,
          phone: phnnumber.replaceAll('+', ''),
          fullName: ncont.text.trim().toUpperCase(),
          fullNameLower: ncont.text.trim().toLowerCase(),
          labelIds: chkLabels,
        );
        var payload = {
          "eventId": widget.event.id,
          "attendees": [atdt.toMap()],
          "templateCardId": finalTemplateId,
          "usepng": widget.event.usepng,
          "kardType": widget.kardType.name,
        };
        var source = await client.post(
          Uri.parse(crtAtCloudUrl),
          body: jsonEncode(payload),
        );
        var body = jsonDecode(source.body);
        if (body == null || !body['status']) {
          var message = body != null ? body['message'] : "Failed";
          showToast(isGood: false, msg: "$message");
          showOutput(msg: "$message");
          return safeState(() {
            isWritting = false;
          });
        }
        showToast(isGood: true, msg: "Success");
        showOutput(msg: "Success");
        return safeState(() {
          isWritting = false;
        });
      } catch (e) {
        safeState(() {
          isWritting = false;
        });
        showOutput(msg: "Action Failed");
        showToast(isGood: true, msg: "Failed because: $e");
      }
      client.close();
    }
  }

  validatePhone() {
    if (phncont.text.isEmpty) {
      showToast(isGood: false, msg: "Phone number is required");
      return false;
    }
    return true;
  }

  // dataCleaner({passcode}) {
  //   chk = [];
  //   String type = data?.type ?? "unknown";
  //   int cap = data?.capacity ?? 1;
  //   List clearAt = data?.clearAt ?? [];
  //   for (var i = 0; i < cap; i++) {
  //     var atentry = {
  //       cattendeename: "Slot: ${i + 1}",
  //       crdChkpns: {for (var chkpnId in clearAt) chkpnId: false},
  //     };
  //     chk.add(atentry);
  //   }
  //   data?.elements[crdattname][lmntvalue] = ncont.text;
  //   data?.elements[crdtype][lmntvalue] = type;
  //   data?.elements[crdQrCode][lmntvalue] = passcode;
  // }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => glassDialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Delete Attendee?",
                    style: _T.f(size: 18, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: _T.f(size: 14, color: _T.lbl2),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: lqAssButton(
                          label: "Cancel",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog
                            await _deleteAttendee();
                          },
                          color: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            "Delete",
                            style: _T.f(weight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteAttendee() async {
    setState(() => isWritting = true);
    try {
      await FirebaseFirestore.instance
          .collection(ecol)
          .doc(widget.event.id)
          .collection(atcol)
          .doc(widget.attendee!.id)
          .delete();
      if (mounted) Navigator.pop(context, "deleted"); // Return to list
      showToast(isGood: true, msg: "Attendee Deleted");
    } catch (e) {
      showToast(isGood: false, msg: "Delete failed: $e");
    } finally {
      safeState(() => isWritting = false);
    }
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  showOutput({msg}) {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: psm * 2,
              horizontal: psm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$msg",
                  style: _T.f(size: 16, weight: FontWeight.bold, color: _T.lbl1),
                ),
                const SizedBox(height: psm * 0.75),
                lqAssButton(
                  label: "Stay here",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: psm * 0.75),
                lqAssButton(
                  label: "Leave page",
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  poper() {
    dismissal(context: context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg      = Color(0xFF111114);
  static const card    = Color(0xFF1C1C1E);
  static const card2   = Color(0xFF28282C);
  static const card3   = Color(0xFF3A3A3C);
  static const sep     = Color(0xFF2C2C2E);
  static const lime    = Color(0xFFC9A84C);
  static const limeDim = Color(0xFF2A2210);
  static const lbl1    = Color(0xFFFFFFFF);
  static const lbl2    = Color(0xFFAEAEB2);
  static const lbl3    = Color(0xFF636366);
  static const lbl4    = Color(0xFF48484A);
  static const white   = Color(0xFFFFFFFF);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
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
