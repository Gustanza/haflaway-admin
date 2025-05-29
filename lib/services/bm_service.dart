import 'dart:convert';

const bmSecretKey =
    "MDZjMzE0OTg2YWE5ZmQ5NjE0MDA1ZmYzNjA0NGYwZWUwNDNkZDYyNmZlMjhlNzhjYWM1YjQyZjY3ZDA1ODNmNA==";

const bmAPIKey = 'a809b9356629fd29';

var bmHeaders = {
  "Authorization": 'Basic ${base64Encode(
    utf8.encode("$bmAPIKey:$bmSecretKey"),
  )}',
  'Accept': "application/json",
  'Content-Type': "application/json"
};

Map<String, dynamic> bmBody = {
  "source_addr": "HAFLAWAY",
  "schedule_time": "",
  "encoding": "0"
};
