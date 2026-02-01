import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/app_users/app_users.dart';
import 'package:haflaway/top_destinations/settings/account.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/dimensions.dart';

Widget drawer({context}) {
  return Drawer(
    shape: BeveledRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(0),
    ),
    backgroundColor: scaback,
    child: Container(
      decoration: BoxDecoration(gradient: scagrad),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 0),
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/utils/imagen/icon.png'),
              ),
              title: Text("Haflaway Cpanel"),
              subtitle: getEvsCount(),
              onTap: () {},
              trailing: Icon(Icons.stop, size: icnsm, color: Colors.green),
            ),
            Divider(thickness: 0.1, height: 0),
            ListTile(
              title: Text("Settings & Configs"),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return Mipangilio();
                    },
                  ),
                );
              },
              trailing: Icon(Icons.arrow_forward_ios, size: icnsm),
            ),
            Divider(thickness: 0.1, height: 0),
            // ListTile(
            //   title: Text("Users Management"),
            //   onTap: () {
            //     Navigator.of(context).pop();
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) {
            //           return AppUsersScreen();
            //         },
            //       ),
            //     );
            //   },
            //   trailing: Icon(Icons.arrow_forward_ios, size: icnsm),
            // ),
            // Divider(thickness: 0.1, height: 0),
          ],
        ),
      ),
    ),
  );
}

getEvsCount() {
  return FutureBuilder(
    future: FirebaseFirestore.instance.collection(ecol).count().get(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        var count = snapshot.data?.count;
        return Text("$count Events total");
      } else if (snapshot.hasError) {
        return Text("Data unavailable");
      } else {
        return Text("Loading...");
      }
    },
  );
}
