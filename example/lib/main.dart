import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matter Dart Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Matter Dart Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Runner _runner = Runner();

  void _startRunner() {
    int counter = 0;
    Engine engine = Engine.create(EngineOptions(
        world: Composite.create(CompositeOptions(bodies: [Bodies.rectangle(0, 0, 20, 20, BodyOptions())]))));
    _runner.run((dt, correction) {
      if (correction.isFinite) {
        print('$counter -> dt: $dt \t correction: $correction');

        engine.update(dt, correction);
        print(" here speed -->  ${engine.world?.bodies.first.speed}");
        counter++;
      }
    }, engineTiming: EngineTimingOptions(timeScale: 1.1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _startRunner,
      ),
    );
  }
}
