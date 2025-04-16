import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

enum ReadingStatus {
  wantToRead('Want to Read', Colors.orangeAccent),
  currentlyReading('Currently Reading', Colors.teal),
  finished('Finished', Colors.deepPurple);

  const ReadingStatus(this.label, this.color);
  final String label;
  final Color color;

  static final List<DropdownMenuItem<ReadingStatus>> items = UnmodifiableListView<DropdownMenuItem<ReadingStatus>>(
    values.map<DropdownMenuItem<ReadingStatus>>(
      (ReadingStatus status) => DropdownMenuItem<ReadingStatus>(
        value: status,
        child: Text(
          status.label,
          style: TextStyle(color: status.color),
        ),
      ),
    ),
  );
}
