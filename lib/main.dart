import 'package:flutter/material.dart';
import 'package:snakewich/snake.dart';

void main() {
  runApp(MyApp());
}

int BOARD_ROWS = 20;
int BOARD_COLUMNS = 20;
double snakeSpeedPPS = 5;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  AnimationController worldController;
  SnakeModel snake;
  int lastUpdateMillis;
  List<Offset> upcomingSwipes;
  Offset targetPoint;

  List<Offset> applePositions = [];

  @override
  void initState() {
    super.initState();
    worldController =
        AnimationController(vsync: this, duration: Duration(days: 10000));
    worldController.addListener(_update);
    _reset();
  }

  void _reset() {
    snake = SnakeModel(head: Offset(5, 10), length: 4, points: [
      Offset(1, 10),
    ]);
    lastUpdateMillis = 0;
    upcomingSwipes = [];
    applePositions = [Offset(3.0, 7.0)];
  }

  void _update() {
    if (!worldController.isAnimating) {
      return;
    }

    double elapsedTimeSeconds =
        (worldController.lastElapsedDuration.inMilliseconds -
                lastUpdateMillis) /
            1000;
    if (upcomingSwipes.isNotEmpty) {
      if (targetPoint == null) {
        targetPoint = (snake.head + snake.direction / 2);
        targetPoint = Offset(
            targetPoint.dx.roundToDouble(), targetPoint.dy.roundToDouble());
      }
      Offset targetOffset = targetPoint - snake.head;
      Offset directionToTarget = Offset.fromDirection(targetOffset.direction);
      if (snake.direction.dx.round() == 0 &&
              (snake.direction.dy + directionToTarget.dy).round() == 0 ||
          snake.direction.dy.round() == 0 &&
              (snake.direction.dx + directionToTarget.dx).round() == 0) {
        Offset newHead =
            targetPoint + upcomingSwipes[0] * targetOffset.distance;
        snake = SnakeModel(
            head: newHead,
            length: snake.length,
            points: [targetPoint] + snake.points);
        targetPoint = null;
        upcomingSwipes.removeAt(0);
      }
    }
    snake = SnakeModel(
        head: snake.head +
            (snake.direction * (snakeSpeedPPS * elapsedTimeSeconds)),
        length: snake.length,
        points: snake.points);

    lastUpdateMillis = worldController.lastElapsedDuration.inMilliseconds;
  }

  void _start() {
    worldController.forward();
  }

  void _swipe(Offset swipeDirection) {
    if (!worldController.isAnimating) {
      _start();
    } else {
      Offset comparisonDirection =
          upcomingSwipes.isEmpty ? snake.direction : upcomingSwipes.last;
      if (swipeDirection.dy.round() != 0 &&
              comparisonDirection.dx.round() != 0 ||
          swipeDirection.dx.round() != 0 &&
              comparisonDirection.dy.round() != 0) {
        upcomingSwipes.add(swipeDirection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double tileSize = size.width / BOARD_COLUMNS;
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(Offset(0, details.primaryVelocity.sign));
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(Offset(details.primaryVelocity.sign, 0));
            }
          },
          child: AspectRatio(
            aspectRatio: BOARD_COLUMNS / BOARD_ROWS,
            child: Stack(
              children: <Widget>[
                    Positioned.fill(
                        child: AnimatedBuilder(
                            animation: worldController,
                            builder: (context, _) {
                              return SnakeWidget(
                                snake: snake,
                                boardColumns: BOARD_COLUMNS,
                                boardRows: BOARD_ROWS,
                              );
                            }))
                  ] +
                  applePositions
                      .map((e) => Positioned(
                          left: e.dx * tileSize,
                          top: e.dy * tileSize,
                          child: Container(
                              width: 25, height: 25, color: Colors.blue)))
                      .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
