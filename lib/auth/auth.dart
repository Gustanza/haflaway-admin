import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/eventz/navhost.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../utils/globalwids.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController baruaPepeCon = TextEditingController();
  TextEditingController nenoSiriCon = TextEditingController();
  bool nalodi = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 32, right: 32),
        decoration: BoxDecoration(gradient: scagrad),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                gradient: secscagrad,
                border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
                borderRadius: BorderRadius.circular(bmd),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: baruaPepeCon,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      hintText: 'Email of the User',
                      hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nenoSiriCon,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      hintText: 'Password',
                      hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: kToolbarHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        nalodi
                            ? const Center(child: CircularProgressIndicator())
                            : TextButton(
                              onPressed: () async {
                                if (mcheckiFomu()) {
                                  try {
                                    setState(() {
                                      nalodi = true;
                                    });
                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                          email: baruaPepeCon.text.trim(),
                                          password: nenoSiriCon.text.trim(),
                                        );
                                    setState(() {
                                      nalodi = false;
                                    });
                                    goOn();
                                  } catch (shida) {
                                    setState(() {
                                      nalodi = false;
                                    });
                                    mjumbe(shida.toString());
                                  }
                                }
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const KuresetNenoSiri(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  mcheckiFomu() {
    if (baruaPepeCon.text.isEmpty) {
      mjumbe('Enter emai');
      return false;
    }
    if (nenoSiriCon.text.isEmpty) {
      mjumbe('Type-in password to proceed');
      return false;
    }
    return true;
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }

  goOn() {
    if (kIsWeb) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const NavHost()));
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavHost()),
        (route) => false,
      );
    }
  }
}

class Msajili extends StatefulWidget {
  final Userr? userr;
  const Msajili({super.key, this.userr});

  @override
  State<Msajili> createState() => _MsajiliState();
}

class _MsajiliState extends State<Msajili> {
  int? selClrnc;
  String phnnumber = '';
  Map<int, String> clrncDict = {
    2: "Cards Verification Staff (Level 02)",
    4: "Committee Staff (Level 04)",
    6: "Event Organizer (Level 06)",
  };
  GlobalKey<FormState> key = GlobalKey<FormState>();
  TextEditingController jinafestCon = TextEditingController();
  TextEditingController jinalastCon = TextEditingController();
  TextEditingController baruapepeCon = TextEditingController();
  TextEditingController nenoSiriCon = TextEditingController();
  TextEditingController clrncLvlCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  FirebaseAuth kisajilishi = FirebaseAuth.instance;
  String? yuarL;
  bool nalodi = false;

  popper() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    bindData();
    super.initState();
  }

  bindData() {
    Userr? userr = widget.userr;
    if (userr == null) return;
    jinafestCon.text = userr.firstName ?? "";
    jinalastCon.text = userr.lastName ?? "";
    selClrnc = userr.clearanceLevel ?? 2;
    clrncLvlCon.text = clrncDict[selClrnc] ?? "";
    phnnumber = userr.phoneNumber ?? "";
    phoneCon.text = phnnumber.replaceAll('255', '');
    safeState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: 'Register User',
        leading: appBarActionButton(
          onTap: () {
            popper();
          },
          icon: Icons.arrow_back,
        ),
        actions: Row(children: [
            
          ],
        ),
      ),
      body: Ccafold(
        child: Form(
          key: key,
          child: Container(
            padding: EdgeInsets.only(left: psm, right: psm),
            child: ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: psm),
                buildField(cont: jinafestCon, lbl: 'First name'),
                const SizedBox(height: spaceTiles),
                buildField(cont: jinalastCon, lbl: 'Last name'),
                if (widget.userr == null) // //
                  const SizedBox(height: spaceTiles),
                if (widget.userr == null) // //
                  buildField(cont: baruapepeCon, lbl: 'Email'),
                if (widget.userr == null) // //
                  const SizedBox(height: spaceTiles),
                if (widget.userr == null) // //
                  buildField(cont: nenoSiriCon, lbl: 'Password'),
                const SizedBox(height: spaceTiles),
                bldDrdDwn(
                  lbl: "Clearence Level",
                  controller: clrncLvlCon,
                  entries: clrncDict.entries,
                  onSelected: (val) {
                    selClrnc = val;
                  },
                ),
                const SizedBox(height: spaceTiles),
                buildPhone(mobileCont: phoneCon),
                const SizedBox(height: psm),
                buildPrimaryButton(
                  label: widget.userr == null ? "Register" : "Save Info",
                  isLoading: nalodi,
                  iconData: Icons.edit,
                  onTap: () async {
                    bool isValid = key.currentState?.validate() ?? false;
                    if (isValid && izVally()) {
                      try {
                        safeState(() {
                          nalodi = true;
                        });
                        if (widget.userr == null) {
                          await kisajilishi.createUserWithEmailAndPassword(
                            email: baruapepeCon.text.trim(),
                            password: nenoSiriCon.text.trim(),
                          );
                          await createDeits();
                        } else {
                          await saveEdits(userId: widget.userr?.id ?? "");
                        }
                        safeState(() {
                          nalodi = false;
                        });
                      } catch (shida) {
                        safeState(() {
                          nalodi = false;
                        });
                        mjumbe(shida.toString());
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  bool izVally() {
    if (selClrnc == null) {
      showToast(isGood: false, msg: "Select clearence level");
      return false;
    }
    if (phoneCon.text.isEmpty) {
      showToast(isGood: false, msg: "Phone number is required");
      return false;
    }
    return true;
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

  Future<void> createDeits() async {
    var obj = FirebaseAuth.instance;
    var userId = obj.currentUser?.uid;
    //process ya ku upload deits za yuza
    try {
      Userr userr = Userr(
        profileImage: "",
        isActive: true,
        firstName: jinafestCon.text.trim(),
        lastName: jinalastCon.text.trim(),
        phoneNumber: phnnumber,
        email: baruapepeCon.text.trim(),
        balance: 1000.0,
        clearanceLevel: selClrnc,
        registrationDate: DateTime.now().toIso8601String(),
        lastLoginDate: DateTime.now().toIso8601String(),
      );
      await FirebaseFirestore.instance
          .collection(ucol)
          .doc(userId)
          .set(userr.kwendaJson(), SetOptions(merge: true));
      showToast(isGood: true, msg: "User created successfully");
    } catch (shida) {
      showToast(isGood: false, msg: "$shida");
      debugPrint('shida ni: $shida');
    }
  }

  Future<void> saveEdits({userId}) async {
    try {
      Userr userr = Userr(
        firstName: jinafestCon.text.trim(),
        lastName: jinalastCon.text.trim(),
        phoneNumber: phnnumber,
        clearanceLevel: selClrnc,
      );
      await FirebaseFirestore.instance
          .collection(ucol)
          .doc(userId)
          .set(userr.kwendaJson(), SetOptions(merge: true));
      showToast(isGood: true, msg: "Data saved successfully");
    } catch (shida) {
      showToast(isGood: false, msg: "$shida");
      debugPrint('shida ni: $shida');
    }
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }
}

class KuresetNenoSiri extends StatefulWidget {
  const KuresetNenoSiri({super.key});

  @override
  State<KuresetNenoSiri> createState() => _KuresetNenoSiriState();
}

class _KuresetNenoSiriState extends State<KuresetNenoSiri> {
  TextEditingController baruaPepeCon = TextEditingController();
  bool nalodi = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Passwords & Security",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        padding: const EdgeInsets.only(left: p20, right: p20, top: p20),
        decoration: const BoxDecoration(gradient: scagrad),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: secscagrad,
              border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
              borderRadius: BorderRadius.circular(bmd),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Rotate password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baruaPepeCon,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    hintText: 'Email of the user',
                    hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: kToolbarHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      nalodi
                          ? const Center(child: CircularProgressIndicator())
                          : TextButton(
                            onPressed: () async {
                              if (baruaPepeCon.text.isNotEmpty) {
                                try {
                                  setState(() {
                                    nalodi = true;
                                  });
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(
                                        email: baruaPepeCon.text,
                                      );
                                  setState(() {
                                    nalodi = false;
                                  });
                                  mjumbe(
                                    'Password reset email sent succesfully',
                                  );
                                } catch (shida) {
                                  setState(() {
                                    nalodi = false;
                                  });
                                  mjumbe(shida.toString());
                                }
                              } else {
                                mjumbe('Email is required');
                              }
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }
}
