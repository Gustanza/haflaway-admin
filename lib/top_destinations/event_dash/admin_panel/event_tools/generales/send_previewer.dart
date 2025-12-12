import 'package:flutter/material.dart';
import 'package:haflaway/components/Ccafold.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/templates.dart';
import 'package:haflaway/utils/colors.dart';

class SendPreviewer extends StatefulWidget {
  const SendPreviewer({super.key});

  @override
  State<SendPreviewer> createState() => _SendPreviewerState();
}

class _SendPreviewerState extends State<SendPreviewer> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaback,
        appBar: appBar(
          title: "Unaelekea Kutuma",
          leading: buildActionButton(
            icon: Icons.arrow_back,
            onTap: () {
              popper();
            },
          ),
        ),
        body: Ccafold(
          child: Column(
            children: [
              TabBar(
                dividerHeight: 0,
                indicatorColor: primaryColor,
                labelColor: primaryColor,
                tabs: [Tab(text: "WhatsApp Channel"), Tab(text: "SMS Channel")],
              ),
            ],
          ),
        ),
      ),
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
