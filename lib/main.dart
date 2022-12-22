import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:nysse_times/stop_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nysse times',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Nysse times'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _stopName = "No stop";
  String _distance = "0m";
  List<dynamic> _arrivals = [];

  void _getBussTimes() async {
    try {
      final stop = await StopHandler().getStops();
      final filtered = stop['node']['place']['stoptimesWithoutPatterns']
          .where((element) =>
              element['trip']['tripHeadsign'] == 'Haukiluoma' ||
              element['trip']['tripHeadsign'] == 'Kyösti' ||
              element['trip']['tripHeadsign'] == 'Keskustori')
          .toList();
      //print(stop['node']['place']['name']);
      //print('distance' + stop['node']['distance'].toString());
      setState(() {
        _stopName = stop['node']['place']['name'];
        _distance = stop['node']['distance'].toString();
        _arrivals = filtered;
      });
    } catch (e) {
      print(e);
      print("failed to fetch stop");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _getBussTimes();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          children: <Widget>[
            Text(
              _stopName + " - " + _distance  + "m",
              style: Theme.of(context).textTheme.headline4,
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: _arrivals.length,
                    itemBuilder: (context, index) {
                      final arrival = _arrivals[index];
                      final routeShortName = arrival['trip']['routeShortName'];
                      final tripHeadsign = arrival['trip']['tripHeadsign'];
                      final scHours =
                          (arrival['scheduledArrival'] / (60 * 60)).toInt();
                      final scMinutes =
                          ((arrival['scheduledArrival'] - (scHours * 60 * 60)) /
                                  60)
                              .toInt();
                      final scHourFormated = scHours == 24
                          ? 0
                          : scHours == 25
                              ? 1
                              : scHours;
                      final eHours =
                          (arrival['realtimeArrival'] / (60 * 60)).toInt();
                      final eMinutes =
                          ((arrival['realtimeArrival'] - (eHours * 60 * 60)) /
                                  60)
                              .toInt();
                      final eHourFormated = eHours == 24
                          ? 0
                          : eHours == 25
                              ? 1
                              : eHours;
                      return Card(
                          child: ListTile(
                              title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tripHeadsign + ': ' + routeShortName,
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            scHourFormated.toString().padLeft(2, '0') +
                                ":" +
                                scMinutes.toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                          Text(
                            eHourFormated.toString().padLeft(2, '0') +
                                ":" +
                                eMinutes.toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: 20, color: Colors.green),
                          ),
                        ],
                      )));
                    }))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getBussTimes,
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
