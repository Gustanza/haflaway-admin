import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/styles.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  bool isDarkMode = false;
  bool pushNotifications = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        elevation: psm,
        title: const Text("Account"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) {
                    return const Login();
                  },
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        "${firebaseAuth.currentUser?.photoURL}",
                      ), // Replace with actual image
                    ),
                  ),
                  Text(
                    "${firebaseAuth.currentUser?.displayName}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${firebaseAuth.currentUser?.email}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            expandedHeight: 250,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Settings Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: psm),
                child: CupertinoListSection.insetGrouped(
                  header: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: psm * 0.5),
                      Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: fsm,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(top: psm * 0.5, bottom: psm),
                  children: [
                    buildSettingsItem('Edit Profile', Icons.arrow_forward_ios),
                    buildSwitchItem('Push Notifications', pushNotifications, (
                      value,
                    ) {
                      setState(() {
                        pushNotifications = value;
                      });
                    }),
                    buildSwitchItem('Dark Mode', themeProvider.isDarkMode, (
                      value,
                    ) {
                      // setState(() {
                      final provider = Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      );
                      provider.toggleTheme(value);
                      // });
                    }),
                    buildSettingsItem(
                      'Change Language',
                      Icons.arrow_forward_ios,
                    ),
                    buildSettingsItem(
                      'Terms and Conditions',
                      Icons.arrow_forward_ios,
                    ),
                    buildSettingsItem(
                      'Help and Support',
                      Icons.arrow_forward_ios,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget buildSettingsItem(String title, IconData icon) {
    return ListTile(title: Text(title), trailing: Icon(icon), onTap: () {});
  }

  Widget buildSwitchItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
