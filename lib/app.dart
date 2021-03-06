// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:better_som_today/studies/som/colors.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/pages/home.dart';
import 'package:better_som_today/pages/login.dart';

final keyx = GlobalKey<HomePageState>(debugLabel: "__RIKEY1__");
class SomApp extends StatelessWidget {
  const SomApp();
  static const String loginRoute = '/Som/login';
  static const String homeRoute = '/Som';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Som',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),

      initialRoute: loginRoute,
      routes: <String, WidgetBuilder>{
        homeRoute: (context) => HomePage(key: keyx),
        loginRoute: (context) => LoginPage(storage: UserStorage()),
      },
    );
  }
}
