import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionDetails {
  double? distance;
  double? duration;
  List? points=[];

  DirectionDetails({this.distance, this.duration, this.points});
}
