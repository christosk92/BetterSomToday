// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/data/bettersom_options.dart';
import 'package:better_som_today/layout/image_placeholder.dart';
import 'package:better_som_today/app.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'dart:async';

const homeAssets = [
  'assets/logo/somtoday.png',
];
bool firstTime = true;
String dropdownValue;
String dropDownUUID;

class LoginPage extends StatefulWidget {
  LoginPage({this.storage});
  final UserStorage storage;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class SchoolSearch extends SearchDelegate<String> {
  SchoolSearch({this.schoolData});
  final List<SchoolListItem> schoolData;
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = "";
          })
    ];
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ),
        onPressed: () {});
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
  }
  TextStyle posRes =
          TextStyle(color: Colors.white),
      negRes = TextStyle(color: Colors.grey);
  String search;

  TextSpan searchMatch(String match) {
    if (search == null || search == "")
      return TextSpan(text: match, style: negRes);
    var refinedMatch = match.toLowerCase();
    var refinedSearch = search.toLowerCase();
    if (refinedMatch.contains(refinedSearch)) {
      if (refinedMatch.substring(0, refinedSearch.length) == refinedSearch) {
        return TextSpan(
          style: posRes,
          text: match.substring(0, refinedSearch.length),
          children: [
            searchMatch(
              match.substring(
                refinedSearch.length,
              ),
            ),
          ],
        );
      } else if (refinedMatch.length == refinedSearch.length) {
        return TextSpan(text: match, style: posRes);
      } else {
        return TextSpan(
          style: negRes,
          text: match.substring(
            0,
            refinedMatch.indexOf(refinedSearch),
          ),
          children: [
            searchMatch(
              match.substring(
                refinedMatch.indexOf(refinedSearch),
              ),
            ),
          ],
        );
      }
    } else if (!refinedMatch.contains(refinedSearch)) {
      return TextSpan(text: match, style: negRes);
    }
    return TextSpan(
      text: match.substring(0, refinedMatch.indexOf(refinedSearch)),
      style: negRes,
      children: [
        searchMatch(match.substring(refinedMatch.indexOf(refinedSearch)))
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = schoolData.where(
        (element) => element.naam.toLowerCase().contains(query.toLowerCase()));
    search = query.toLowerCase();
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
          title: RichText(
              text: searchMatch(
        suggestionList.toList()[index].naam,
      ))),
      itemCount: suggestionList.length,
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    Future<List<SchoolListItem>> schools() async {
      widget.storage.readUserdata().then((List<String> value) async {
        if (value != null) {
          await _login(context, value[0], value[1], value[2]);
        }
      });
      Dio dio = new Dio();
      dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);
      final forcedResponse = await dio.get(
          'https://servers.somtoday.nl/organisaties.json',
          options: buildCacheOptions(Duration(days: 7)));
      var instellingen = forcedResponse.data[0]["instellingen"];
      List<SchoolListItem> _data = new List<SchoolListItem>();
      instellingen.forEach((k) =>
          _data.add(new SchoolListItem(uuid: k["uuid"], naam: k["naam"])));
      _data.sort((a, b) {
        return a.naam.toLowerCase().compareTo(b.naam.toLowerCase());
      });
      return _data;
    }

    return ApplyTextOptions(
        child: Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<SchoolListItem>>(
            future: schools(),
            builder: (BuildContext context,
                AsyncSnapshot<List<SchoolListItem>> snapshot) {
              List<Widget> children;
              if (snapshot.hasData) {
                if (firstTime) {
                  dropdownValue = snapshot.data.first.naam;
                  dropDownUUID = snapshot.data.first.uuid;
                }
                firstTime = false;
                children = <Widget>[
                  ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      const _SmallLogo(),
                      new Container(
                          height: 50,
                          child: Theme(
                              data: Theme.of(context).copyWith(
                                  canvasColor: Theme.of(context).primaryColor),
                              child: Center(
                                  child: TextField(
                                onChanged: (text) {
                                  print("changed " + text);
                                  showSearch(
                                      context: context,
                                      query: _controller.text,
                                      delegate: SchoolSearch(
                                          schoolData: snapshot.data));
                                },
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: "Search for school",
                                  suffixIcon: IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.search),
                                  ),
                                ),
                              )))),
                      _UsernameInput(
                        usernameController: _usernameController,
                      ),
                      const SizedBox(height: 20),
                      _PasswordInput(
                        passwordController: _passwordController,
                      ),
                      _LoginButton(
                        onTap: () {
                          _login(context, _usernameController.text,
                              _passwordController.text, dropDownUUID);
                        },
                      ),
                    ],
                  ),
                ];
              } else {
                children = <Widget>[
                  SizedBox(
                    child: CircularProgressIndicator(),
                    width: 60,
                    height: 60,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Awaiting result...'),
                  )
                ];
              }
              return Container(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                      // new line
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: children,
                  )));
            }),
      ),
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context, String usernameD, String passwordD,
      String uuidD) async {
    try {
      String username = "119371@mymerewade.nl";
      String password = "christos,2002";
      String uuid = "960222bf-836b-4f43-aa0c-67243cab2d50";
      var res = await tryAuthenticate(
          uuid.trim() + "\\${username.trim()}", "${password.trim()}");
      if (!res.containsKey("error")) {
        widget.storage.writeUserData(username, password, uuid);
        Navigator.of(context).pushNamed(SomApp.homeRoute);
      } else {
        await _showDialog("There was a problem",
            "Please check if your username and password are correct.", "RETRY");
      }
    } catch (e) {
      await _showDialog("There was a problem", e.message, "RETRY");
    }
  }

  Future<void> _showDialog(
      String title, String message, String buttonText) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text(message)],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(buttonText),
              onPressed: () {
                widget.storage.readUserdata().then((List<String> value) async {
                  if (value != null) {
                    await _login(context, value[0], value[1], value[2]);
                  }
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class _SmallLogo extends StatelessWidget {
  const _SmallLogo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 175,
        child: ExcludeSemantics(
          child: FadeInImagePlaceholder(
            image: AssetImage('assets/logo/somtoday.png'),
            placeholder: SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput({
    Key key,
    this.maxWidth,
    this.usernameController,
  }) : super(key: key);

  final double maxWidth;
  final TextEditingController usernameController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: TextField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: 'GEBRUIKERSNAAM',
          ),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    Key key,
    this.maxWidth,
    this.passwordController,
  }) : super(key: key);

  final double maxWidth;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'WACHTWOORD',
          ),
          obscureText: true,
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    Key key,
    @required this.onTap,
    this.maxWidth,
  }) : super(key: key);

  final double maxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      width: MediaQuery.of(context).size.width * 0.62,
      child: RaisedButton(
          child: const Text(
            "INLOGGGEN",
            style: TextStyle(
                color: Color.fromRGBO(40, 48, 52, 1),
                fontFamily: 'RadikalMedium',
                fontSize: 14),
          ),
          color: Colors.white,
          elevation: 4.0,
          onPressed: onTap),
    );
  }
}
