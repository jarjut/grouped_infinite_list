// ignore_for_file: prefer_const_constructors

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grouped_infinite_list/grouped_infinite_list.dart';

void main() {
  group('GroupedInfiniteList', () {
    test('can be instantiated', () {
      expect(
        GroupedInfiniteList(
          itemBuilder: (context, index) => Container(),
          groupBy: (item) => item,
          groupSeparatorBuilder: (item) => Container(),
          positiveItems: const [],
        ),
        isNotNull,
      );
    });
  });
}
