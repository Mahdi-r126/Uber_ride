import 'package:flutter/material.dart';

import '../Models/addressModels.dart';

class AppData extends ChangeNotifier {
  Address pickupAddress = Address();

  Address destinationAddress = Address();

  void updatePickupAddress(Address pickup) {
    pickupAddress = pickup;
    notifyListeners();
  }

  void updateDestinationAddress(Address destination) {
    destinationAddress = destination;
    notifyListeners();
  }
}
