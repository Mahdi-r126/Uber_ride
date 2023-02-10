import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber/Models/addressModels.dart';
import 'package:uber/Models/directionDetails.dart';
import 'package:uber/helper/requestHelper.dart';
import 'package:uber/providers/appdata.dart';

import '../GlobalVar.dart';
import '../Models/user.dart';

class HelperMethods {
  static Future<String> findAddress(Position position, context) async {
    String placeAddress = "";
    String APIKey = "a454a37e47a41681dd1e279315477e1f";
    String street;
    String county;
    String region;
    var connectivityresult = await Connectivity().checkConnectivity();
    if (connectivityresult != ConnectivityResult.mobile &&
        connectivityresult != ConnectivityResult.wifi) {
      return placeAddress;
    }
    String url =
        // "http://api.positionstack.com/v1/reverse?access_key=${APIKey}&query=${position.latitude}, ${position.longitude}";
        "https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json";
    var response = await RequewstHelper.getRequset(url);
    if (response != "failed") {
      // street = response['data'][0]['street'];
      // county = response['data'][0]['county'];
      // region = response['data'][0]['region'];
      // if (street == null) {
      //   placeAddress = "$county,$region";
      // } else {
      //   placeAddress = "$street,$county,$region";
      // }
      placeAddress = response['display_name'];
      Address address = Address();
      address.lat = position.latitude;
      address.long = position.longitude;
      address.placeAddress = placeAddress;

      Provider.of<AppData>(context, listen: false).updatePickupAddress(address);
    }
    return placeAddress;
  }

  static Future<DirectionDetails?> getDirectionDetails(
      LatLng startPosition, LatLng endPosition) async {
    String url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=5b3ce3597851110001cf6248c4e8a8c9e2954ec8914d787627b2cdef&start=${startPosition.longitude},${startPosition.latitude}&end=${endPosition.longitude},${endPosition.latitude}";
    var response = await RequewstHelper.getRequset(url);

    if (response == 'failed') {
      return null;
    }
    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.distance =
        response['features'][0]['properties']['segments'][0]['distance'];
    directionDetails.duration =
        response['features'][0]['properties']['segments'][0]['duration'];
    directionDetails.points =
        response['features'][0]['geometry']['coordinates'];

    return directionDetails;
  }

  static int calculateMoney(DirectionDetails details) {
    double baseMoney = 4;
    double distance = (details.distance! / 1000) * 0.7;
    double duration = (details.duration! / 60) * 0.3;
    double totalMoney = baseMoney + distance + duration;
    return totalMoney.round();
  }

  static int calculateDistance(DirectionDetails details) {
    double distance = details.distance! / 1000;
    return distance.round();
  }

  static String replaceFarsiNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], farsi[i]);
    }

    return input;
  }

  static String splitDisplayName(String name) {
    if (name != null) {
      final split = name.split(',');
      final Map<int, String> values = {
        for (int i = 0; i < split.length; i++) i: split[i]
      };

      return values[0].toString() +
          "،" +
          values[1].toString() +
          "،" +
          values[2].toString();
    } else {
      return "";
    }
  }

  static void getCurrentUser() async {
    currentFirebaseUser =
        await FirebaseAuth.instance.currentUser();

    String userId = currentFirebaseUser.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userId');
    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = User.fromSnapshot(snapshot);
        print("+++++My name is ${currentUserInfo.fullName}");
      }
    });
  }

  static double generateRandomNumber(int max) {
    var randoGenerator = Random();
    int randInt = randoGenerator.nextInt(max);
    return randInt.toDouble();
  }
}
