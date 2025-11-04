import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/auth/auth.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/buttons.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/user.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/checktemps.dart';
import 'package:haflaway/top_destinations/settings/notifications/notindex.dart';
import 'package:haflaway/top_destinations/settings/transactions/all_transactions.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/helpers.dart';
import 'package:haflaway/utils/styles.dart';

class Mipangilio extends StatefulWidget {
  const Mipangilio({super.key});

  @override
  State<Mipangilio> createState() => _MipangilioState();
}

class _MipangilioState extends State<Mipangilio> {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        title: 'Account Preferences',
      ),
      body: StreamBuilder(
        stream: firestore.collection(ucol).doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = (snapshot.data as dynamic).data();
            if (data == null) {
              return buildNoDataView("No data");
            }
            Userr userr = Userr.fromMap(userId, data);
            return MyAccountScreen(userr: userr);
          }
          if (snapshot.hasError) {
            return buildErrorView();
          }
          return Center(child: CupertinoActivityIndicator());
        },
      ),
    );
  }
}

class MyAccountScreen extends StatefulWidget {
  final Userr userr;
  const MyAccountScreen({Key? key, required this.userr}) : super(key: key);

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  int? eventsAffils;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    getAffiliations();
    super.initState();
  }

  getAffiliations() async {
    AggregateQuerySnapshot source =
        await firestore
            .collection(ecol)
            .where("adminsIds", arrayContains: "${widget.userr.id}")
            .count()
            .get();
    eventsAffils = source.count;
    safeState(() {});
  }

  safeState(runnable) {
    if (mounted) {
      setState(() {
        runnable();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: scagrad),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: psm,
              right: psm,
              top: p20,
              bottom: p20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: lqassgrad,
                    border: Border.all(
                      color: lqassbdrColor,
                      width: bdrWidthGen,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.userr.firstName} ${widget.userr.lastName}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.userr.email}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: p20),
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.event_outlined,
                        title: 'Events Affiliations',
                        value: 'Total: ${eventsAffils ?? 'No data'}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Account Balance',
                        value: '\TZS ${widget.userr.balance?.toInt()}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: psm),
                // Settings Section
                Text(
                  'Preferences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Other Settings
                _buildSettingsItem(
                  icon: Icons.money,
                  title: 'Transactions',
                  subtitle: 'Preview your cash flow',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AllTransactions(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notifications',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Notifications();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsItem(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  subtitle: 'Password and security',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return KuresetNenoSiri();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Contact support',
                  onTap: () async {
                    await callNumber("+255625689904");
                  },
                ),

                const SizedBox(height: p20),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showConfirmLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  showConfirmLogout() {
    return showDialog(
      context: context,
      builder: (context) {
        return glassDialog(
          child: Padding(
            padding: const EdgeInsets.all(p20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Confirm Logout!",
                  style: TextStyle(
                    fontSize: fsm + 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: psm),
                lqAssButton(
                  label: "Logout",
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) {
                          return Login();
                        },
                      ),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: psm),
                lqAssButton(
                  label: "Cancel",
                  onPressed: () {
                    popper();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: lqassgrad,
        border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fsm + 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: lqassgrad,
          border: Border.all(color: lqassbdrColor, width: bdrWidthGen),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
