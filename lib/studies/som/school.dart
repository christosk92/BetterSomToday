// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:better_som_today/data/bettersom_options.dart';
import 'package:better_som_today/layout/text_scale.dart';
import 'package:better_som_today/studies/som/colors.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/studies/som/formatters.dart';
import 'package:better_som_today/studies/som/charts/vertical_fraction_bar.dart';
class FullRoosterView extends StatelessWidget {
  const FullRoosterView({
    this.heroLabel,
    this.heroAmount,
    this.wholeAmount,
    this.quickRoosterCards,
  });

  /// The amounts to assign each item.
  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<QuickItemView> quickRoosterCards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: RallyColors.inputBackground,
          ),
          Container(
            color: RallyColors.cardBackground,
            child: Column(
              children: quickRoosterCards,
            ),
          ),
        ],
      );
    });
  }
}

class QuickItemView extends StatelessWidget {
  const QuickItemView({
    @required this.indicatorColor,
    @required this.indicatorFraction,
    @required this.title,
    @required this.subtitle,
    @required this.semanticsLabel,
    @required this.amount,
    @required this.suffix,
  });

  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final String amount;
  final Widget suffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics.fromProperties(
      properties: SemanticsProperties(
        button: true,
        label: semanticsLabel,
      ),
      excludeSemantics: true,
      child: FlatButton(
        onPressed: () {},
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 32 + 60 * (cappedTextScale(context) - 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: VerticalFractionBar(
                      color: indicatorColor,
                      fraction: indicatorFraction,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.bodyText2.copyWith(fontSize: 16),
                            ),
                            Text(
                              subtitle,
                              style: textTheme.bodyText2
                                  .copyWith(color: RallyColors.gray60),
                            ),
                          ],
                        ),
                        Text(
                          amount,
                          style: textTheme.bodyText1.copyWith(
                            fontSize: 20,
                            color: RallyColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: RallyColors.dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}


QuickItemView buildQuickRoosterViewFromAccountData(
  QuickRoosterData model,
  int accountDataIndex,
  BuildContext context,
) {
  return QuickItemView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: model.teacher,
    amount: model.time,
    semanticsLabel: model.name,
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
  );
}

List<QuickItemView> buildQuickRoosterListView(
  List<QuickRoosterData> items,
  BuildContext context,
) {
  return List<QuickItemView>.generate(
    items.length,
    (i) => buildQuickRoosterViewFromAccountData(items[i], i, context),
  );
}

QuickItemView buildQuickGradeViewFromAccountData(
  CijferData model,
  int accountDataIndex,
  BuildContext context,
) {
  return QuickItemView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    amount: model.grade.toString(),
    subtitle: model.date,
    semanticsLabel: model.name,
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
  );
}

List<QuickItemView> buildQuickGradeListView(
  List<CijferData> items,
  BuildContext context,
) {
  return List<QuickItemView>.generate(
    items.length,
    (i) => buildQuickGradeViewFromAccountData(items[i], i, context),
  );
}


class FullRoosterPage extends StatelessWidget {
  final List<DetailedEventData> items =
      DummyDataService.getDetailedEventItems();

  @override
  Widget build(BuildContext context) {
    final isDesktop = false;

    return ApplyTextOptions(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            'test',
            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 18),
          ),
        ),
        body: Column(
          children: [

            Expanded(
              child: Padding(
                padding: isDesktop ? const EdgeInsets.all(40) : EdgeInsets.zero,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (DetailedEventData detailedEventData in items)
                      _DetailedEventCard(
                        title: detailedEventData.title,
                        date: detailedEventData.date,
                        amount: detailedEventData.amount,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedEventCard extends StatelessWidget {
  const _DetailedEventCard({
    @required this.title,
    @required this.date,
    @required this.amount,
  });

  final String title;
  final DateTime date;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final isDesktop = false;
    return FlatButton(
      onPressed: () {},
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _EventTitle(title: title),
                      ),
                      _EventDate(date: date),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _EventAmount(amount: amount),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EventTitle(title: title),
                          _EventDate(date: date),
                        ],
                      ),
                      _EventAmount(amount: amount),
                    ],
                  ),
          ),
          SizedBox(
            height: 1,
            child: Container(
              color: RallyColors.dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventAmount extends StatelessWidget {
  const _EventAmount({Key key, @required this.amount}) : super(key: key);

  final double amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      usdWithSignFormat(context).format(amount),
      style: textTheme.bodyText1.copyWith(
        fontSize: 20,
        color: RallyColors.gray,
      ),
    );
  }
}

class _EventDate extends StatelessWidget {
  const _EventDate({Key key, @required this.date}) : super(key: key);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      shortDateFormat(context).format(date),
      semanticsLabel: longDateFormat(context).format(date),
      style: textTheme.bodyText2.copyWith(color: RallyColors.gray60),
    );
  }
}

class _EventTitle extends StatelessWidget {
  const _EventTitle({Key key, @required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.bodyText2.copyWith(fontSize: 16),
    );
  }
}
