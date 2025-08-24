import 'package:flutter/material.dart';
import 'package:haflaway/utils/colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              height: size.height * 0.8,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: scagrad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "HAFLAWAY",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Create & Share Beautiful Wedding Invitations",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: const [
                  FeatureTile(
                    icon: Icons.sms,
                    title: "Instant SMS Invitations",
                    subtitle:
                        "Send wedding invites directly via SMS in one click.",
                  ),
                  SizedBox(height: 20),
                  FeatureTile(
                    icon: Icons.chat_bubble,
                    title: "WhatsApp Sharing",
                    subtitle:
                        "Easily share your invitations with your guests on WhatsApp.",
                  ),
                  SizedBox(height: 20),
                  FeatureTile(
                    icon: Icons.design_services,
                    title: "Elegant Designs",
                    subtitle:
                        "Choose from beautiful templates tailored for weddings.",
                  ),
                ],
              ),
            ),

            // Call to Action
            Container(
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: scagrad,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    "Start Your Celebration with HaflaWay",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Download the app and share your joy effortlessly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: lqassgradBaseColor,
          child: Icon(icon, color: primaryWhite),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
