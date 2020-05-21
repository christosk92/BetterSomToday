// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:better_som_today/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:better_som_today/layout/text_scale.dart';
import 'package:better_som_today/studies/som/colors.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/studies/som/school.dart';
import 'dart:io';

/// A page that shows a status overview.
class OverviewView extends StatefulWidget {
  @override
  _OverviewViewState createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView>
    with AutomaticKeepAliveClientMixin<OverviewView> {
  static bool _wantToKeepAlive = true;
  static bool userInvokedLoading = false;
  @override
  bool get wantKeepAlive => _wantToKeepAlive;
  @override
  void initState() {
    super.initState();
  }

  Future<List<List<QuickItemData>>> quickItemsAsync() async {
    return Future.microtask(() async {
      try {
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('connected');
          }
        } on SocketException catch (_) {
          print('not connected');
          throw Exception('INTERNAL_ERROR');
        }
        return await SomDataService.getQuickItemsAsync(context);
      } catch (e) {
        if (e.message.toString() != "INTERNAL_ERROR") {
          keyx.currentState.showDiag("There was a problem", e.toString(), "OK");
        }
      }
      var pseudoItems = new List<List<QuickItemData>>();
      var pseudoError = new List<QuickItemData>();
      pseudoError.add(QuickItemData(name: "ERROR_INTERNET"));
      pseudoItems.add(pseudoError);
      return pseudoItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double spacing = 12;
    final int maxItemsOnGrades = 3;
    final int maxItemsOnRooster = 3;
    return RefreshIndicator(
      child: FutureBuilder<List<List<QuickItemData>>>(
          future: quickItemsAsync(),
          builder: (BuildContext context,
              AsyncSnapshot<List<List<QuickItemData>>> snapshot) {
            List<Widget> children;
            if (snapshot.hasData && !userInvokedLoading) {
              if (snapshot.data.length > 1) {
                children = <Widget>[
                  Column(children: [
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, constraints) {
                      // Only display multiple columns when the constraints allow it and we
                      // have a regular text scale factor.
                      final hasMultipleColumns = false;
                      final boxWidth = hasMultipleColumns
                          ? constraints.maxWidth / 2 - spacing / 2
                          : double.infinity;
                      return Wrap(
                        runSpacing: spacing,
                        children: [
                          if (snapshot.data[0].length > 0)
                            Container(
                              width: boxWidth,
                              child: _QuickRoosterView(
                                title: 'VOLGENDE LESSEN',
                                subtitle: currentDate(),
                                quickItems: buildQuickRoosterListView(
                                    snapshot.data[0], context),
                                order: 1,
                                maxItems: maxItemsOnRooster,
                              ),
                            ),
                          if (snapshot.data[0].length == 0)
                            Container(
                                width: boxWidth,
                                child: EmptyView(
                                    title: "VOLGENDE LESSEN",
                                    subtitle: "Geen lessen",
                                    order: 2)),
                          if (hasMultipleColumns) SizedBox(width: spacing),
                          if (snapshot.data[1].length > 0)
                            Container(
                              width: boxWidth,
                              child: _QuickRoosterView(
                                title: 'LAATSTE CIJFERS',
                                subtitle: averageLatestGrades(
                                    snapshot.data[1], maxItemsOnGrades),
                                quickItems: buildQuickGradeListView(
                                    snapshot.data[1], context),
                                order: 2,
                                maxItems: maxItemsOnGrades,
                              ),
                            ),
                          if (snapshot.data[1].length == 0)
                            Container(
                                width: boxWidth,
                                child: EmptyView(
                                    title: "LAATSTE CIJFERS",
                                    subtitle: "Geen cijfers",
                                    order: 2))
                        ],
                      );
                    })
                  ])
                ];
              } else {
                children = <Widget>[
                  Icon(Icons.error_outline, size: 45, color: Color(0xFFFFFFFF)),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Something went wrong.'),
                  ),
                  RaisedButton(
                    onPressed: () {
                      setState(() {
                        SomDataService.setCacheNull();
                        userInvokedLoading = true;
                      });
                    },
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      child: const Text('Retry',
                          style: TextStyle(letterSpacing: 1.0, height: 1.0)),
                    ),
                  ),
                ];
              }
            } else {
              userInvokedLoading = false;
              children = <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      SizedBox(
                        child: CircularProgressIndicator(),
                        width: 60,
                        height: 60,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Awaiting result...'),
                      )
                    ]))
              ];
            }
            return ListView(
              // new line
              physics: const AlwaysScrollableScrollPhysics(),
              children: children,
            );
          }),
      onRefresh: _getData,
    );
  }

  Future<void> _getData() async {
    setState(() {
      SomDataService.setCacheNull();
    });
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    this.title,
    this.subtitle,
    this.order,
  });

  final String title;
  final String subtitle;
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
          ],
        ),
      ),
    );
  }
}

class _QuickRoosterView extends StatelessWidget {
  const _QuickRoosterView(
      {this.title,
      this.subtitle,
      this.quickItems,
      this.buttonSemanticsLabel,
      this.order,
      this.maxItems});
  final int maxItems;
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
            ...quickItems.sublist(0, math.min(quickItems.length, maxItems)),
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
