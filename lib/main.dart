import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgColor = Color.fromARGB(255, 168, 214, 0);
const Color pixelColor = Color.fromARGB(255, 32, 65, 0);
Paint pixelPaint = Paint()..color = pixelColor;

void main() {
  runApp(SnakeApp());
}

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNAAAKE',
      theme: ThemeData(
          scaffoldBackgroundColor: bgColor,
          textTheme:
              GoogleFonts.pressStart2pTextTheme().apply(bodyColor: pixelColor)),
      home: SnakeGame(),
    );
  }
}

enum Direction { north, east, south, west }

Direction fromOffset(Offset o) {
  if (o.dx.abs() > o.dy.abs()) {
    return o.dx > 0 ? Direction.east : Direction.west;
  } else {
    return o.dy > 0 ? Direction.south : Direction.north;
  }
}

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

  Direction directionTo(Coord c) {
    if (c.y == y) {
      return c.x < x ? Direction.west : Direction.east;
    } else if (c.x == x) {
      return c.y < y ? Direction.north : Direction.south;
    } else {
      throw new Exception("invalid coordinates");
    }
  }

  bool operator ==(obj) => obj is Coord && obj.x == x && obj.y == y;
  int get hashCode => x * 31 + y;
}

class SnakePart {
  final Coord coord;
  final bool apple;

  SnakePart(this.coord, this.apple);
}

class SnakeGame extends StatefulWidget {
  @override
  SnakeGameState createState() => SnakeGameState();
}

class SnakeGameState extends State<SnakeGame> {
  Random r = new Random();

  Timer updateTimer;

  int gridSize;
  List<SnakePart> snake;
  Direction snakeDirection;

  Coord apple;

  List<Direction> swipes;

  int score = 0;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    updateTimer.cancel();
    super.dispose();
  }

  void _reset() {
    score = 0;
    gridSize = 20;
    snake = [
      SnakePart(Coord(4, 3), false),
      SnakePart(Coord(3, 3), false),
      SnakePart(Coord(2, 3), false)
    ];
    apple = _getCoordForApple();
    snakeDirection = Direction.east;
    swipes = [];
    updateTimer = Timer.periodic(Duration(milliseconds: 600), _update);
    gameOver = false;
  }

  void _update(Timer timer) {
    setState(() {
      if (swipes.isNotEmpty) {
        snakeDirection = swipes.first;
        swipes.removeAt(0);
      }
      Coord newHead = snake.first.coord.getNeighbor(snakeDirection);
      if (newHead == apple) {
        score += 4;
        snake = [SnakePart(newHead, true), ...snake.take(snake.length)];
        apple = _getCoordForApple();
      } else {
        snake = [SnakePart(newHead, false), ...snake.take(snake.length - 1)];
      }
      if (newHead.x < 0 ||
          newHead.y < 0 ||
          newHead.x >= gridSize ||
          newHead.y >= gridSize ||
          snake.skip(1).map((c) => c.coord).contains(newHead)) {
        timer.cancel();
        gameOver = true;
        return;
      }
    });
  }

  Coord _getCoordForApple() {
    List<Coord> eligibleApplePositions = List.generate(
            gridSize, (y) => List.generate(gridSize, (x) => Coord(x, y)))
        .expand((e) => e)
        .where((e) => !snake.map((e) => e.coord).contains(e))
        .toList();
    return eligibleApplePositions[r.nextInt(eligibleApplePositions.length)];
  }

  void _swipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.distance > 20) {
      Direction direction = fromOffset(details.velocity.pixelsPerSecond);
      if ((swipes.isEmpty && direction.isOrthogonal(snakeDirection)) ||
          (swipes.isNotEmpty && swipes.last.isOrthogonal(direction))) {
        swipes.add(direction);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget game = CustomPaint(
        painter: SnakePainter(
            gridSize: gridSize,
            snake: snake,
            snakeDirection: snakeDirection,
            apple: apple));
    if (gameOver) {
      game = Stack(fit: StackFit.expand, children: [
        game,
        Center(
            child: Text(
          "GAME OVER",
        ))
      ]);
    }
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("$score"),
              GestureDetector(
                onTap: gameOver ? _reset : null,
                onVerticalDragEnd: gameOver ? null : _swipe,
                onHorizontalDragEnd: gameOver ? null : _swipe,
                child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        border: Border.all(color: pixelColor, width: 4)),
                    child: AspectRatio(aspectRatio: 1.0, child: game)),
              )
            ]),
      ),
    );
  }
}

const List<List<bool>> snakeHeadPixels = [
  [true, false, false, false],
  [false, true, true, false],
  [true, true, true, false],
  [false, false, false, false]
];
const List<List<bool>> snakeHeadWithMouthOpenPixels = [
  [true, false, true, false],
  [false, true, false, false],
  [true, true, false, false],
  [false, false, true, false]
];
const List<List<bool>> snakeBodyPixels = [
  [false, false, false, false],
  [true, true, false, true],
  [true, false, true, true],
  [false, false, false, false]
];
const List<List<bool>> snakeBodyWithApplePixels = [
  [false, true, true, false],
  [true, true, false, true],
  [true, false, true, true],
  [false, true, true, false]
];
const List<List<bool>> snakeBodyTurnPixels = [
  [false, false, false, false],
  [false, false, true, true],
  [false, true, false, true],
  [false, true, true, false]
];
const List<List<bool>> snakeTailPixels = [
  [false, false, false, false],
  [false, false, true, true],
  [true, true, true, true],
  [false, false, false, false]
];
const List<List<bool>> applePixels = [
  [false, true, false, false],
  [true, false, true, false],
  [false, true, false, false],
  [false, false, false, false]
];

List<List<bool>> flipH(List<List<bool>> v) =>
    v.map((row) => row.reversed.toList()).toList();
List<List<bool>> flipV(List<List<bool>> v) => v.reversed.toList();
List<List<bool>> rotCCW(List<List<bool>> v) =>
    List.generate(4, (x) => List.generate(4, (y) => v[y][x])).reversed.toList();

List<List<bool>> faceDirection(List<List<bool>> v, Direction d) {
  switch (d) {
    case Direction.north:
      return rotCCW(v);
    case Direction.east:
      return v;
    case Direction.south:
      return flipV(rotCCW(v));
    case Direction.west:
      return flipH(v);
  }
}

class SnakePainter extends CustomPainter {
  final int gridSize;
  final List<SnakePart> snake;
  final Direction snakeDirection;
  final Coord apple;

  SnakePainter({this.gridSize, this.snake, this.snakeDirection, this.apple});

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = size.width / gridSize;
    drawSnake(canvas, tileSize);
    drawPixelTile(canvas, applePixels, apple, tileSize);
  }

  void drawSnake(Canvas canvas, double tileSize) {
    drawPixelTile(
        canvas,
        faceDirection(
            snake.first.coord.getNeighbor(snakeDirection) == apple
                ? snakeHeadWithMouthOpenPixels
                : snakeHeadPixels,
            snakeDirection),
        snake.first.coord,
        tileSize);
    for (int segment = 1; segment < snake.length - 1; segment++) {
      drawPixelTile(canvas, getBodySegment(snake, segment),
          snake[segment].coord, tileSize);
    }
    drawPixelTile(
        canvas,
        faceDirection(snakeTailPixels,
            snake.last.coord.directionTo(snake[snake.length - 2].coord)),
        snake.last.coord,
        tileSize);
  }

  List<List<bool>> getBodySegment(List<SnakePart> snake, int segment) {
    SnakePart seg = snake[segment];
    Direction head = seg.coord.directionTo(snake[segment - 1].coord);
    Direction tail = snake[segment + 1].coord.directionTo(seg.coord);
    if (head == tail) {
      return faceDirection(
          seg.apple ? snakeBodyWithApplePixels : snakeBodyPixels, head);
    }
    switch (head) {
      case Direction.north:
        return tail == Direction.east
            ? flipV(flipH(snakeBodyTurnPixels))
            : flipV(snakeBodyTurnPixels);
      case Direction.east:
        return tail == Direction.north
            ? snakeBodyTurnPixels
            : flipV(snakeBodyTurnPixels);
      case Direction.south:
        return tail == Direction.east
            ? flipH(snakeBodyTurnPixels)
            : snakeBodyTurnPixels;
      case Direction.west:
        return tail == Direction.north
            ? flipH(snakeBodyTurnPixels)
            : flipV(flipH(snakeBodyTurnPixels));
    }
  }

  void drawPixelTile(
      Canvas canvas, List<List<bool>> pixels, Coord c, double size) {
    double ps = size / 4;
    for (int py = 0; py < 4; py++) {
      for (int px = 0; px < 4; px++) {
        if (pixels[py][px]) {
          canvas.drawRect(
              Rect.fromLTWH(c.x * size + px * ps, c.y * size + py * ps, ps, ps)
                  .deflate(.1),
              pixelPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SnakePainter old) =>
      old.gridSize != gridSize ||
      old.snake != snake ||
      old.snakeDirection != snakeDirection ||
      old.apple != apple;
}
