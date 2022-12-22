import 'package:graphql/client.dart';
import 'package:geolocator/geolocator.dart';

class StopHandler {
  static getClient() {
    final httpLink = HttpLink(
        'https://api.digitransit.fi/routing/v1/routers/waltti/index/graphql');
    return GraphQLClient(
      /// pass the store to the cache for persistence
      cache: GraphQLCache(),
      link: httpLink,
    );
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  _mapStops() {}

  getStops() async {
    final loc = await _getPosition();

    const String getNearestStops = r'''
      query getNearestLocations($lat: Float!, $lon: Float!) {
        nearest(lat: $lat, lon: $lon, maxResults: 100, filterByPlaceTypes: [STOP]) {
          edges {
            node {
                place {
                  lat
                  lon
                  ...on Stop {
                    name
                    gtfsId
                    name
                    routes {
                      shortName
                    }
                    patterns {
                      name
                      headsign
                    }
                    stoptimesWithoutPatterns(numberOfDepartures: 100) {
                      scheduledArrival
                      realtimeArrival
                      trip {
                        routeShortName
                        tripHeadsign
                      }
                    }
                  }
                }
                distance
            }
          }
        }
      }
    ''';

    //const testLat = 61.498920;
    //const testLon = 23.782495;

    final QueryOptions options = QueryOptions(
      document: gql(getNearestStops),
      variables: <String, double>{'lat': loc.latitude, 'lon': loc.longitude},
    );

    final GraphQLClient client = getClient();
    final QueryResult result = await client.query(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    final List<dynamic> list =
        result.data!['nearest']['edges'] as List<dynamic>;
    const homeLat = 61.472119;
    const homeLon = 23.725973;

    //print(Geolocator.distanceBetween(homeLat, homeLon, loc.latitude, loc.longitude));

    final goingToCity = Geolocator.distanceBetween(
                homeLat, homeLon, loc.latitude, loc.longitude) <
            500
        ? true
        : false;
    //print('goingToCity:' + goingToCity.toString());

    const routeShortName = '8';

    final List<dynamic> validStops = list
        .where((element) => element['node']['place']['routes']
            .map((r) => r['shortName'])
            .contains(routeShortName))
        .toList();
    final List<dynamic> corrDirectionStops = goingToCity
        ? validStops
            .where((element) =>
                element['node']['place']['stoptimesWithoutPatterns']
                    .map((r) => r['trip']['tripHeadsign'])
                    .contains('Keskustori') ||
                element['node']['place']['stoptimesWithoutPatterns']
                    .map((r) => r['trip']['tripHeadsign'])
                    .contains('Haukiluoma'))
            .toList()
        : validStops
            .where((element) => element['node']['place']
                    ['stoptimesWithoutPatterns']
                .map((r) => r['trip']['tripHeadsign'])
                .contains('Kyösti'))
            .toList();
    return corrDirectionStops.first;
  }
}
