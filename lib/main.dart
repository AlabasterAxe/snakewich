import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(SnakeApp());
}

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNAAAKE',
      home: SnakeGame(),
    );
  }
}

enum Direction { north, east, south, west }

extension DirectionUtil on Direction {
  bool isOrthogonal(Direction d) {
    switch (this) {
      case Direction.north:
      case Direction.south:
        return d == Direction.east || d == Direction.west;
      case Direction.west:
      case Direction.east:
        return d == Direction.south || d == Direction.north;
    }
  }
}

class Coord {
  final int x;
  final int y;

  Coord(this.x, this.y);

  Coord getNeighbor(Direction d) => Coord(
      d == Direction.east
          ? x + 1
          : d == Direction.west
              ? x - 1
              : x,
      d == Direction.north
          ? y - 1
          : d == Direction.south
              ? y + 1
              : y);
  bool operator ==(obj) => obj is Coord && obj.x == x && obj.y == y;
  int get hashCode => x * 31 + y;
}

class SnakeGame extends StatefulWidget {
  @override
  SnakeGameState createState() => SnakeGameState();
}

class SnakeGameState extends State<SnakeGame> {
  Random r = new Random();

  int width;
  int height;
  List<Coord> snake;
  Direction snakeDirection;

  List<Direction> swipes;

  Timer updateTimer;

  int appleCountdown;
  List<Coord> apples;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    width = 20;
    height = 20;
    snake = [Coord(5, 3), Coord(4, 3)];
    apples = [];
    snakeDirection = Direction.east;
    swipes = [];
    appleCountdown = 4 + r.nextInt(10);
    updateTimer = Timer.periodic(Duration(milliseconds: 600), _update);
  }

  void _update(Timer timer) {
    setState(() {
      if (swipes.isNotEmpty) {
        snakeDirection = swipes.first;
        swipes.removeAt(0);
      }
      _updateSnake();
      _updateApples();
    });
  }

  void _updateSnake() {
    Coord newHead = snake.first.getNeighbor(snakeDirection);
    int tailLength = snake.length - 1;
    Coord consumedApple =
        apples.firstWhere((element) => element == newHead, orElse: () => null);
    if (consumedApple != null) {
      tailLength++;
      apples.remove(consumedApple);
    }
    snake = [newHead, ...snake.take(tailLength)];
  }

  void _updateApples() {
    appleCountdown--;
    if (appleCountdown <= 0) {
      List<Coord> eligibleApplePositions =
          List.generate(height, (y) => List.generate(width, (x) => Coord(x, y)))
              .expand((e) => e)
              .where((e) => !snake.contains(e) && !apples.contains(e))
              .toList();
      apples.add(
          eligibleApplePositions[r.nextInt(eligibleApplePositions.length)]);
      appleCountdown = 4 + r.nextInt(10);
    }
  }

  void _swipe(Direction direction) {
    if ((swipes.isEmpty && direction.isOrthogonal(snakeDirection)) ||
        (swipes.isNotEmpty && swipes.last.isOrthogonal(direction))) {
      swipes.add(direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(details.velocity.pixelsPerSecond.dy < 0
                  ? Direction.north
                  : Direction.south);
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(details.velocity.pixelsPerSecond.dx < 0
                  ? Direction.west
                  : Direction.east);
            }
          },
          child: AspectRatio(
            aspectRatio: width / height,
            child: Stack(fit: StackFit.expand, children: <Widget>[
              CustomPaint(
                  painter: SnakePainter(
                      width: width,
                      height: height,
                      snake: snake,
                      apples: apples))
            ]),
          ),
        ),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final int width;
  final int height;
  final List<Coord> snake;
  final List<Coord> apples;

  SnakePainter({this.width, this.height, this.snake, this.apples});
  @override
  void paint(Canvas canvas, Size size) {
    Paint tileColor = Paint()..color = Colors.blue.shade100;
    Paint snakeColor = Paint()..color = Colors.green.shade800;
    Paint appleColor = Paint()..color = Colors.red.shade800;
    double tileSize = size.width / width;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        drawTile(canvas, x, y, tileSize, .5, tileColor);
      }
    }
    for (Coord snake in snake) {
      drawTile(canvas, snake.x, snake.y, tileSize, 2, snakeColor);
    }
    for (Coord apple in apples) {
      drawTile(canvas, apple.x, apple.y, tileSize, 5, appleColor);
    }
  }

  void drawTile(
      Canvas canvas, int x, int y, double size, double deflation, Paint p) {
    canvas.drawRect(
        Rect.fromLTWH(x * size, y * size, size, size).deflate(deflation), p);
  }

  @override
  bool shouldRepaint(SnakePainter old) =>
      old.height != height ||
      old.width != width ||
      old.snake != snake ||
      old.apples != apples;
}
