import 'package:flutter/material.dart';
import '../Utilities/color_util.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime currentMonth;
  final int firstWeekday; // 1=Mon … 7=Sun
  final int daysInMonth;
  final Map<int, int> entriesPerDay;
  final List<int> reviewedDays;
  final bool isReviewMode;
  final ValueChanged<int> onDayTapped;

  const CalendarWidget({
    super.key,
    required this.currentMonth,
    required this.firstWeekday,
    required this.daysInMonth,
    required this.entriesPerDay,
    required this.reviewedDays,
    required this.isReviewMode,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    // How many table rows we need
    final rowCount = ((daysInMonth + (firstWeekday - 1)) / 7).ceil();
    //sunday first labels:
    final labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final offset = firstWeekday % 7;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: labels
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: TextStyle(fontWeight: FontWeight.bold)))))
                .toList(),
          ),
          SizedBox(height: 8),
          // Calendar grid
          Table(
            children: List.generate(rowCount, (weekIdx) {
              return TableRow(
                children: List.generate(7, (wdayIdx) {
                  // slotIndex 0 maps to Mon slot if firstWeekday==1
                  final slot = weekIdx * 7 + wdayIdx;
                  final day = slot - offset + 1;

                  // blank cell if outside 1…daysInMonth
                  if (day < 1 || day > daysInMonth) {
                    return SizedBox(height: 40);
                  }

                  // determine background & text colors
                  final entryCount = entriesPerDay[day] ?? 0;
                  final bgColor =
                      getColor(entryCount, day, isReviewMode, reviewedDays);
                  final textColor = (isReviewMode && reviewedDays.contains(day))
                      ? Colors.white
                      : Colors.black;

                  return GestureDetector(
                    onTap: () => onDayTapped(day),
                    child: Container(
                      height: 40,
                      margin: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        //This is the controll for the day being at its most extreme point
                        child: entryCount >= 10
                            ? Icon(Icons.whatshot,
                                color: Colors.yellow,
                                size: getFlameSize(entryCount))
                            : Text(
                                '$day',
                                style:
                                    TextStyle(color: textColor, fontSize: 14),
                              ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}
