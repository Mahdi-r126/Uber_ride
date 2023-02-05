class Prediction {
  int? placeId;

  String? displayName;

  String? lat;

  String? long;

  String? village;

  String? district;

  String? county;

  String? state;

  String? road;

  Prediction({this.placeId, this.displayName,this.lat,this.long,this.county,this.district,this.road,this.state,this.village});

  Prediction.fromJson(Map<String, dynamic> json) {
    placeId = json['place_id'];
    displayName = json['display_name'];
    lat = json['lat'];
    long = json['lon'];
    village = json['address']['village'];
    district = json['address']['district'];
    county = json['address']['county'];
    state = json['address']['state'];
    road = json['address']['road'];
  }
}
