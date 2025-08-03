import 'package:flutter/material.dart';

Color getColor(
  int entryCount,
  int day,
  bool isReviewMode,
  reviewedDays,
) {
  if (isReviewMode && reviewedDays.contains(day)) {
    return Color(0xFF4B0082); //indigo color
  }
  if (entryCount == 0) return Colors.grey;
  //this bit of code, is the gradient from grey to green to yellow to red
  //it will adapt to the number of entries and transition
  const int maxCount =
      10; //the gradient change caps at 10 entries for the transition.
  final normalized = (entryCount / maxCount).clamp(0.0, 1.0);
  if (entryCount <= 5) {
    return Color.lerp(Colors.grey, Colors.green, normalized / (5 / maxCount))!;
  } else if (entryCount <= 9) {
    return Color.lerp(Colors.green, Colors.yellow,
        (normalized - (5 / maxCount)) / ((9 - 5) / maxCount))!;
  } else {
    return Color.lerp(Colors.yellow, Colors.red,
        (normalized - (9 / maxCount)) / ((maxCount - 9) / maxCount))!;
  }
}

BoxDecoration getMulberryRingDeco(bool isPeriodDay) {
  return isPeriodDay
      ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isPeriodDay
                ? Color.fromARGB(255, 198, 67, 164)
                : Colors.transparent,
            width: 5.0,
          ),
        )
      : BoxDecoration();
}

double getFlameSize(int entryCount) {
  if (entryCount < 10) {
    return 0; //remains hidden for the sake of the icon size at the begining.
  }
  const double minSize = 20;
  const double maxSize = 30;
  const int sStart = 10;
  const int sEnd = 20;

  final flareUp = ((entryCount - sStart) / (sEnd - sStart)).clamp(0.0, 1.0);
  return minSize + (maxSize - minSize) * flareUp;
}
