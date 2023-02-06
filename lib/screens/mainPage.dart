import 'dart:async';
import 'dart:io' show Platform;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:provider/provider.dart';
import 'package:uber/GlobalVar.dart';
import 'package:uber/Models/directionDetails.dart';
import 'package:uber/Models/nearbyDrivers.dart';
import 'package:uber/brand_colors.dart';
import 'package:uber/helper/fireHelper.dart';
import 'package:uber/helper/helperMethods.dart';
import 'package:uber/list.dart';
import 'package:uber/providers/appdata.dart';
import 'package:uber/screens/searchPage.dart';
import 'package:uber/widgets/ProgressDialog.dart';
import 'package:uber/widgets/Text.dart';
import 'package:uber/widgets/taxiButton.dart';

import '../widgets/Drawer.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  static const String id = "mainpage";

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  double mapBottomPadding = 0;
  double searchHeight = (Platform.isIOS) ? 310 : 300;
  double rideDetailsHeight = 0.0;
  double requestSheet = 0.0;

  bool is1st = true;

  var geolocator = Geolocator();
  late Position currentPosition;

  var latLngCoordinates;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  var directionDetails;

  DirectionDetails? tripDetails;

  late DatabaseReference rideRef;

  bool nearbyDriversKeyLoaded = false;

  void SetCurrentLocation() async {
    Position position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;
    LatLng pos = LatLng(position.latitude, position.longitude);
    print("Lat:" +
        pos.latitude.toString() +
        " , " +
        "Lng:" +
        pos.longitude.toString());
    CameraPosition cp = CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

    // ignore: use_build_context_synchronously
    String address = await HelperMethods.findAddress(position, context);
    print(address);
    startGeofireListener();
  }

  void startGeofireListener() {
    Geofire.initialize("driversAvailable");
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)
        ?.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDrivers nearbyDrivers = NearbyDrivers();
            nearbyDrivers.key = map['key'];
            nearbyDrivers.latitude = map['latitude'];
            nearbyDrivers.longitude = map['longitude'];

            FireHelper.nearbyDriversList.add(nearbyDrivers);

            if (nearbyDriversKeyLoaded) {
              updateDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            NearbyDrivers nearbyDrivers = NearbyDrivers();
            nearbyDrivers.key = map['key'];
            nearbyDrivers.latitude = map['latitude'];
            nearbyDrivers.longitude = map['longitude'];
            FireHelper.updateNearbyLocation(nearbyDrivers);
            updateDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            // All Intial Data is loaded
            nearbyDriversKeyLoaded = true;
            updateDriversOnMap();
            print("Nearby Drivers: ${FireHelper.nearbyDriversList.length}");
            print(map['result']);

            break;
        }
      }
    });
  }

  updateDriversOnMap() {
    setState(() {
      _markers.clear();
    });
    Set<Marker> tempMarker = Set<Marker>();

    for (NearbyDrivers nearbyDrivers in FireHelper.nearbyDriversList) {
      LatLng driverPosition =
          LatLng(nearbyDrivers.latitude, nearbyDrivers.longitude);
      Marker marker = Marker(
          markerId: MarkerId("driver ${nearbyDrivers.key}"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: driverPosition,
          rotation: HelperMethods.generateRandomNumber(360));
      tempMarker.add(marker);
    }
    setState(() {
      _markers = tempMarker;
    });
  }

  void showDetailSheet() async {
    await getDirection();

    setState(() {
      searchHeight = 0.0;
      is1st = false;
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        rideDetailsHeight = 255.0;
        mapBottomPadding = 255.0;
      } else {
        rideDetailsHeight = 245.0;
        mapBottomPadding = 245.0;
      }
    });
  }

  void showRequestSheet() async {
    setState(() {
      rideDetailsHeight = 0.0;
      is1st = true;
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        requestSheet = 280.0;
        mapBottomPadding = 280.0;
      } else {
        requestSheet = 260.0;
        mapBottomPadding = 260.0;
      }
    });
    createRideRequest();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HelperMethods.getCurrentUser();
  }

  void createRideRequest() {
    rideRef = FirebaseDatabase.instance.reference().child('rideRequest').push();
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map pickupMap = {
      'lat': pickup.lat.toString(),
      'long': pickup.long.toString()
    };

    Map destinationMap = {
      'lat': destination.lat.toString(),
      'long': destination.long.toString()
    };

    Map rideMap = {
      'time_created': DateTime.now().toString(),
      'rider_name': currentUserInfo.fullName,
      'rider_phone': currentUserInfo.phoneNumber,
      'pickup_address': pickup.placeAddress,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment-method': 'card',
      'driver_id': 'waiting'
    };
    rideRef.set(rideMap);
    print("request accepted");
  }

  void cancelRide() {
    rideRef.remove();
  }

  void resetApp() {
    setState(() {
      _polylines.clear();
      _markers.clear();
      rideDetailsHeight = 0;
      requestSheet = 0;
      is1st = true;
      SetCurrentLocation();
      searchHeight = (Platform.isIOS) ? 310 : 300;
    });
  }

  static const CameraPosition _kLake = CameraPosition(
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Container(
          width: 250,
          color: Colors.white,
          child: const MainDrawer(),
        ),
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: mapBottomPadding),
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: _kLake,
              polylines: _polylines,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                mapController = controller;
                setState(() {
                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                    mapBottomPadding = 300;
                  } else {
                    mapBottomPadding = 310;
                  }
                });
                SetCurrentLocation();
              },
            ),
            Positioned(
                top: 50,
                right: 20,
                child: Builder(
                  builder: (context) {
                    return Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 1.5)),
                      child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          elevation: 20,
                          child: Icon(
                            (is1st) ? Icons.menu : Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            (is1st)
                                ? Scaffold.of(context).openDrawer()
                                : resetApp();
                          }),
                    );
                  },
                )),

            //SearchSheet
            Positioned(
              bottom: 0.0,
              right: 0.0,
              left: 0.0,
              child: AnimatedSize(
                duration: const Duration(microseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                  height: searchHeight,
                  decoration: BoxDecoration(
                      border: Border.all(color: BrandColors.colorGreen),
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      boxShadow: [
                        const BoxShadow(
                            color: BrandColors.colorGreen,
                            blurRadius: 5,
                            offset: Offset(0.7, 0.7),
                            spreadRadius: 0.5)
                      ]),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PersianTextField(
                            text: "به تاکسینو خوش اومدید!",
                            textSize: 10,
                          ),
                          PersianTextField(
                            text: "کجا میخوای بری؟",
                            textSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          //SearchBox
                          GestureDetector(
                            onTap: () async {
                              var response = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          const SearchPage())));
                              if (response == 'getDirection') {
                                showDetailSheet();
                              }
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 10,
                                        offset: Offset(0.7, 0.7),
                                        spreadRadius: 0.5)
                                  ]),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    // ignore: prefer_const_literals_to_create_immutables
                                    children: [
                                      PersianTextField(
                                        text: "جستجوی مقصد",
                                        textSize: 14,
                                      ),
                                      const SizedBox(
                                        width: 7,
                                      ),
                                      const Icon(
                                        Icons.search,
                                        color: BrandColors.colorAccentPurple,
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            textDirection: TextDirection.rtl,
                            children: [
                              const Icon(
                                OMIcons.home,
                                color: BrandColors.colorDimText,
                                size: 30,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PersianTextField(
                                    text: "اضافه کردن مکان",
                                    fontWeight: FontWeight.bold,
                                  ),
                                  PersianTextField(
                                    text: "مکان شما",
                                    textSize: 11,
                                    color: BrandColors.colorDimText,
                                  )
                                ],
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(color: Colors.black54),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            textDirection: TextDirection.rtl,
                            children: [
                              const Icon(
                                OMIcons.workOutline,
                                color: BrandColors.colorDimText,
                                size: 30,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PersianTextField(
                                    text: "اضافه کردن دفترکار",
                                    fontWeight: FontWeight.bold,
                                  ),
                                  PersianTextField(
                                    text: "دفترکار شما",
                                    textSize: 11,
                                    color: BrandColors.colorDimText,
                                  )
                                ],
                              )
                            ],
                          ),
                        ],
                      )),
                ),
              ),
            ),

            //RideDetailSheet

            Positioned(
              right: 0,
              bottom: 0,
              left: 0,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                  height: rideDetailsHeight,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 15,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7))
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(children: [
                      Container(
                        color: BrandColors.colorAccent1,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                (tripDetails != null)
                                    ? "${HelperMethods.replaceFarsiNumber(HelperMethods.calculateMoney(tripDetails!).toString())} هزارتومان"
                                    : "",
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontFamily: 'vazir',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Column(
                                children: [
                                  const Text(
                                    "تاکسی",
                                    style: TextStyle(
                                        fontFamily: "vazir",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    (tripDetails != null)
                                        ? "${HelperMethods.replaceFarsiNumber(HelperMethods.calculateDistance(tripDetails!).toString())} کیلومتر"
                                        : "",
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                        fontFamily: "vazir", fontSize: 14),
                                  )
                                ],
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Image.asset(
                                "assets/images/taxi.png",
                                height: 70,
                                width: 70,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              "نقدی",
                              style:
                                  TextStyle(fontFamily: 'vazir', fontSize: 17),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: BrandColors.colorTextLight,
                              size: 16,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Icon(
                              Icons.money,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TaxiButton(
                            title: "درخواست تاکسی",
                            color: BrandColors.colorGreen,
                            onPressed: () {
                              showRequestSheet();
                            },
                          ))
                    ]),
                  ),
                ),
              ),
            ),

            //Search taxi sheet
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: AnimatedSize(
                curve: Curves.easeIn,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: requestSheet,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0.7, 0.7),
                            spreadRadius: 0.5)
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ColorizeAnimatedTextKit(
                              text: const [
                                "...در جستجوی تاکسی",
                              ],
                              speed: const Duration(milliseconds: 30),
                              repeatForever: true,
                              textStyle: const TextStyle(
                                  fontSize: 22.0,
                                  fontFamily: "vazir",
                                  fontWeight: FontWeight.bold),
                              colors: const [
                                Colors.green,
                                Colors.greenAccent,
                                Colors.lightGreen,
                                Colors.lightGreenAccent,
                              ],
                              textAlign: TextAlign.center,
                              alignment: AlignmentDirectional
                                  .center // or Alignment.topLeft
                              ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onLongPress: () {
                            cancelRide();
                            resetApp();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.black87, width: 1)),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black87,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        PersianTextField(text: "لغو درخواست", textSize: 12)
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }

  Future<void> getDirection() async {
    var pickUp = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    var pickLatLng = LatLng(pickUp.lat, pickUp.long);
    var destinationLatLng = LatLng(destination.lat, destination.long);

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            const ProgressDialog(status: "please wait..."));

    var directionDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);
    tripDetails = directionDetails;

    // ignore: use_build_context_synchronously
    Navigator.pop(context);

    try {
      for (int i = 0; i < directionDetails!.points!.length; i++) {
        latLngCoordinates = directionDetails.points
            ?.map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();
      }
    } catch (_) {
      resetApp();
    }

    print(latLngCoordinates.toString());

    _polylines.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId('polyid'),
          color: const Color.fromARGB(255, 16, 38, 235),
          points: latLngCoordinates,
          jointType: JointType.round,
          width: 4,
          visible: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      _polylines.add(polyline);
    });

    LatLngBounds bounds;

    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
          northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude));
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
        markerId: MarkerId("pickup"),
        position: pickLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(snippet: "My Location", title: pickUp.placeAddress));

    Marker destinationMarker = Marker(
        markerId: MarkerId("destination"),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(snippet: "Destination", title: destination.placeName));

    setState(() {
      _markers.add(pickupMarker);
      _markers.add(destinationMarker);
    });
  }
}
