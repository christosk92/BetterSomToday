// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:better_som_today/layout/text_scale.dart';
import 'package:better_som_today/studies/som/colors.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/studies/som/school.dart';

/// A page that shows a status overview.
class OverviewView extends StatefulWidget {
  @override
  _OverviewViewState createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _OverviewGrid(spacing: 12),
          ],
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({Key key, @required this.spacing}) : super(key: key);

  final double spacing;

  @override
  Widget build(BuildContext context) {
    final quickRoosterDataList = DummyDataService.getQuickRoosterItem(context);
    final quickGradeDataList = DummyDataService.getQuickGradeItem(context);

    return LayoutBuilder(builder: (context, constraints) {

      // Only display multiple columns when the constraints allow it and we
      // have a regular text scale factor.
      final hasMultipleColumns = false;
      final boxWidth = hasMultipleColumns
          ? constraints.maxWidth / 2 - spacing / 2
          : double.infinity;

      return Wrap(
        runSpacing: spacing,
        children: [
          Container(
            width: boxWidth,
            child: _QuickRoosterView(
              title: 'VOLGENDE LESSEN',
              subtitle: currentDate(),
              quickItems:
                  buildQuickRoosterListView(quickRoosterDataList, context),
              order: 1,
            ),
          ),
          if (hasMultipleColumns) SizedBox(width: spacing),
          Container(
            width: boxWidth,
            child: _QuickRoosterView(
              title: 'LAATSTE CIJFERS',
              subtitle: averageLatestGrades(quickGradeDataList),
              quickItems: buildQuickGradeListView(quickGradeDataList, context),
              order: 2,
            ),
          )
        ],
      );
    });
  }
}

class _QuickRoosterView extends StatelessWidget {
  const _QuickRoosterView({
    this.title,
    this.subtitle,
    this.quickItems,
    this.buttonSemanticsLabel,
    this.order,
  });

  final String title;
  final String buttonSemanticsLabel;
  final String subtitle;
  final List<QuickItemView> quickItems;
  final double order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: Container(
        color: RallyColors.cardBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    child: Text(title),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodyText1.copyWith(
                        fontSize: 44 / reducedTextScale(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...quickItems.sublist(0, math.min(quickItems.length, 3)),
            FlatButton(
              child: Text(
                'ZIE ALLES',
                semanticsLabel: buttonSemanticsLabel,
              ),
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<FullRoosterPage>(
                    builder: (context) => FullRoosterPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
