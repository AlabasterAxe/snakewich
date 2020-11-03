import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:snakewich/model/direction.dart';
import 'package:snakewich/snake.dart';
import 'package:snakewich/views/snake-board.dart';

void main() {
  runApp(SnakeApp());
}

class SnakeApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNAAAKE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  @override
  SnakeGameState createState() => SnakeGameState();
}

class SnakeGameState extends State<SnakeGame> {
  Random r = new Random();

  SnakeBoard board;
  List<SnakeBoardTile> snake;
  List<SnakeBoardTile> apples;
  Direction snakeDirection;

  List<Direction> swipes;

  Timer updateTimer;

  int appleCountdown;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    board = SnakeBoard(20, 20);
    snake = [board.tiles[5][3], board.tiles[5][2]];
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
      SnakeBoardTile newHead = snake.first.getNeighbor(snakeDirection);
      int tailLength = snake.length - 1;
      SnakeBoardTile consumedApple = apples
          .firstWhere((element) => element == newHead, orElse: () => null);
      if (consumedApple != null) {
        tailLength++;
        apples.remove(consumedApple);
      }
      snake = [newHead] + snake.take(tailLength).toList();
      appleCountdown--;
      if (appleCountdown == 0) {
        appleCountdown = 4 + r.nextInt(10);
        List<SnakeBoardTile> eligibleApplePositions =
            board.tiles.expand((e) => e).toList();
        snake.forEach((element) {
          eligibleApplePositions.remove(element);
        });
        apples.add(
            eligibleApplePositions[r.nextInt(eligibleApplePositions.length)]);
      }
    });
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
            aspectRatio: board.width / board.height,
            child: Stack(children: <Widget>[
              Positioned.fill(
                  child: CustomPaint(
                      painter: SnakePainter(
                          board: board, snake: snake, apples: apples)))
            ]),
          ),
        ),
      ),
    );
  }
}
