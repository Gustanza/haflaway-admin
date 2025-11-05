import 'package:haflaway/auth/utils.dart';

const ucol = "users";

class Userr {
  String? id;
  String? profileImage;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? email;
  double? balance;
  bool? isActive;
  int? clearanceLevel;
  String? registrationDate;
  String? lastLoginDate;
  String? couponCode;

  Userr({
    this.id,
    this.isActive = false,
    this.profileImage,
    this.firstName,
    this.lastName,
    this.couponCode,
    this.phoneNumber,
    this.email,
    this.balance,
    this.clearanceLevel,
    this.registrationDate,
    this.lastLoginDate,
  });

  Map<String, dynamic> kwendaJson() => {
    if (isActive != null) 'isActive': isActive,
    if (firstName != null) ufname: firstName,
    if (lastName != null) ulname: lastName,
    if (phoneNumber != null) uphoneno: phoneNumber,
    if (couponCode != null) ucouponcode: couponCode,
    if (email != null) uemail: email,
    if (balance != null) ubalance: balance,
    if (profileImage != null) uprofileImage: profileImage,
    if (registrationDate != null) uregdate: registrationDate,
    if (lastLoginDate != null) ulastlogin: lastLoginDate,
    if (clearanceLevel != null) uclearance: clearanceLevel,
  };

  factory Userr.fromMap(String id, Map<String, dynamic> map) {
    return Userr(
      id: id,
      profileImage: map['profileImage'] ?? defImg,
      firstName: map['firstName'] ?? "Haflaway",
      lastName: map['lastName'] ?? "User",
      couponCode: map['couponCode'] ?? "",
      phoneNumber: map['phoneNumber'] ?? "255754XXXXXX",
      email: map['email'] ?? "example@haflaway.com",
      isActive: map['isActive'] ?? false,
      balance:
          map['balance'] != null ? (map['balance'] as num).toDouble() : 0.0,
      registrationDate:
          map['registrationDate'] ?? DateTime(1990).toIso8601String(),
      clearanceLevel: map['clearanceLevel'] != null ? map['clearanceLevel'] : 0,
      lastLoginDate: map['lastLoginDate'] ?? DateTime(1990).toIso8601String(),
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
String uclearance = 'clearanceLevel';
String uprofileImage = "profileImage";
