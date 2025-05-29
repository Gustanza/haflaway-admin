// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:intl_phone_number_input/intl_phone_number_input.dart';
// import 'package:haflaway/models/user.dart';
// import 'package:haflaway/top_destinations/navhost.dart';
// import 'package:haflaway/utils/dimensions.dart';
// import 'package:haflaway/utils/globalfns.dart';
// import 'package:haflaway/utils/globalwids.dart';
// import 'package:haflaway/utils/strings.dart';
// import 'package:pinput/pinput.dart';
// // import '../utils/styles.dart';

// class PhoneRegister extends StatefulWidget {
//   const PhoneRegister({super.key});

//   @override
//   State<PhoneRegister> createState() => _PhoneRegisterState();
// }

// class _PhoneRegisterState extends State<PhoneRegister> {
//   String phonenumber = '';
//   FirebaseAuth auth = FirebaseAuth.instance;
//   PhoneNumber number = PhoneNumber(isoCode: 'TZ');
//   TextEditingController pcont = TextEditingController();
//   TextEditingController fnameCont = TextEditingController();
//   TextEditingController lnameCont = TextEditingController();
//   TextEditingController coucodeCont = TextEditingController();
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     askSmsPerm();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Form(
//           key: formKey,
//           child: Center(
//             child: MaterialButton(
//               onPressed: () {},
//               child: const Text("data"),
//             ),
//           ),
//           // ListView(
//           //   reverse: true,
//           //   padding: const EdgeInsets.all(psm),
//           //   children: [
//           //     const SizedBox(height: psm),
//           //     ElevatedButton(
//           //       onPressed: submit,
//           //       child: const Text("Continue"),
//           //     ),
//           //     const SizedBox(height: psm),
//           //     buildField(
//           //       controller: coucodeCont,
//           //       placeholder: "Coupon Code (optional)",
//           //     ),
//           //     // const SizedBox(height: psm),
//           //     buildPhone(),
//           //     const SizedBox(height: psm),
//           //     buildField(
//           //       controller: lnameCont,
//           //       placeholder: rglname,
//           //     ),
//           //     const SizedBox(height: psm),
//           //     buildField(
//           //       controller: fnameCont,
//           //       placeholder: rgfname,
//           //     ),
//           //     const SizedBox(height: psm),
//           //     Center(
//           //       child: Padding(
//           //         padding: const EdgeInsets.only(
//           //           top: psm * 0.5,
//           //           left: psm * 2,
//           //           right: psm * 2,
//           //         ),
//           //         child: Text(
//           //           "Provide a phone number to use for registration",
//           //           textAlign: TextAlign.center,
//           //           style: normal(),
//           //         ),
//           //       ),
//           //     ),
//           //     Center(
//           //       child: Text(
//           //         "Register",
//           //         style: header1(),
//           //       ),
//           //     ),
//           //   ],
//           // ),
//         ),
//       ),
//     );
//   }

//   buildPhone() {
//     return IntlPhoneField(
//       controller: pcont,
//       decoration: const InputDecoration(
//         labelText: 'Phone Number',
//         border: OutlineInputBorder(
//           borderSide: BorderSide(),
//         ),
//       ),
//       initialCountryCode: 'TZ',
//       onChanged: (phone) {
//         phonenumber = phone.completeNumber;
//       },
//     );
//   }

//   buildField({controller, placeholder}) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         hintText: placeholder,
//         border: const OutlineInputBorder(),
//       ),
//       textInputAction: TextInputAction.next,
//       textCapitalization: TextCapitalization.sentences,
//       validator: (value) {
//         switch (placeholder) {
//           case rgfname:
//             if (value == null || value.isEmpty) {
//               return rgfnameErr;
//             } else {
//               return null;
//             }
//           case rglname:
//             if (value == null || value.isEmpty) {
//               return rglnameErr;
//             } else {
//               return null;
//             }

//           default:
//             return null;
//         }
//       },
//     );
//   }

//   Future<String?> showPinPut() async {
//     return await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Center(child: Text("Enter OTP")),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "A One Time Password was sent to your mobile number",
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: psm),
//               Pinput(
//                 length: 6,
//                 onCompleted: (pin) {
//                   Navigator.of(context).pop(pin);
//                 },
//               ),
//               const SizedBox(height: psm * 0.5),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text("Resend Code"),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   submit() async {
//     bool isValid = formKey.currentState?.validate() ?? false;
//     if (pcont.text.isNotEmpty && isValid) {
//       showProgress(context: context);
//       try {
//         await auth.verifyPhoneNumber(
//           phoneNumber: phonenumber,
//           verificationCompleted: (PhoneAuthCredential credential) async {
//             await auth.signInWithCredential(credential);
//             dismissal(context: context);
//             navnReplaceUntil(context: context, widget: const NavHost());
//           },
//           verificationFailed: (FirebaseAuthException e) {
//             debugPrint("error ni: ${e.message}");
//             showToast(isGood: false, msg: e.message);
//             dismissal(context: context);
//           },
//           codeSent: (String verificationId, int? resendToken) async {
//             dismissal(context: context);
//             String? smsCode = await showPinPut();
//             if (smsCode != null && smsCode.isNotEmpty) {
//               PhoneAuthCredential credential = PhoneAuthProvider.credential(
//                   verificationId: verificationId, smsCode: smsCode);
//               try {
//                 showProgress(context: context);
//                 await auth.signInWithCredential(credential);
//                 await uploadUser();
//               } catch (e) {
//                 dismissal(context: context);
//                 showToast(isGood: false, msg: e);
//               }
//             } else {
//               showToast(isGood: false, msg: "OTP patching failed");
//             }
//           },
//           codeAutoRetrievalTimeout: (String verificationId) {},
//         );
//       } catch (e) {
//         dismissal(context: context);
//         showToast(isGood: false, msg: e.toString());
//       }
//     }
//   }

//   uploadUser() async {
//     try {
//       var uid = auth.currentUser?.uid;
//       await FirebaseFirestore.instance.collection(ucol).doc(uid).set(Userr(
//             firstName: fnameCont.text,
//             lastName: lnameCont.text,
//             phonenumber: phonenumber,
//             lastLoginDate: DateTime.now(),
//             registrationDate: DateTime.now(),
//             couponCode: coucodeCont.text,
//           ).kwendaJson());
//       dismissal(context: context);
//       navnReplaceUntil(context: context, widget: const NavHost());
//       return true;
//     } catch (e) {
//       await auth.signOut();
//       dismissal(context: context);
//       showToast(isGood: false, msg: e);
//       return false;
//     }
//   }
// }
