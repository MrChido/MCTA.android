import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicationsCard extends StatefulWidget {
  @override
  _MedicationsCardState createState() => _MedicationsCardState();
}

class _MedicationsCardState extends State<MedicationsCard> {
  List<String> medications = [];
  bool isExpanded = false;
  bool isEditing = false;
  final String medicationKey = 'medications';

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(medicationKey);
    setState(() {
      medications = savedList ?? [""];
    });
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(medicationKey, medications);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: true,
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              isEditing
                  ? Column(
                      children: List.generate(medications.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextFormField(
                            initialValue: medications[index],
                            onChanged: (value) {
                              medications[index] = value;
                            },
                            decoration: InputDecoration(
                              labelText: "Item ${index + 1}",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        );
                      }),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: medications
                          .map((med) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(med),
                              ))
                          .toList(),
                    ),
              if (isExpanded) ...[
                Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEditing)
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            medications.add("");
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(isEditing ? Icons.check : Icons.edit,
                          color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                          if (!isEditing) _saveMedications();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
