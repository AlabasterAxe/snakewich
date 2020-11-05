import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color bgColor = Color.fromARGB(255, 168, 214, 0);
Color pixelColor = Color.fromARGB(255, 32, 65, 0);

void main() {
  runApp(SnakeApp());
}

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNAAAKE',
      theme: ThemeData(textTheme: GoogleFonts.pressStart2pTextTheme()),
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

  int width;
  int height;
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
    if (updateTimer != null) {
      updateTimer.cancel();
    }
    super.dispose();
  }

  void _reset() {
    score = 0;
    width = 20;
    height = 20;
    snake = [
      SnakePart(Coord(5, 3), false),
      SnakePart(Coord(4, 3), false),
      SnakePart(Coord(3, 3), false)
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
      bool eatingApple = apple == newHead;
      int tailLength = snake.length - 1;
      if (eatingApple) {
        score += 15;
        tailLength++;
        apple = _getCoordForApple();
      }
      snake = [SnakePart(newHead, eatingApple), ...snake.take(tailLength)];
      if (newHead.x < 0 ||
          newHead.y < 0 ||
          newHead.x >= width ||
          newHead.y >= height ||
          snake.skip(1).contains(newHead)) {
        timer.cancel();
        gameOver = true;
        return;
      }
    });
  }

  Coord _getCoordForApple() {
    List<Coord> eligibleApplePositions =
        List.generate(height, (y) => List.generate(width, (x) => Coord(x, y)))
            .expand((e) => e)
            .where((e) => !snake.contains(e))
            .toList();
    return eligibleApplePositions[r.nextInt(eligibleApplePositions.length)];
  }

  void _swipe(Direction direction) {
    if ((swipes.isEmpty && direction.isOrthogonal(snakeDirection)) ||
        (swipes.isNotEmpty && swipes.last.isOrthogonal(direction))) {
      swipes.add(direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget game = CustomPaint(
        painter: SnakePainter(
            width: width,
            height: height,
            snake: snake,
            snakeDirection: snakeDirection,
            apple: apple));
    if (gameOver) {
      game = Stack(fit: StackFit.expand, children: [
        game,
        Center(
            child: Text(
          "GAME OVER",
          style: TextStyle(color: pixelColor),
        ))
      ]);
    }
    game = Container(
        padding: EdgeInsets.all(4),
        decoration:
            BoxDecoration(border: Border.all(color: pixelColor, width: 4)),
        child: AspectRatio(aspectRatio: width / height, child: game));
    if (gameOver) {
      game = GestureDetector(
        child: game,
        onTap: () {
          _reset();
        },
      );
    } else {
      game = GestureDetector(
        onVerticalDragEnd: (details) {
          if (gameOver) {
            _reset();
          } else {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(details.velocity.pixelsPerSecond.dy < 0
                  ? Direction.north
                  : Direction.south);
            }
          }
        },
        onHorizontalDragEnd: (details) {
          if (gameOver) {
            _reset();
          } else {
            if (details.velocity.pixelsPerSecond.distance > 20) {
              _swipe(details.velocity.pixelsPerSecond.dx < 0
                  ? Direction.west
                  : Direction.east);
            }
          }
        },
        child: game,
      );
    }
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "$score",
                textAlign: TextAlign.left,
              ),
              game
            ]),
      ),
    );
  }
}

enum PixelArt {
  snakeHead,
  snakeHeadWithMouthOpen,
  snakeBody,
  snakeBodyWithApple,
  snakeBodyTurn,
  snakeTail,
  apple
}
const Map<PixelArt, List<List<bool>>> pixelArt = {
  PixelArt.snakeHead: [
    [true, false, false, false],
    [false, true, true, false],
    [true, true, true, false],
    [false, false, false, false]
  ],
  PixelArt.snakeHeadWithMouthOpen: [
    [true, false, true, false],
    [false, true, false, false],
    [true, true, false, false],
    [false, false, true, false]
  ],
  PixelArt.snakeBody: [
    [false, false, false, false],
    [true, true, false, true],
    [true, false, true, true],
    [false, false, false, false]
  ],
  PixelArt.snakeBodyWithApple: [
    [false, true, true, false],
    [true, true, false, true],
    [true, false, true, true],
    [false, true, true, false]
  ],
  PixelArt.snakeBodyTurn: [
    [false, false, false, false],
    [false, false, true, true],
    [false, true, false, true],
    [false, true, true, false]
  ],
  PixelArt.snakeTail: [
    [false, false, false, false],
    [false, false, true, true],
    [true, true, true, true],
    [false, false, false, false]
  ],
  PixelArt.apple: [
    [false, true, false, false],
    [true, false, true, false],
    [false, true, false, false],
    [false, false, false, false]
  ]
};

List<List<bool>> flipH(List<List<bool>> v) =>
    v.map((row) => row.reversed.toList()).toList();
List<List<bool>> flipV(List<List<bool>> v) => v.reversed.toList();
List<List<bool>> rotCCW(List<List<bool>> v) =>
    List.generate(4, (x) => List.generate(4, (y) => v[y][x])).reversed.toList();

List<List<bool>> getBodySegment(List<SnakePart> snake, int segment) {
  SnakePart seg = snake[segment];
  Direction head = seg.coord.directionTo(snake[segment - 1].coord);
  Direction tail = snake[segment + 1].coord.directionTo(seg.coord);
  if (head == tail) {
    return faceDirection(
        pixelArt[seg.apple ? PixelArt.snakeBodyWithApple : PixelArt.snakeBody],
        head);
  }
  switch (head) {
    case Direction.north:
      return tail == Direction.east
          ? flipV(flipH(pixelArt[PixelArt.snakeBodyTurn]))
          : flipV(pixelArt[PixelArt.snakeBodyTurn]);
    case Direction.east:
      return tail == Direction.north
          ? pixelArt[PixelArt.snakeBodyTurn]
          : flipV(pixelArt[PixelArt.snakeBodyTurn]);
    case Direction.south:
      return tail == Direction.east
          ? flipH(pixelArt[PixelArt.snakeBodyTurn])
          : pixelArt[PixelArt.snakeBodyTurn];
    case Direction.west:
      return tail == Direction.north
          ? flipH(pixelArt[PixelArt.snakeBodyTurn])
          : flipV(flipH(pixelArt[PixelArt.snakeBodyTurn]));
  }
}

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
  final Paint pixelPaint;
  final int width;
  final int height;
  final List<SnakePart> snake;
  final Direction snakeDirection;
  final Coord apple;

  SnakePainter(
      {this.width, this.height, this.snake, this.snakeDirection, this.apple})
      : pixelPaint = Paint()..color = Color.fromARGB(255, 32, 65, 0);

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = size.width / width;
    drawSnake(canvas, tileSize);
    drawPixelTile(canvas, pixelArt[PixelArt.apple], apple.x, apple.y, tileSize,
        pixelPaint);
  }

  void drawSnake(Canvas canvas, double tileSize) {
    drawPixelTile(
        canvas,
        faceDirection(
            pixelArt[snake.first.coord.getNeighbor(snakeDirection) == apple
                ? PixelArt.snakeHeadWithMouthOpen
                : PixelArt.snakeHead],
            snakeDirection),
        snake.first.coord.x,
        snake.first.coord.y,
        tileSize,
        pixelPaint);
    for (int segment = 1; segment < snake.length - 1; segment++) {
      drawPixelTile(canvas, getBodySegment(snake, segment),
          snake[segment].coord.x, snake[segment].coord.y, tileSize, pixelPaint);
    }
    drawPixelTile(
        canvas,
        faceDirection(pixelArt[PixelArt.snakeTail],
            snake.last.coord.directionTo(snake[snake.length - 2].coord)),
        snake.last.coord.x,
        snake.last.coord.y,
        tileSize,
        pixelPaint);
  }

  void drawPixelTile(
      Canvas canvas, List<List<bool>> art, int x, int y, double size, Paint p) {
    double pixelSize = size / 4;
    for (int py = 0; py < 4; py++) {
      for (int px = 0; px < 4; px++) {
        if (art[py][px]) {
          canvas.drawRect(
              Rect.fromLTWH(x * size + px * pixelSize,
                      y * size + py * pixelSize, pixelSize, pixelSize)
                  .deflate(.1),
              p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SnakePainter old) =>
      old.height != height ||
      old.width != width ||
      old.snake != snake ||
      old.snakeDirection != snakeDirection ||
      old.apple != apple;
}
