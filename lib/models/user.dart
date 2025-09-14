import 'package:haflaway/auth/utils.dart';

const ucol = "users";

class Userr {
  String id;
  String profileImage;
  String firstName;
  String lastName;
  String phoneNumber;
  String email;
  double balance;
  bool isActive;
  DateTime registrationDate;
  DateTime lastLoginDate;
  String couponCode;

  Userr({
    required this.id,
    this.isActive = false,
    required this.profileImage,
    required this.firstName,
    required this.lastName,
    required this.couponCode,
    required this.phoneNumber,
    required this.email,
    required this.balance,
    required this.registrationDate,
    required this.lastLoginDate,
  });

  Map<String, dynamic> kwendaJson() => {
    'isActive': isActive,
    ufname: firstName,
    ulname: lastName,
    uphoneno: phoneNumber,
    uregdate: registrationDate.toIso8601String(),
    ulastlogin: lastLoginDate.toIso8601String(),
    ucouponcode: couponCode,
    uemail: email,
    ubalance: balance,
    uprofileImage: profileImage,
  };

  factory Userr.fromMap(String id, Map<String, dynamic> map) {
    return Userr(
      id: id,
      profileImage: map['profileImage'] ?? defImg,
      firstName: map['firstName'] ?? "",
      lastName: map['lastName'] ?? "",
      couponCode: map['couponCode'] ?? "",
      phoneNumber: map['phoneNumber'] ?? "",
      email: map['email'] ?? "",
      isActive: map['isActive'] ?? false,
      balance:
          map['balance'] != null ? (map['balance'] as num).toDouble() : 0.0,
      registrationDate:
          map['registrationDate'] != null
              ? DateTime.parse(map['registrationDate'])
              : DateTime(1990),
      lastLoginDate:
          map['lastLoginDate'] != null
              ? DateTime.parse(map['lastLoginDate'])
              : DateTime(1990),
    );
  }
}

String ufname = "firstName";
String ulname = "lastName";
String uphoneno = "phoneNumber";
String uregdate = "registrationDate";
String ulastlogin = "lastLoginDate";
String ucouponcode = "couponCode";
String uemail = "email";
String ubalance = "balance";
String uprofileImage = "profileImage";
