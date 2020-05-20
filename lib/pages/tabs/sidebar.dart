// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:better_som_today/studies/som/colors.dart';

class TabWithSidebar extends StatelessWidget {
  const TabWithSidebar({
    Key key,
    @required this.mainView,
    @required this.sidebarItems,
  }) : super(key: key);

  final Widget mainView;
  final List<Widget> sidebarItems;

  @override
  Widget build(BuildContext context) {
      return SingleChildScrollView(child: mainView);
  }
}

class SidebarItem extends StatelessWidget {
  const SidebarItem({Key key, this.value, this.title}) : super(key: key);

  final String value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: textTheme.bodyText2.copyWith(
            fontSize: 16,
            color: RallyColors.gray60,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.bodyText1.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Container(
          color: RallyColors.primaryBackground,
          height: 1,
        ),
      ],
    );
  }
}
