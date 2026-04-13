import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/eventz/navhost.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              left: -60,
              child: _GusOrb(size: 300, color: Color(0xFFC9A84C), opacity: 0.1),
            ),
            const Positioned(
              bottom: -50,
              right: -80,
              child: _GusOrb(
                size: 250,
                color: Color(0xFFC9A84C),
                opacity: 0.05,
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo/App Title placeholder if needed
                      Text(
                        'HAFLAWAY',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFC9A84C),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access your event management portal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildLoginField(
                        controller: baruaPepeCon,
                        label: 'Email Address',
                        hint: 'name@example.com',
                        icon: Icons.alternate_email_rounded,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildLoginField(
                        controller: nenoSiriCon,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        isObscure: true,
                        type: TextInputType.visiblePassword,
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const KuresetNenoSiri(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFC9A84C).withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: type,
          textCapitalization: capitalization,
          onTap: () {},
          onTapOutside: (e) => FocusScope.of(context).unfocus(),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFFC9A84C).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(
              0xFF141414,
            ), // Slightly lighter for contrast on Login
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFC9A84C),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9A84C),
          foregroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
        ),
        onPressed: () async {
          if (mcheckiFomu()) {
            try {
              setState(() {
                nalodi = true;
              });
              await FirebaseAuth.instance.signInWithEmailAndPassword(
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
        child:
            nalodi
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0A0A0A),
                  ),
                )
                : Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
  final ScrollController _scrollController = ScrollController();

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
    bool isEdit = widget.userr != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              right: -60,
              child: _GusOrb(
                size: 300,
                color: Color(0xFFC9A84C),
                opacity: 0.08,
              ),
            ),
            const Positioned(
              bottom: 100,
              left: -80,
              child: _GusOrb(
                size: 250,
                color: Color(0xFFC9A84C),
                opacity: 0.05,
              ),
            ),

            SafeArea(
              child: Form(
                key: key,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _topBar(isEdit ? 'Edit User' : 'New User'),
                    ),
                    SliverToBoxAdapter(
                      child: _heroTitle(
                        isEdit ? 'Edit Profile' : 'Register User',
                        isEdit
                            ? 'Update security clearance and details'
                            : 'Create a new account for your organization',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 20),
                          // Section 1: Name
                          _buildPremiumSection(
                            label: 'PERSONAL INFORMATION',
                            children: [
                              _buildPremiumField(
                                cont: jinafestCon,
                                lbl: 'First Name',
                                icon: Icons.person_outline_rounded,
                                capitalization: TextCapitalization.sentences,
                              ),
                              const SizedBox(height: 20),
                              _buildPremiumField(
                                cont: jinalastCon,
                                lbl: 'Last Name',
                                icon: Icons.person_outline_rounded,
                                capitalization: TextCapitalization.sentences,
                              ),
                            ],
                          ),

                          if (!isEdit) ...[
                            const SizedBox(height: 24),
                            // Section 2: Account
                            _buildPremiumSection(
                              label: 'ACCOUNT SECURITY',
                              children: [
                                _buildPremiumField(
                                  cont: baruapepeCon,
                                  lbl: 'Email Address',
                                  icon: Icons.alternate_email_rounded,
                                  type: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                _buildPremiumField(
                                  cont: nenoSiriCon,
                                  lbl: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  isObscure: true,
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),
                          // Section 3: Clearance
                          _buildPremiumSection(
                            label: 'AUTHORIZATION',
                            children: [_buildPremiumDropdown()],
                          ),

                          const SizedBox(height: 24),
                          // Section 4: Contact
                          _buildPremiumSection(
                            label: 'CONTACT DETAILS',
                            children: [_buildPremiumPhone()],
                          ),

                          const SizedBox(height: 48),
                          _buildSubmitButton(isEdit),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => popper(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFC9A84C),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'App Users',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection({
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController cont,
    required String lbl,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool isObscure = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lbl,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: cont,
          obscureText: isObscure,
          keyboardType: type,
          textCapitalization: capitalization,
          onTap: () {},
          onTapOutside: (e) => FocusScope.of(context).unfocus(),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          validator: (v) => v!.isEmpty ? "This field is required" : null,
          decoration: InputDecoration(
            hintText: "Enter $lbl",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFFC9A84C).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC9A84C),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Clearance Level",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selClrnc,
          dropdownColor: const Color(0xFF141414),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFC9A84C),
            size: 20,
          ),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Select Level",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            prefixIcon: Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: const Color(0xFFC9A84C).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC9A84C),
                width: 1.5,
              ),
            ),
          ),
          items:
              clrncDict.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
          isExpanded: true,
          onChanged: (v) {
            setState(() {
              selClrnc = v;
            });
          },
          validator: (v) => v == null ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildPremiumPhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: phoneCon,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          dropdownTextStyle: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Phone Number',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC9A84C),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          initialCountryCode: 'TZ',
          onChanged: (phone) {
            phnnumber = phone.completeNumber.replaceAll('+', '');
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9A84C),
          foregroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
        ),
        onPressed: nalodi ? null : _handleSubmit,
        child:
            nalodi
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0A0A0A),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEdit ? Icons.check_rounded : Icons.person_add_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? "Save Changes" : "Create Account",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _handleSubmit() async {
    bool isValid = key.currentState?.validate() ?? false;
    if (isValid && izVally()) {
      try {
        safeState(() {
          nalodi = true;
        });
        if (widget.userr == null) {
          // Prevention of admin logout: Use a secondary Firebase App
          FirebaseApp tempApp;
          try {
            tempApp = await Firebase.initializeApp(
              name: 'TemporaryUserCreator',
              options: Firebase.app().options,
            );
          } catch (e) {
            tempApp = Firebase.app('TemporaryUserCreator');
          }

          FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          UserCredential creds = await tempAuth.createUserWithEmailAndPassword(
            email: baruapepeCon.text.trim(),
            password: nenoSiriCon.text.trim(),
          );

          // Save details using the main firestore instance (authorized by admin)
          await createDeits(userId: creds.user?.uid);

          // Delete the temporary app
          await tempApp.delete();
        } else {
          await saveEdits(userId: widget.userr?.id ?? "");
        }
        safeState(() {
          nalodi = false;
        });
        popper();
      } catch (shida) {
        safeState(() {
          nalodi = false;
        });
        mjumbe(shida.toString());
      }
    }
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

  Future<void> createDeits({userId}) async {
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
        searchName:
            "${jinafestCon.text.trim().toLowerCase()} ${jinalastCon.text.trim().toLowerCase()}",
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
        searchName:
            "${jinafestCon.text.trim().toLowerCase()} ${jinalastCon.text.trim().toLowerCase()}",
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
        color: color.withOpacity(opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class KuresetNenoSiri extends StatefulWidget {
  // ... existing KuresetNenoSiri code ...
  const KuresetNenoSiri({super.key});

  @override
  State<KuresetNenoSiri> createState() => _KuresetNenoSiriState();
}

class _KuresetNenoSiriState extends State<KuresetNenoSiri> {
  TextEditingController baruaPepeCon = TextEditingController();
  bool nalodi = false;
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // Ambient Orbs
            const Positioned(
              top: -100,
              right: -60,
              child: _GusOrb(size: 300, color: Color(0xFFC9A84C), opacity: 0.1),
            ),

            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Reset Access',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email to receive recovery instructions',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 48),

                          _buildResetField(),

                          const SizedBox(height: 40),
                          _buildResetButton(),
                        ],
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFC9A84C),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email Address",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: baruaPepeCon,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'name@example.com',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              size: 20,
              color: const Color(0xFFC9A84C).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFF141414),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFC9A84C),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9A84C),
          foregroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 0,
        ),
        onPressed: () async {
          if (baruaPepeCon.text.isNotEmpty) {
            try {
              setState(() {
                nalodi = true;
              });
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: baruaPepeCon.text,
              );
              setState(() {
                nalodi = false;
              });
              mjumbe('Recovery instructions sent to your email');
            } catch (shida) {
              setState(() {
                nalodi = false;
              });
              mjumbe(shida.toString());
            }
          } else {
            mjumbe('Email address is required');
          }
        },
        child:
            nalodi
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0A0A0A),
                  ),
                )
                : Text(
                  'Send Instructions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
    );
  }

  mjumbe(String ujumbe) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ujumbe)));
  }
}
