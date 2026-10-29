import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<BarChartGroupData> singleRodGroups() {
    return [
      for (var i = 0; i < 3; i++)
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: 5 + i.toDouble(), width: 15)],
        ),
    ];
  }

  Future<List<double>> groupCenters(
    WidgetTester tester, {
    required int rotationQuarterTurns,
    required double groupsSpace,
    required Size size,
    BarChartAlignment alignment = BarChartAlignment.start,
    List<BarChartGroupData>? barGroups,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: BarChart(
                BarChartData(
                  alignment: alignment,
                  rotationQuarterTurns: rotationQuarterTurns,
                  groupsSpace: groupsSpace,
                  maxY: 10,
                  minY: 0,
                  barGroups: barGroups ?? singleRodGroups(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barTouchData: const BarTouchData(
                    handleBuiltInTouches: false,
                  ),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final render = tester.renderObject<RenderBarChart>(
      find.byType(BarChartLeaf),
    );
    final centers = <int, double>{};
    for (var y = 0.0; y < render.size.height; y += 2) {
      for (var x = 0.0; x < render.size.width; x += 1) {
        final spot = render.getResponseAtLocation(Offset(x, y)).spot;
        if (spot == null) {
          continue;
        }
        centers.putIfAbsent(spot.touchedBarGroupIndex, () => spot.offset.dx);
      }
    }
    final indexes = centers.keys.toList()..sort();
    return [for (final index in indexes) centers[index]!];
  }

  testWidgets(
    'groupsSpace matches with and without rotation for single-rod groups',
    (tester) async {
      // https://github.com/imaNNeo/fl_chart/issues/2095
      const size = Size(300, 200);
      const groupsSpace = 50.0;
      final upright = await groupCenters(
        tester,
        rotationQuarterTurns: 0,
        groupsSpace: groupsSpace,
        size: size,
      );
      final rotated = await groupCenters(
        tester,
        rotationQuarterTurns: 1,
        groupsSpace: groupsSpace,
        size: size,
      );

      expect(upright, [7.5, 72.5, 137.5]);
      expect(rotated, upright);

      for (final alignment in [
        BarChartAlignment.end,
        BarChartAlignment.center,
      ]) {
        final uprightAligned = await groupCenters(
          tester,
          rotationQuarterTurns: 0,
          groupsSpace: groupsSpace,
          size: size,
          alignment: alignment,
        );
        final rotatedAligned = await groupCenters(
          tester,
          rotationQuarterTurns: 1,
          groupsSpace: groupsSpace,
          size: size,
          alignment: alignment,
        );
        expect(
          rotatedAligned[1] - rotatedAligned[0],
          uprightAligned[1] - uprightAligned[0],
        );
        expect(rotatedAligned[1] - rotatedAligned[0], 15 + groupsSpace);
      }
    },
  );

  testWidgets(
    'groupsSpace is kept when rotation makes the group axis shorter',
    (tester) async {
      const size = Size(300, 140);
      const groupsSpace = 80.0;
      final upright = await groupCenters(
        tester,
        rotationQuarterTurns: 0,
        groupsSpace: groupsSpace,
        size: size,
      );
      final rotated = await groupCenters(
        tester,
        rotationQuarterTurns: 1,
        groupsSpace: groupsSpace,
        size: size,
      );

      expect(upright, [7.5, 102.5, 197.5]);
      // The third group is past the rotated axis (width 140) and clipped.
      // The visible gap is still the rod width plus groupsSpace.
      expect(rotated, [7.5, 102.5]);
      expect(rotated[1] - rotated[0], upright[1] - upright[0]);
    },
  );

  testWidgets(
    'side-by-side groups still spread evenly when rotation overflows',
    (tester) async {
      final groups = [
        for (var i = 0; i < 3; i++)
          BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(toY: 5, width: 10),
              BarChartRodData(toY: 8, width: 10),
            ],
          ),
      ];
      final centers = await groupCenters(
        tester,
        rotationQuarterTurns: 1,
        groupsSpace: 80,
        size: const Size(300, 140),
        barGroups: groups,
      );

      // Group centers are 29, 70 and 111. Touch hits resolve to a rod, so
      // compare the gap between groups rather than the raw rod centers.
      expect(centers.length, 3);
      expect(centers[1] - centers[0], 41);
      expect(centers[2] - centers[1], 41);
    },
  );

  for (final alignment in BarChartAlignment.values) {
    testWidgets(
      'alignment $alignment stays consistent for multi-rod groups',
      (tester) async {
        final groups = [
          for (var i = 0; i < 3; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: 4, width: 8),
                BarChartRodData(toY: 6, width: 8),
              ],
            ),
        ];
        final upright = await groupCenters(
          tester,
          rotationQuarterTurns: 0,
          groupsSpace: 12,
          size: const Size(300, 200),
          alignment: alignment,
          barGroups: groups,
        );
        final rotated = await groupCenters(
          tester,
          rotationQuarterTurns: 1,
          groupsSpace: 12,
          size: const Size(300, 200),
          alignment: alignment,
          barGroups: groups,
        );

        expect(upright.length, 3);
        expect(rotated.length, 3);
        if (alignment == BarChartAlignment.start ||
            alignment == BarChartAlignment.end ||
            alignment == BarChartAlignment.center) {
          expect(upright[1] - upright[0], 20 + 12);
          expect(rotated[1] - rotated[0], upright[1] - upright[0]);
        }
      },
    );
  }
}
