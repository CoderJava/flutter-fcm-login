import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  var isLogin = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var sharedPreferences = await SharedPreferences.getInstance();
      isLogin = sharedPreferences.getBool('isLogin') ?? false;
      if (isLogin) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: !isLogin ? LoginPage() : HomePage(),
    );
  }
}

Future<dynamic> onBackgroundMessageHandler(Map<String, dynamic> message) async {
  debugPrint('onBackgroundMessageHandler');
  var sharedPreferences = await SharedPreferences.getInstance();
  var isLogin = sharedPreferences.getBool('isLogin') ?? false;
  if (isLogin) {
    var title = '-';
    var content = '-';
    if (Platform.isIOS) {
      title = message['title'];
      content = message['content'];
    } else {
      title = message['data']['title'];
      content = message['data']['content'];
    }
    _showLocalNotification(title, content);
  }
  return true;
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final scaffoldState = GlobalKey<ScaffoldState>();
  final formState = GlobalKey<FormState>();
  final controllerEmail = TextEditingController();
  final controllerPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formState,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headline6,
                ),
                Text(
                  'Sign to continue',
                  style: Theme.of(context).textTheme.caption,
                ),
                SizedBox(height: 42),
                TextFormField(
                  controller: controllerEmail,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'EMAIL',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    return value.isEmpty ? 'Enter an email' : null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: controllerPassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'PASSWORD',
                  ),
                  validator: (value) {
                    return value.isEmpty ? 'Enter a password' : null;
                  },
                  obscureText: true,
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: RaisedButton(
                    onPressed: () async {
                      if (formState.currentState.validate()) {
                        var email = controllerEmail.text.trim();
                        var password = controllerPassword.text.trim();
                        if (email == 'admin' && password == 'admin') {
                          var sharedPreferences = await SharedPreferences.getInstance();
                          await sharedPreferences.setBool('isLogin', true);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                        } else {
                          scaffoldState.currentState.showSnackBar(SnackBar(content: Text('Login failed')));
                        }
                      }
                    },
                    child: Text('LOGIN'),
                    color: Colors.blue,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final firebaseMessaging = FirebaseMessaging();
  var tokenFcm = '-';

  @override
  void initState() {
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _getDataFcm(message);
      },
      onBackgroundMessage: onBackgroundMessageHandler,
      onResume: (Map<String, dynamic> message) async {
        _getDataFcm(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        _getDataFcm(message);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                  child: Text('GET TOKEN'),
                  onPressed: () {
                    firebaseMessaging.requestNotificationPermissions(
                      const IosNotificationSettings(),
                    );
                    firebaseMessaging.onIosSettingsRegistered.listen((event) {
                      debugPrint('IOS settings registered');
                    });
                    firebaseMessaging.getToken().then((value) => setState(() {
                          tokenFcm = value;
                          debugPrint('tokenFcm: $tokenFcm');
                        }));
                  },
                ),
                SizedBox(width: 16),
                RaisedButton(
                  child: Text('LOGOUT'),
                  onPressed: () async {
                    var sharedPreferences = await SharedPreferences.getInstance();
                    sharedPreferences.remove('isLogin');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                ),
              ],
            ),
            Text(tokenFcm),
          ],
        ),
      ),
    );
  }
}

void _getDataFcm(Map<String, dynamic> message) {
  var title = '-';
  var content = '-';
  if (Platform.isIOS) {
    title = message['title'];
    content = message['content'];
  } else {
    title = message['data']['title'];
    content = message['data']['content'];
  }
  _showLocalNotification(title, content);
}

void _showLocalNotification(String title, String content) {
  var initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
    initializationSettingsAndroid,
    initializationSettingsIOS,
  );
  var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'test channel id',
    'test channel name',
    'test channel description',
    importance: Importance.Max,
    priority: Priority.High,
  );
  var iosPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iosPlatformChannelSpecifics);
  flutterLocalNotificationsPlugin.show(1, title, content, platformChannelSpecifics);
}
