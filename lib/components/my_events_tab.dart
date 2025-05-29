import 'package:flutter/cupertino.dart';
import 'package:haflaway/utils/dimensions.dart';

var myevtabs = {
  0: myevtext(data: "Personal Events"),
  1: myevtext(data: "Guest Events"),
};

Widget myevtext({data}) {
  return Padding(padding: const EdgeInsets.all(psm), child: Text(data));
}
