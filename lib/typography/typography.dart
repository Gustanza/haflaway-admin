import 'package:flutter/material.dart';
import 'package:haflaway/utils/styles.dart';

/* heading */
h3({str}) {
  return Text(
    str,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: fsm + 2),
  );
}
/* heading */

/* paragraph */

pn({str}) {
  return Text("$str", style: TextStyle(color: Colors.grey[100]));
}

/* paragraph */
