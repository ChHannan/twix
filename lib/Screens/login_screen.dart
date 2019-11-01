import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moor_flutter/moor_flutter.dart' hide Column;
import 'package:progress_button/progress_button.dart';
import 'package:provider/provider.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:twix/Screens/home_screen.dart';

import 'package:twix/Widgets/custom_scroll_behaviour.dart';
import 'package:uuid/uuid.dart';
import 'package:twix/Database/database.dart';
import 'package:twix/Api/api.dart';


class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginState();
}

class LoginState extends State<Login> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String registrationId;

  @override
  void initState() {
    super.initState();
    _firebaseAddDevice();
  }

  void _firebaseAddDevice() async {
    registrationId = await _firebaseMessaging.getToken();
  }

  ButtonState showSpinner = ButtonState.normal;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<TwixDB>(context);
    return Scaffold(
      body: Builder(
        builder: (context) =>
            SafeArea(
              child: ScrollConfiguration(
                behavior: CustomScrollBehaviour(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.20,
                        child: Center(
                          child: Hero(
                            tag: 'avatar',
                            child: Image(
                              image: AssetImage(
                                'images/splash_image.png',
                              ),
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Text(
                                'Welcome!',
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Text(
                                'Sign up to continue...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.35,
                        child: Column(
                          children: <Widget>[
                            _buildTextField('Name', nameController, false),
                            _buildTextField('Email', emailController, false),
                            _buildTextField(
                                'Password', passwordController, true),
                          ],
                        ),
                      ),
                      Container(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.07,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        margin: EdgeInsets.all(30),
                        child: ProgressButton(
                          buttonState: showSpinner,
                          backgroundColor: Colors.amber,
                          onPressed: () async {
                            if (Connect.getConnection) {
                              if (_validateFields()) {
                                setState(() {
                                  showSpinner = ButtonState.inProgress;
                                });
                                if (await (_actionSignUp(database))) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(),
                                    ),
                                  );
                                }
                              } else {
                                final snackBar = SnackBar(
                                  duration: Duration(milliseconds: 800),
                                  content: Text(
                                      'Please fill the above fields correctly!'),
                                );
                                Scaffold.of(context).showSnackBar(snackBar);
                              }
                            } else {
                              final snackBar = SnackBar(
                                duration: Duration(milliseconds: 800),
                                content: Text(
                                    'You must be connected to the internet to proceed!'),
                              );
                              Scaffold.of(context).showSnackBar(snackBar);
                            }
                          },
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      bool obscureText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
      child: TextField(
        obscureText: obscureText,
        controller: controller,
        textCapitalization: TextCapitalization.values[0],
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }

  Future<bool> _actionSignUp(TwixDB database) async {
    final String id = Uuid().v4();
    final response = await Api.createUser(
        id, nameController.text, emailController.text, passwordController.text);
    final responseToken =
    await Api.getToken(emailController.text, passwordController.text);
    final bool result =
        response.statusCode == 201 && responseToken.statusCode == 200;
    if (result) {
      String authToken = jsonDecode(responseToken.body)['token'];
      await database.userDao.insertUser(
        UserTableCompanion(
          id: Value(id),
          name: Value(nameController.text),
          email: Value(emailController.text),
          password: Value(passwordController.text),
          token: Value(authToken),
        ),
      );
      Api.setAuthToken(authToken);
      Api.createDevice('${nameController.text} Device', registrationId);
    }
    return result;
  }

  bool _validateFields() {
    if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      if (!emailController.text.contains('@')) {
        final snackBar = SnackBar(
          duration: Duration(milliseconds: 800),
          content: Text('Please provide valid email address'),
        );
        Scaffold.of(context).showSnackBar(snackBar);
        return false;
      }
      if (passwordController.text.length < 5) {
        final snackBar = SnackBar(
          duration: Duration(milliseconds: 800),
          content: Text(
            'Password should contains at least five characters',
          ),
        );
        Scaffold.of(context).showSnackBar(snackBar);
        return false;
      }
      return true;
    }
    return false;
  }
}
