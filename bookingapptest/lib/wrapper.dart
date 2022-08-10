
import 'package:bookingapptest/home.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'login.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return const BookingPage();
          } else {
            return const LoginScreen();
          }
        }
      ),
    );
  }
}
