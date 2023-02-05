// ignore_for_file: use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber/screens/loginPage.dart';
import 'package:uber/screens/mainPage.dart';

import '../brand_colors.dart';
import '../widgets/ProgressDialog.dart';
import '../widgets/taxiButton.dart';

class RegistrationPage extends StatelessWidget {
  static const String id = "registration";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  var fullNameController = TextEditingController();
  var emailController = TextEditingController();
  var phoneNumberController = TextEditingController();
  var passwordController = TextEditingController();

  void showSnackbar(String title, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 14, fontFamily: "bolt-regular", color: Colors.black87),
      ),
      backgroundColor: Colors.yellow[50],
      elevation: 20,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void registerUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const ProgressDialog(status: "Regisering you..."));

    final FirebaseUser user = (await _auth
            .createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    )
            .catchError((err) {
      Navigator.pop(context);
      //Check error and display message
      PlatformException thisErr = err;
      showSnackbar(thisErr.message.toString(), context);
    }))
        .user;
    print("User added");
    //check if Registeration is successful
    if (user != null) {
      DatabaseReference newUser =
          FirebaseDatabase.instance.reference().child('users/${user.uid}');
      Map userMap = {
        "fullname": fullNameController.text,
        "email": emailController.text,
        "phone": phoneNumberController.text
      };
      newUser.set(userMap);
      Navigator.pop(context);
      //Go to MainPage
      Navigator.pushNamedAndRemoveUntil(context, LoginPage.id, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 70,
              ),
              const Image(
                alignment: Alignment.center,
                height: 150,
                width: 150,
                fit: BoxFit.contain,
                image: AssetImage("assets/images/logo.png"),
              ),
              const SizedBox(
                height: 40,
              ),
              const Text(
                "Create a Rider\'s Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: "bolt-semibold", fontSize: 25),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    TextField(
                      controller: fullNameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: "Full name",
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: "Email Address",
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: "Phone number",
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    TaxiButton(
                      color: BrandColors.colorAccentPurple,
                      title: "Register",
                      onPressed: () async {
                        // check network avaibility
                        var connectivityresult =
                            await Connectivity().checkConnectivity();
                        if (connectivityresult != ConnectivityResult.mobile &&
                            connectivityresult != ConnectivityResult.wifi) {
                          showSnackbar("No internet connectivity", context);
                          return;
                        }
                        if (fullNameController.text.length < 3) {
                          showSnackbar(
                              "Your name shoud be more than 2 characters",
                              context);
                          return;
                        }

                        if (phoneNumberController.text.length < 10) {
                          showSnackbar(
                              "Your phone number shoud be more than 9 characters",
                              context);
                          return;
                        }

                        if (!emailController.text.contains("@")) {
                          showSnackbar("Your email is invalid", context);
                          return;
                        }

                        if (passwordController.text.length < 8) {
                          showSnackbar("Your password is too short", context);
                          return;
                        }
                        registerUser(context);
                      },
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, LoginPage.id, (route) => false),
                child: const Text("have a Rider\'s account? Login",
                    style:
                        TextStyle(fontFamily: 'bolt-semibold', fontSize: 15)),
              )
            ],
          ),
        ),
      ),
    );
    ;
  }
}
