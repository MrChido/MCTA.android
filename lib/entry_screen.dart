import 'package:flutter/material.dart';
import 'package:spoonie/main.dart';
import 'services/database_helper.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import "Utilities/slumber_util.dart";

class EntryScreen extends StatefulWidget {
  final int day;
  final Function(int) updateEntryCount;
  const EntryScreen({required this.day, required this.updateEntryCount});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _BoltThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(30, 30);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    const iconSize = 24.0;

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.bolt.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: Icons.bolt.fontFamily,
          package: Icons.bolt.fontPackage,
          color: sliderTheme.thumbColor ?? Colors.deepOrangeAccent,
        ),
      ),
      textDirection: textDirection,
    );

    iconPainter.layout();
    iconPainter.paint(canvas, center - Offset(iconSize / 2, iconSize / 2));
  }
}

class _WaterDropThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(30, 30);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    const iconSize = 24.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.water_drop.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: Icons.water_drop.fontFamily,
          package: Icons.water_drop.fontPackage,
          color: sliderTheme.thumbColor ?? Colors.blueAccent,
        ),
      ),
      textDirection: textDirection,
    );

    textPainter.layout();
    textPainter.paint(canvas, center - Offset(iconSize / 2, iconSize / 2));
  }
}

class _EntryScreenState extends State<EntryScreen> {
  bool fatigue = false;
  int severity = 4;
  final TextEditingController _bsugarsController = TextEditingController();
  List<String> mnm = [];
  List<String> activities = [];
  final TextEditingController _mnmController = TextEditingController();
  final TextEditingController _activitiesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _wakeTimeController = TextEditingController();
  final TextEditingController _sleepTimeController = TextEditingController();
  int water = 0;
  final TextEditingController _hHealthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool mperiod = false;

  String convertToMilitaryTime(String timeInput) {
    timeInput = timeInput.trim().toLowerCase(); //normalize the case usage
    RegExp regExp = RegExp(r'(\d{1,2})[:.](\d{2})\s*(am|pm)?');
    Match? match = regExp.firstMatch(timeInput);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      String? period = match.group(3);

      if (period == "pm" && hour != 12) {
        hour += 12; //add 12 hours to the input
      } else if (period == "am" && hour == 12) {
        hour = 0; //convert 12 AM to 00
      }

      return "${hour.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}";
    }

    return "Invalid Format";
  }

//android conversion stoped here
  Future<void> safeDraft() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString('bsugars_draft', _bsugarsController.text);
    prefs.setString('hHealth_draft', _hHealthController.text);
    prefs.setString('weight_draft', _weightController.text);
    prefs.setString('mnm_draft', _mnmController.text);
    prefs.setString('activites_draft', _activitiesController.text);
    prefs.setString('symptoms_draft', _symptomsController.text);
    prefs.setString('wake_draft', _wakeTimeController.text);
    prefs.setString('sleep_draft', _sleepTimeController.text);
    prefs.setInt('severity_draft', severity);
    prefs.setBool('fatigue_draft', fatigue);
    prefs.setInt('water_draft', water);
    prefs.setBool('mperiod_draft', mperiod);
  }

  int getSleepTimeValue() {
    final text = _sleepTimeController.text.trim();
    return text.isEmpty ? -1 : parseCustomTimeFormat(text);
  }

  int getWakeTimeValue() {
    final text = _wakeTimeController.text.trim();
    return text.isEmpty ? -1 : parseCustomTimeFormat(text);
  }

  @override
  void dispose() {
    _bsugarsController.dispose();
    _mnmController.dispose();
    _activitiesController.dispose();
    _symptomsController.dispose();
    _wakeTimeController.dispose();
    _sleepTimeController.dispose();
    _hHealthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Please fill all the fields')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Toggle Symptoms:'),
            SwitchListTile(
              title: Text('Fatigue'),
              value: fatigue,
              onChanged: (bool newValue) {
                setState(() {
                  fatigue = newValue;
                });
              },
            ),
            SwitchListTile(
              title: Text('Menstrual Period'),
              value: mperiod,
              onChanged: (bool newValue) {
                setState(() {
                  mperiod = newValue;
                });
              },
            ),
            Text('Pain Severity:'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: _BoltThumb(),
                thumbColor: Colors.deepOrangeAccent,
              ),
              child: Slider(
                value: severity.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: severity.round().toString(), //shows current value
                onChanged: (double newValue) {
                  setState(() {
                    severity = newValue.toInt();
                  });
                },
              ),
            ),
            Text('Sleep Cycle:'),
            Text('Bed Time:'),
            TextField(
                controller: _sleepTimeController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                    hintText: '10.00PM',
                    hintStyle: TextStyle(color: Colors.grey))),
            Text('Woke up at:'),
            TextField(
                controller: _wakeTimeController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                    hintText: '7.00AM',
                    hintStyle: TextStyle(color: Colors.grey))),
            Text('Physical Health:'),
            Text('Blood Sugar:'),
            TextField(
                controller: _bsugarsController,
                style: TextStyle(color: Colors.black), //tracks the input
                decoration: InputDecoration(
                    hintText: "Enter single readings",
                    hintStyle: TextStyle(color: Colors.grey))),
            Text('Heart Health (Systolic/Diastolic/Heart Rate/O²):'),
            TextField(
              controller: _hHealthController,
              style: TextStyle(color: Colors.black), //tracks the input
              decoration: InputDecoration(
                  hintText: "Systolic/Diastolic/Heart Rate/O²",
                  hintStyle: TextStyle(color: Colors.grey)),
            ),
            Text('Weight:'),
            TextField(
              controller: _weightController,
              style: TextStyle(color: Colors.black), //tracks the input
              decoration: InputDecoration(
                  hintText: "Please Enter your Weight(Lb)",
                  hintStyle: TextStyle(color: Colors.grey)),
            ),
            Text('Consumptions:'),
            Text('Meals/Medications:'),
            TextField(
              controller: _mnmController,
              style: TextStyle(color: Colors.black), //tracks the input
              decoration: InputDecoration(
                  hintText: "separate by commas",
                  hintStyle: TextStyle(color: Colors.grey)),
            ),
            Text('water (oz):'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: _WaterDropThumb(),
                thumbColor: Colors.blueAccent,
              ),
              child: Slider(
                value: water.toDouble(),
                min: 0,
                max: 110,
                divisions: 11, //0 to median 110 oz in steps of 10
                label: "$water oz",
                activeColor: Colors.blueAccent,
                onChanged: (double newWat) {
                  setState(() {
                    water = ((newWat / 10).round() * 10).clamp(0,
                        110); // This is how sliders work you have your input "newWat" and 10 points on the line.
                    //.round() *10 makes the divisions clean, .clamp() defines the 2 endpoints of the slider.
                  });
                },
              ),
            ),
            Text('Internal & External factors:'),
            Text('Activities:'),
            TextField(
              controller: _activitiesController,
              style: TextStyle(color: Colors.black), //tracks the input
              decoration: InputDecoration(
                  hintText: "separate by commas",
                  hintStyle: TextStyle(color: Colors.grey)),
            ),

            Text('Symptoms:'),
            TextField(
              controller: _symptomsController,
              style: TextStyle(color: Colors.black), //tracks symptom input
              decoration: InputDecoration(
                  hintText: 'separate by commas',
                  hintStyle: TextStyle(color: Colors.grey)),
            ),

            //Save Entry Button
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  print("Save button tapped.");
                  final sleepTime = getSleepTimeValue();
                  final wakeTime = getWakeTimeValue();
                  print(
                      'Sleep time being saved to DB: $sleepTime'); // Debug print
                  String bloodSugarInput =
                      _bsugarsController.text.trim(); //get user input
                  //int bloodSugarValue = int.tryParse(bloodSugarInput) ?? 0;
                  String hHealth = _hHealthController.text.trim();

                  List<String> mnm = _mnmController.text
                      .trim()
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  List<String> activities = _activitiesController.text
                      .trim()
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  List<String> symptoms = _symptomsController.text
                      .trim()
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  String mnmInput = jsonEncode(mnm);
                  String activitiesInput = jsonEncode(activities);
                  String symptomsInput = jsonEncode(symptoms);
                  double weight =
                      double.tryParse(_weightController.text) ?? 0.0;

                  final now = DateTime.now();
                  // Create a DateTime that combines the selected date with the current time
                  final selectedDateTime = DateTime(
                    now.year,
                    now.month,
                    widget.day,
                    now.hour,
                    now.minute,
                    now.second,
                  );
                  print(
                      "Saving entry with timestamp for selected date (day ${widget.day})");
                  await DatabaseHelper().insertEntry(
                      widget.day, // Use the selected day for saving
                      severity.round(),
                      fatigue,
                      bloodSugarInput,
                      mnmInput,
                      activitiesInput,
                      symptomsInput,
                      wakeTime,
                      sleepTime,
                      water.round(),
                      hHealth,
                      weight,
                      mperiod);
                  print("mnm before inserting: $mnmInput");
                  print("activities before inserting: $activitiesInput");

                  widget.updateEntryCount(widget
                      .day); // Calls the function passed from CalendarScreen
                  print("About to pop back to main");
                  FocusScope.of(context).unfocus();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => CalendarScreen()),
                    (route) => false,
                  );
                },
                child: Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
