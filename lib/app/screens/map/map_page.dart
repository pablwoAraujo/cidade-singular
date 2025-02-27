import 'dart:async';

import 'package:cidade_singular/app/models/singularity.dart';
import 'package:cidade_singular/app/models/user.dart';
import 'package:cidade_singular/app/screens/map/filter_type_widget.dart';
import 'package:cidade_singular/app/screens/singularity/singularity_page.dart';
import 'package:cidade_singular/app/services/singularity_service.dart';
import 'package:cidade_singular/app/stores/city_store.dart';
import 'package:cidade_singular/app/util/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'dart:ui' as ui;

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  SingularityService service = Modular.get();
  CityStore cityStore = Modular.get();
  bool loading = false;

  @override
  initState() {
    super.initState();
    getSingularites();
  }

  Set<Marker> markers = {};

  List<Singularity> singularities = [];

  getSingularites({CuratorType? type}) async {
    setState(() => loading = true);
    singularities = await service.getSingularities(query: {
      "city": cityStore.city.id,
      if (type != null) "type": type.toString().split(".").last,
    });
    var icons = await loadBitmapIcons();
    Set<Marker> newMarkers = singularities.map((sing) {
      MarkerId markerId = MarkerId(sing.id);
      return Marker(
        markerId: markerId,
        position: sing.latLng,
        icon: icons[sing.type] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          onTap: () async {
            Modular.to.pushNamed(SingularityPage.routeName, arguments: sing);
          },
          title: sing.title,
          snippet: sing.address,
        ),
      );
    }).toSet();
    setState(() {
      markers = newMarkers;
      loading = false;
    });
  }

  changeMapMode() {
      getJsonFile("assets/images/mapMode.json").then(setMapStyle);
  }

  Future<String> getJsonFile(String path) async {
    return await rootBundle.loadString(path);
  }

  void setMapStyle(String mapStyle) {
    _controller.setMapStyle(mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              liteModeEnabled: false,
              rotateGesturesEnabled: false,
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: cityStore.city.latLng,
                zoom: 13,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                changeMapMode();
                setState(() {});
              },
              markers: markers,
            ),
          ),
          if (loading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  color: Constants.primaryColor,
                ),
              ),
            ),
          Positioned.fill(
            child: FilterTypeWidget(
              onChoose: (type) {
                getSingularites(type: type);
              },
            ),
            top: 100,
            bottom: 150,
          )
        ],
      ),
    );
  }

  Widget selectTypeWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: CuratorType.values
          .map(
            (type) => GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                    color: Constants.getColor(type.toString().split(".").last),
                    borderRadius: BorderRadius.circular(50)),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.value),
                    SvgPicture.asset(
                        "assets/images/${type.toString().split(".").last}.svg",
                        width: 20)
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<Map<String, BitmapDescriptor>> loadBitmapIcons() async {
    return {
      "MUSIC": BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/music.png", 100)
      ),
      "ARTS":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/art.png", 100)
      ),
      "CRAFTS":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/crafts.png", 100)
      ),
      "FILM":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/film.png", 100)
      ),
      "GASTRONOMY":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/gastronomy.png", 100)
      ),
      "LITERATURE":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/book.png", 100)
      ),
      "DESIGN":  BitmapDescriptor.fromBytes(
        await getBytesFromAsset("assets/images/design.png", 100)
      ),
    };
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
}
