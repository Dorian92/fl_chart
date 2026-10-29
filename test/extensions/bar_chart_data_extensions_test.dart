import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/extensions/bar_chart_data_extension.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chart/data_pool.dart';

void main() {
  group('BarChartDataExtension.calculateGroupsX', () {
    test('calculates correct positions for basic alignments', () {
      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.start)
            .calculateGroupsX(100),
        [9.0, 43.0, 77.0],
      );

      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.end)
            .calculateGroupsX(100),
        [23.0, 57.0, 91.0],
      );

      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.center)
            .calculateGroupsX(100),
        [16.0, 50.0, 84.0],
      );

      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.spaceBetween)
            .calculateGroupsX(100),
        [9.0, 50.0, 91.0],
      );

      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.spaceAround)
            .calculateGroupsX(100),
        [16.666666666666668, 50.0, 83.33333333333334],
      );

      expect(
        MockData.barChartData1
            .copyWith(alignment: BarChartAlignment.spaceEvenly)
            .calculateGroupsX(100),
        [20.5, 50.0, 79.5],
      );
    });

    for (final alignment in [
      BarChartAlignment.start,
      BarChartAlignment.end,
      BarChartAlignment.center,
    ]) {
      test(
        'spaces evenly when a groupX exceeds view width for $alignment',
        () {
          expect(
            MockData.barChartData1
                .copyWith(alignment: alignment)
                .calculateGroupsX(60),
            [10.5, 30.0, 49.5],
          );
        },
      );
    }

    test('keeps groupsSpace for single-rod groups that overflow the axis', () {
      final data = BarChartData(
        alignment: BarChartAlignment.start,
        groupsSpace: 80,
        barGroups: [
          for (var i = 0; i < 3; i++)
            BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: 5, width: 15)],
            ),
        ],
      );

      // 3 * 15 + 2 * 80 = 205, which fits in 300 and overflows 200. Rotation
      // swaps the group axis onto that shorter side.
      expect(
        data.calculateGroupsX(300),
        [7.5, 102.5, 197.5],
      );
      expect(
        data.calculateGroupsX(200),
        [7.5, 102.5, 197.5],
      );
      expect(
        data.copyWith(alignment: BarChartAlignment.end).calculateGroupsX(200),
        [2.5, 97.5, 192.5],
      );
      expect(
        data
            .copyWith(alignment: BarChartAlignment.center)
            .calculateGroupsX(200),
        [5, 100, 195],
      );
    });

    test('keeps groupsSpace for vertically stacked rods on a short axis', () {
      final data = BarChartData(
        alignment: BarChartAlignment.start,
        groupsSpace: 40,
        barGroups: [
          for (var i = 0; i < 2; i++)
            BarChartGroupData(
              x: i,
              groupVertically: true,
              barRods: [
                BarChartRodData(toY: 4, width: 10),
                BarChartRodData(toY: 6, width: 12),
              ],
            ),
        ],
      );

      // Group width is the widest rod (12). 12 * 2 + 40 = 64 > 50.
      expect(data.calculateGroupsX(50), [6, 58]);
    });

    test('still spaces side-by-side rods evenly when groupsSpace overflows',
        () {
      final data = BarChartData(
        alignment: BarChartAlignment.start,
        groupsSpace: 80,
        barGroups: [
          for (var i = 0; i < 3; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: 5, width: 10),
                BarChartRodData(toY: 8, width: 10),
              ],
            ),
        ],
      );

      // Group width is 24. Bars fit in 140 (72 <= 140) but groupsSpace does
      // not, so side-by-side groups keep the even distribution.
      expect(data.calculateGroupsX(140), [29, 70, 111]);
    });

    test('spaces single-rod groups evenly when the rods themselves overflow',
        () {
      final data = BarChartData(
        alignment: BarChartAlignment.start,
        groupsSpace: 10,
        barGroups: [
          for (var i = 0; i < 3; i++)
            BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: 5, width: 30)],
            ),
        ],
      );

      expect(data.calculateGroupsX(50), [5, 25, 45]);
    });

    test('Throws Assertion error when barGroups is empty', () {
      expect(
        () => MockData.barChartData1
            .copyWith(barGroups: []).calculateGroupsX(100),
        throwsAssertionError,
      );
    });
  });
}
