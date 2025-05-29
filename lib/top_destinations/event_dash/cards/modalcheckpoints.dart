import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';

class BuildModalChecks extends StatefulWidget {
  final dynamic data;
  final List? checkpoints;
  final Function(List) isTapped;
  const BuildModalChecks({
    super.key,
    required this.data,
    required this.isTapped,
    required this.checkpoints,
  });

  @override
  State<BuildModalChecks> createState() => _BuildModalChecksState();
}

class _BuildModalChecksState extends State<BuildModalChecks> {
  late List checkpoints;
  @override
  void initState() {
    checkpoints = widget.checkpoints!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: CupertinoListSection.insetGrouped(
        margin: EdgeInsets.zero,
        children: List.generate(widget.data.length, (index) {
          var value = checkpoints.contains(widget.data[index].id);
          return CheckboxListTile(
            title: Text(widget.data[index][echeckname]),
            value: value,
            onChanged: (val) {
              if (value) {
                checkpoints.remove(widget.data[index].id);
              } else {
                checkpoints.add(widget.data[index].id);
              }
              setState(() {
                widget.isTapped(checkpoints);
              });
            },
          );
        }),
      ),
    );
  }
}
