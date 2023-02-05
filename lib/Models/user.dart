import 'package:firebase_database/firebase_database.dart';

class User {
  String? fullName;
  String? email;
  String? phoneNumber;
  String? id;

  User({this.fullName, this.email, this.phoneNumber, this.id});

  User.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    fullName = snapshot.value['fullname'];
    email = snapshot.value['email'];
    phoneNumber = snapshot.value['phone'];
  }
}
