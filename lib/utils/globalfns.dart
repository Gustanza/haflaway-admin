import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:permission_handler/permission_handler.dart';

navNormal({context, widget}) async {
  return await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return widget;
      },
    ),
  );
}

navnReplace({context, widget}) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) {
        return widget;
      },
    ),
  );
}

navnReplaceUntil({context, widget}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) {
        return widget;
      },
    ),
    (route) => false,
  );
}

showToast({isGood, msg}) {
  return Fluttertoast.showToast(
    msg: "$msg",
    fontSize: fsm,
    timeInSecForIosWeb: 1,
    textColor: Colors.white,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: isGood ? primaryColor : Colors.red,
  );
}

dismissal({context}) {
  return Navigator.of(context).pop();
}

askSmsPerm() async {
  return await Permission.sms
      .onDeniedCallback(() {
        // Your code
      })
      .onGrantedCallback(() {
        showToast(isGood: true, msg: "Permission granted");
      })
      .onPermanentlyDeniedCallback(() {
        // Your code
      })
      .onRestrictedCallback(() {
        // Your code
      })
      .onLimitedCallback(() {
        // Your code
      })
      .onProvisionalCallback(() {
        // Your code
      })
      .request();
}

datePicker({context}) async {
  return await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime(2034),
  );
}

dtPicky({context}) async {
  // Pick a date
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate == null) return null; // User canceled

  // Pick a time
  TimeOfDay? spickedTime = await showTimePicker(
    helpText: "Select start time",
    context: context,
    initialTime: const TimeOfDay(hour: 00, minute: 00),
  );

  if (spickedTime == null) return null; // User canceled

  TimeOfDay? epickedTime = await showTimePicker(
    helpText: "Select end time",
    context: context,
    initialTime: const TimeOfDay(hour: 00, minute: 00),
  );

  if (epickedTime == null) return null; // User canceled

  // Return date and time
  return EventCalendar(
    startTime: DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      spickedTime.hour,
      spickedTime.minute,
    ),
    endTime: DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      epickedTime.hour,
      epickedTime.minute,
    ),
    eventDate: DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
  );
}

cardUploader({file, type}) async {
  FirebaseStorage fSto = FirebaseStorage.instance;
  var sref = fSto.ref().child("$type/${DateTime.now()}${file.name}");
  try {
    await sref.putFile(File(file.path));
    return await sref.getDownloadURL();
  } catch (e) {
    return null;
  }
}

String cleanStr({String? input}) {
  return input!.replaceAll(RegExp(r'[^0-9.-]+'), '');
}

String generateUniqueSequence() {
  final random = Random();
  final now = DateTime.now();

  // Combine timestamp components with random numbers
  String sequence =
      now.millisecondsSinceEpoch.toString().substring(
        7,
      ) + // Last 6 digits of timestamp
      random.nextInt(10).toString() + // Random digit
      (now.microsecond % 10).toString(); // Last digit of microseconds

  return sequence;
}

buildPop({list, icon, onTap}) {
  return PopupMenuButton<String>(
    padding: EdgeInsets.zero,
    icon: Icon(icon),
    onSelected: (value) {
      onTap(value);
    },
    itemBuilder: (context) {
      return List.generate(list.length, (index) {
        return PopupMenuItem<String>(
          value: list[index],
          child: Text(list[index]),
        );
      });
    },
  );
}

String shortenUrl({longUrl}) {
  // Generate hash of long URL
  var bytes = utf8.encode(longUrl);
  var hash = sha256.convert(bytes);
  // Take first 8 characters for short code
  return 'jambo-prime/${hash.toString().substring(0, 8)}';
}
