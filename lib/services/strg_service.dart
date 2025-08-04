import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/globalfns.dart';

class StorageService {
  static Future fetchFile({
    required KardType kardtype,
    required List<Attendee> atList,
    required Function(String) fdbck,
  }) async {
    try {
      // Get user selected directory
      String? selDir = await FilePicker.platform.getDirectoryPath();
      if (selDir == null) {
        return;
      }
      debugPrint("Abject: len ${atList.length}");
      for (var oneAt in atList) {
        var attrCrdMap = oneAt.cards[kardtype.name];
        if (attrCrdMap == null) {
          debugPrint("Abject: skipped");
          continue;
        }
        debugPrint("Abject: came");
        AttributeCard attributeCard = AttributeCard.fromMap(map: attrCrdMap);
        debugPrint("Abject: reached");
        String fileUrl = attributeCard.url!;
        debugPrint("Abject: url $fileUrl");
        // Create a reference to the file in Firebase Storage
        final fileRef = FirebaseStorage.instance.refFromURL(fileUrl);
        // Get the total size of the file
        final metadata = await fileRef.getMetadata();
        final totalBytes = metadata.size ?? 0;
        String? contentType = metadata.contentType;
        String rndNum = (Random().nextInt(9000) + 1000).toString();
        String cleanType = contentType!.split('/').last;
        final filePath = '$selDir/$rndNum.$cleanType';
        final videofile = File(filePath);
        // Start the download
        showToast(isGood: true, msg: "Starting Download Sequence");
        // await thumbnailref.writeToFile(thumbnailfile);
        final downloadTask = fileRef.writeToFile(videofile);

        // Listen to the download progress
        downloadTask.snapshotEvents.listen((taskSnapshot) async {
          switch (taskSnapshot.state) {
            case TaskState.running:
              final progress = taskSnapshot.bytesTransferred / totalBytes;
              String percent = "${(progress * 100).truncate()} %";
              fdbck(percent);
              break;
            case TaskState.success:
              fdbck("Success");
              break;
            case TaskState.error:
              fdbck("Retry");
              break;
            default:
              //
              break;
          }
        });

        // Wait for the download to complete
        await downloadTask;
      } //end for-loop
      return;
    } catch (e) {
      showToast(isGood: false, msg: "$e");
      return;
    }
  }
}
