import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';


import '../Models/Prediction.dart';
import '../Models/addressModels.dart';
import '../brand_colors.dart';
import '../helper/helperMethods.dart';
import '../providers/appdata.dart';
import '../widgets/Text.dart';
import '../widgets/progressContainer.dart';
import '../widgets/taxiButton.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var pickupController = TextEditingController();
  var destinationController = TextEditingController();
  List<Prediction> list = [];

  var focusDestination = FocusNode();
  bool focus = false;

  void setFocus() {
    if (!focus) {
      FocusScope.of(context).requestFocus(focusDestination);
      focus = true;
    }
  }

  void searchPlace(String placeName) async {
    if (placeName.length > 2) {
      String url =
          "https://nominatim.openstreetmap.org/search?q=${placeName}+iran&format=json&polygon_geojson=1&addressdetails=1";
      http.Response response = await http.get(url);
      try {
        if (response.statusCode == 200) {
          String data = response.body;
          var decodedData = jsonDecode(data);

          var thisList =
              (decodedData as List).map((e) => Prediction.fromJson(e)).toList();
          setState(() {
            list = thisList;
          });
        } else {
          print("failed");
        }
      } catch (e) {
        print(e.toString());
        print("failed2");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    setFocus();
    String address =
        Provider.of<AppData>(context).pickupAddress.placeAddress.toString();
    pickupController.text = HelperMethods.splitDisplayName(address);
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: const Text(
              "Search Destination",
              style:
                  TextStyle(fontFamily: "bolt-semibold", color: Colors.black),
            ),
            leading: MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back, size: 30),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 3,
                          offset: Offset(0.7, 0.7),
                          spreadRadius: 0.3,
                          color: Colors.black26)
                    ],
                  ),
                  child: Column(children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/pickicon.png',
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: BrandColors.colorLightGrayFair,
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                enabled: false,
                                style: const TextStyle(fontFamily: 'vazir'),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                controller: pickupController,
                                decoration: const InputDecoration(
                                    hintText: "Pickup location",
                                    border: InputBorder.none,
                                    fillColor: BrandColors.colorLightGrayFair,
                                    filled: true,
                                    isDense: true),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/desticon.png',
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: BrandColors.colorLightGrayFair,
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    list.cast();
                                    searchPlace(value);
                                  });
                                },
                                controller: destinationController,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontFamily: 'vazir'),
                                // focusNode: focusDestination,
                                decoration: const InputDecoration(
                                    hintText: "انتخاب مقصد",
                                    border: InputBorder.none,
                                    fillColor: BrandColors.colorLightGrayFair,
                                    filled: true,
                                    isDense: true),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(
                  height: 15,
                ),
                if (list.isNotEmpty)
                  ListView.separated(
                    itemBuilder: (context, index) {
                      return PredictionTile(prediction: list[index]);
                    },
                    itemCount: list.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                  )
                else if (destinationController.text.isNotEmpty)
                  const ProgressbarBox()
                else if (destinationController.text.isEmpty)
                  Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PredictionTile extends StatelessWidget {
  Prediction? prediction = Prediction();
  String? displayName;

  PredictionTile({this.prediction});

  void getPlaceDetails(dynamic placeID, BuildContext context) {
    Address thisPlace = Address();
    thisPlace.lat = double.tryParse(prediction!.lat.toString());
    thisPlace.long = double.tryParse(prediction!.long.toString());
    thisPlace.placeId = prediction?.placeId;
    thisPlace.placeName = prediction?.displayName;
    Provider.of<AppData>(context, listen: false)
        .updateDestinationAddress(thisPlace);
    print(thisPlace.lat.toString() +
        '\n' +
        thisPlace.long.toString() +
        '\n' +
        thisPlace.placeName.toString());

    Navigator.pop(context, 'getDirection');
  }

  void showAlertDialog(BuildContext context) {
    AlertDialog alertDialog = AlertDialog(
      title: const Text(
        "Location information",
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'vazir'),
      ),
      titleTextStyle: const TextStyle(
          color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w700),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
      titlePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(prediction!.displayName.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w300)),
          const SizedBox(
            height: 30,
          ),
          TaxiButton(
            title: "OK",
            color: BrandColors.colorBlue,
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
    showDialog(
        context: context,
        builder: (BuildContext buildcontext) {
          return alertDialog;
        });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        getPlaceDetails(prediction!.placeId, context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    HelperMethods.splitDisplayName(
                        prediction!.displayName.toString()),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'vazir'),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showAlertDialog(context);
                    })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
