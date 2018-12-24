import 'dart:async';
import 'dart:convert';

import 'package:LoginUI/Routes.dart';
import 'package:LoginUI/main.dart';
import 'package:LoginUI/model/UserProfile.dart';
import 'package:LoginUI/network/Github.dart';
import 'package:LoginUI/ui/base/BaseStatefulState.dart';
import 'package:LoginUI/ui/dashboard/DashboardPage.dart';
import 'package:LoginUI/ui/dashboard/DrawerHeaderLayout.dart';
import 'package:LoginUI/ui/login/LoginPage.dart';
import 'package:LoginUI/ui/repolist/RepoListPage.dart';
import 'package:LoginUI/ui/searchusers/UserSearchPage.dart';
import 'package:LoginUI/utils/SharedPrefs.dart';
import 'package:flutter/material.dart';
import 'package:http/src/response.dart';

class DashboardPageState extends BaseStatefulState<DashboardPage> {
  Widget appBarTitle = new Text("Your Dashboard");
  UserProfile currentUserProfile;
  String accessToken;
  StreamSubscription<UserProfile> subscriptionMyProfile;
  StreamSubscription<Response> subScriptionApiUserProfile;

  @override
  void initState() {
    super.initState();
    SharedPrefs().getToken().then((token) {
      accessToken = token;
      getMyUserProfile();
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscriptionMyProfile?.cancel();
    subScriptionApiUserProfile?.cancel();
  }

  toolbarAndroid() {
    return new AppBar(
      centerTitle: false,
      title: appBarTitle,
    );
  }

  getDrawer() {
    return new Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the Drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          new DrawerHeaderLayout(userProfile: currentUserProfile),
          ListTile(
            title: Text('User Search'),
            onTap: () {
              navigateTo(Routes.dashboardUserSearch);
            },
          ),
          ListTile(
            title: Text('My Repo List'),
            onTap: () {
              navigateTo(Routes.dashboardRepoList);
            },
          ),
          ListTile(
            title: Text('Logout!'),
            onTap: () {
              logoutUser();
            },
          )
        ],
      ),
    );
  }

  void navigateTo(String  name) {
    Application.router.navigateTo(context, name);
  }

  void logoutUser() {
    SharedPrefs().clear().then((onClear) {
      Application.router.navigateTo(context, Routes.login,clearStack: true);
    });
  }

  @override
  Widget prepareWidget(BuildContext context) {
    return new Scaffold(
        key: scaffoldKey,
        drawer: getDrawer(),
        body: new Stack(
          children: <Widget>[toolbarAndroid()],
        ));
  }

  void getMyUserProfile() {

    var stream = SharedPrefs().getCurrentUserProfile().asStream();
    subscriptionMyProfile = stream.listen((profile) {
      if (profile != null) {
        this.setState(() {
          currentUserProfile = profile;
        });
      }else{
        getApiUserProfile();
      }
    });
  }

  void getApiUserProfile() {
    showProgress();
    var getUserProfile =  Github.getMyUserProfile(accessToken).asStream();
   subScriptionApiUserProfile = getUserProfile.listen((response){
      this.setState(() {
        SharedPrefs().saveCurrentUserProfile(response.body);
        getMyUserProfile();
      });
      hideProgress();
    });
  }
}
