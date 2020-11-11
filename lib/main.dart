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

extension DirectionUtil on Direction {
  bool isOrthogonal(Direction d) {
    if (this == Direction.north || this == Direction.south) {
      return d == Direction.east || d == Direction.west;
    } else {
      return d == Direction.south || d == Direction.north;
    }
  }
}

class Coord {
  final int x;
  final int y;

  Coord(this.x, this.y);

  Coord getNeighbor(Direction d) {
    switch (d) {
      case Direction.north:
        return Coord(x, y - 1);
      case Direction.east:
        return Coord(x + 1, y);
      case Direction.south:
        return Coord(x, y + 1);
      case Direction.west:
        return Coord(x - 1, y);
    }
  }

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

class TilePixelData {
  final List<List<bool>> pixels;

  const TilePixelData(this.pixels);

  TilePixelData flipV() => TilePixelData(pixels.reversed.toList());
  TilePixelData flipH() =>
      TilePixelData(pixels.map((row) => row.reversed.toList()).toList());
  TilePixelData rotCCW() => TilePixelData(
      List.generate(4, (x) => List.generate(4, (y) => pixels[y][x]))
          .reversed
          .toList());
  TilePixelData faceDirection(Direction d) {
    switch (d) {
      case Direction.north:
        return rotCCW();
      case Direction.east:
        return this;
      case Direction.south:
        return rotCCW().flipV();
      case Direction.west:
        return flipH();
    }
  }
}

// These point east by default
const TilePixelData snakeHeadPixels = TilePixelData([
  [true, false, false, false],
  [false, true, true, false],
  [true, true, true, false],
  [false, false, false, false]
]);
const TilePixelData snakeHeadWithMouthOpenPixels = TilePixelData([
  [true, false, true, false],
  [false, true, false, false],
  [true, true, false, false],
  [false, false, true, false]
]);
const TilePixelData snakeBodyPixels = TilePixelData([
  [false, false, false, false],
  [true, true, false, true],
  [true, false, true, true],
  [false, false, false, false]
]);
const TilePixelData snakeBodyWithApplePixels = TilePixelData([
  [false, true, true, false],
  [true, true, false, true],
  [true, false, true, true],
  [false, true, true, false]
]);
const TilePixelData snakeBodyTurnPixels = TilePixelData([
  [false, false, false, false],
  [false, false, true, true],
  [false, true, false, true],
  [false, true, true, false]
]);
const TilePixelData snakeTailPixels = TilePixelData([
  [false, false, false, false],
  [false, false, true, true],
  [true, true, true, true],
  [false, false, false, false]
]);
const TilePixelData applePixels = TilePixelData([
  [false, true, false, false],
  [true, false, true, false],
  [false, true, false, false],
  [false, false, false, false]
]);

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
        snakeDirection = swipes.removeAt(0);
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
      }
    });
  }

  Coord _getCoordForApple() {
    List<Coord> eligibleAppleCoords = [];
    List<Coord> snakeCoords = snake.map((e) => e.coord).toList();
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        Coord c = Coord(x, y);
        if (!snakeCoords.contains(c)) {
          eligibleAppleCoords.add(c);
        }
      }
    }
    return eligibleAppleCoords[r.nextInt(eligibleAppleCoords.length)];
  }

  void _swipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.distance > 20) {
      Offset pps = details.velocity.pixelsPerSecond;
      Direction direction = pps.dx.abs() > pps.dy.abs()
          ? pps.dx > 0
              ? Direction.east
              : Direction.west
          : pps.dy > 0
              ? Direction.south
              : Direction.north;
      if ((swipes.isEmpty && direction.isOrthogonal(snakeDirection)) ||
          (swipes.isNotEmpty && swipes.last.isOrthogonal(direction))) {
        swipes.add(direction);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget game = CustomPaint(
        painter: SnakeGamePainter(
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
                onPanEnd: gameOver ? null : _swipe,
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

class SnakeGamePainter extends CustomPainter {
  final int gridSize;
  final List<SnakePart> snake;
  final Direction snakeDirection;
  final Coord apple;

  SnakeGamePainter(
      {this.gridSize, this.snake, this.snakeDirection, this.apple});

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = size.width / gridSize;
    drawSnake(canvas, tileSize);
    drawPixelTile(canvas, applePixels, apple, tileSize);
  }

  void drawSnake(Canvas canvas, double tileSize) {
    SnakePart head = snake.first;
    drawPixelTile(
        canvas,
        head.coord.getNeighbor(snakeDirection) == apple
            ? snakeHeadWithMouthOpenPixels.faceDirection(snakeDirection)
            : snakeHeadPixels.faceDirection(snakeDirection),
        head.coord,
        tileSize);
    for (int segment = 1; segment < snake.length - 1; segment++) {
      drawPixelTile(canvas, getBodySegment(snake, segment),
          snake[segment].coord, tileSize);
    }
    drawPixelTile(
        canvas,
        snakeTailPixels.faceDirection(
            snake.last.coord.directionTo(snake[snake.length - 2].coord)),
        snake.last.coord,
        tileSize);
  }

  TilePixelData getBodySegment(List<SnakePart> snake, int segment) {
    SnakePart part = snake[segment];
    Direction leadingDirection =
        part.coord.directionTo(snake[segment - 1].coord);
    Direction trailingDirection =
        snake[segment + 1].coord.directionTo(part.coord);
    if (leadingDirection == trailingDirection) {
      return part.apple
          ? snakeBodyWithApplePixels.faceDirection(leadingDirection)
          : snakeBodyPixels.faceDirection(leadingDirection);
    }
    switch (leadingDirection) {
      case Direction.north:
        return trailingDirection == Direction.east
            ? snakeBodyTurnPixels.flipH().flipV()
            : snakeBodyTurnPixels.flipV();
      case Direction.east:
        return trailingDirection == Direction.north
            ? snakeBodyTurnPixels
            : snakeBodyTurnPixels.flipV();
      case Direction.south:
        return trailingDirection == Direction.east
            ? snakeBodyTurnPixels.flipH()
            : snakeBodyTurnPixels;
      case Direction.west:
        return trailingDirection == Direction.north
            ? snakeBodyTurnPixels.flipH()
            : snakeBodyTurnPixels.flipH().flipV();
    }
  }

  void drawPixelTile(
      Canvas canvas, TilePixelData pixelData, Coord c, double size) {
    double ps = size / 4;
    for (int py = 0; py < 4; py++) {
      for (int px = 0; px < 4; px++) {
        if (pixelData.pixels[py][px]) {
          canvas.drawRect(
              Rect.fromLTWH(c.x * size + px * ps, c.y * size + py * ps, ps, ps)
                  .deflate(.1),
              pixelPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SnakeGamePainter old) =>
      old.gridSize != gridSize ||
      old.snake != snake ||
      old.snakeDirection != snakeDirection ||
      old.apple != apple;
}
