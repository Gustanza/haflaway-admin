import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/navhost.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/strings.dart';

import 'utils.dart';

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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(coverpic),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(bsm),
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
                              builder: (context) => const Msajili(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const NavHost()),
      (route) => false,
    );
  }
}

class Msajili extends StatefulWidget {
  const Msajili({super.key});

  @override
  State<Msajili> createState() => _MsajiliState();
}

class _MsajiliState extends State<Msajili> {
  dynamic programe;
  TextEditingController jinafestCon = TextEditingController();
  TextEditingController jinalastCon = TextEditingController();
  TextEditingController baruapepeCon = TextEditingController();
  TextEditingController nenoSiriCon = TextEditingController();
  TextEditingController nenoSiriConCon = TextEditingController();
  TextEditingController couponCodeCon = TextEditingController();
  FirebaseAuth kisajilishi = FirebaseAuth.instance;
  String? yuarL;
  bool nalodi = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 32, right: 32),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(coverpic),
            fit: BoxFit.cover,
          ),
        ),
        //safe-area hapa ili ku allow container beyond statusbar
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.only(
                left: psm,
                top: psm,
                right: psm,
                bottom: psm * 2,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(bsm),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  fomu(jinafestCon, 'First name'),
                  const SizedBox(height: psm * 0.5),
                  fomu(jinalastCon, 'Last name'),
                  const SizedBox(height: psm * 0.5),
                  fomu(baruapepeCon, 'Email'),
                  const SizedBox(height: psm * 0.5),
                  fomu(nenoSiriCon, 'Password'),
                  const SizedBox(height: psm * 0.5),
                  fomu(nenoSiriConCon, 'Confirm password'),
                  const SizedBox(height: psm * 0.5),
                  fomu(couponCodeCon, 'Coupon Code (optional)'),
                  const SizedBox(height: psm * 1.5),
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
                                    await kisajilishi
                                        .createUserWithEmailAndPassword(
                                          email: baruapepeCon.text.trim(),
                                          password: nenoSiriCon.text.trim(),
                                        );
                                    await mratibuDeits();
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
                                'register',
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
      ),
    );
  }

  fomu(TextEditingController con, String hint) {
    return TextField(
      controller: con,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  mcheckiFomu() {
    if (jinafestCon.text.isEmpty) {
      mjumbe('Jina la kwanza linahitajika');
      return false;
    }
    if (jinalastCon.text.isEmpty) {
      mjumbe('Jina la mwisho linahitajika');
      return false;
    }
    if (baruapepeCon.text.isEmpty) {
      mjumbe('Barua Pepe inahitajika');
      return false;
    }

    if (nenoSiriCon.text.isEmpty) {
      mjumbe('Andika neno siri');
      return false;
    }
    if (nenoSiriConCon.text.isEmpty) {
      mjumbe('Hakiki neno siri');
      return false;
    }
    if (nenoSiriCon.text != nenoSiriConCon.text) {
      mjumbe('Neno siri haliendani, Hakiki upya ili kuendelea');
      return false;
    }
    return true;
  }

  Future<void> mratibuDeits() async {
    var obj = FirebaseAuth.instance;
    await kisajilishi.currentUser?.updateDisplayName(
      '${jinafestCon.text} ${jinalastCon.text}',
    );
    await kisajilishi.currentUser?.updatePhotoURL(defImg);
    //mwisho hapa
    var picha = obj.currentUser?.photoURL;
    var userId = obj.currentUser?.uid;
    //process ya ku upload deits za yuza
    try {
      Userr userr = Userr(
        id: '',
        profileImage: picha ?? "",
        firstName: jinafestCon.text,
        lastName: jinalastCon.text,
        couponCode: couponCodeCon.text,
        phoneNumber: '',
        email: baruapepeCon.text,
        balance: 10000.0,
        registrationDate: DateTime.now(),
        lastLoginDate: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection(ucol)
          .doc(userId)
          .set(userr.kwendaJson(), SetOptions(merge: true));
    } catch (shida) {
      debugPrint('shida ni: $shida');
    }
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }

  goOn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const NavHost()),
      (route) => false,
    );
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
      body: Container(
        padding: const EdgeInsets.only(left: 32, right: 32),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(coverpic),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(bsm),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Forgot password',
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
      ),
    );
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }
}
