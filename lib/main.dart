import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

Color pixelColor = Color.fromARGB(255, 32, 65, 0);

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
  Coord apple;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    width = 20;
    height = 20;
    snake = [Coord(5, 3), Coord(4, 3), Coord(3, 3)];
    apple = _getCoordForApple();
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
      Coord newHead = snake.first.getNeighbor(snakeDirection);
      int tailLength = snake.length - 1;
      if (apple == newHead) {
        tailLength++;
        apple = null;
      }
      snake = [newHead, ...snake.take(tailLength)];
      if (apple == null) {
        apple = _getCoordForApple();
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
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 168, 214, 0),
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: pixelColor, width: 4)),
                  child: AspectRatio(
                      aspectRatio: width / height,
                      child: CustomPaint(
                          painter: SnakePainter(
                              width: width,
                              height: height,
                              snake: snake,
                              snakeDirection: snakeDirection,
                              apple: apple)))),
            )),
      ),
    );
  }
}

enum PixelArt {
  snakeHead,
  snakeHeadWithMouthOpen,
  snakeBody,
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

List<List<bool>> getBodySegment(List<Coord> snake, int segment) {
  Coord closerToHead = snake[segment - 1];
  Coord curr = snake[segment];
  Coord closerToTail = snake[segment + 1];
  if (closerToHead.y == closerToTail.y) {
    if (closerToHead.x > closerToTail.x) {
      return pixelArt[PixelArt.snakeBody];
    } else {
      return flipH(pixelArt[PixelArt.snakeBody]);
    }
  } else if (closerToHead.x == closerToTail.x) {
    if (closerToHead.y < closerToTail.y) {
      return flipV(rotCCW(pixelArt[PixelArt.snakeBody]));
    } else {
      return rotCCW(pixelArt[PixelArt.snakeBody]);
    }
  } else if (closerToHead.y < curr.y) {
    if (closerToTail.x > curr.x) {
      return flipV(pixelArt[PixelArt.snakeBodyTurn]);
    } else {
      return flipV(flipH(pixelArt[PixelArt.snakeBodyTurn]));
    }
  } else if (closerToHead.y > curr.y) {
    if (closerToTail.x < curr.x) {
      return flipH(pixelArt[PixelArt.snakeBodyTurn]);
    } else {
      return pixelArt[PixelArt.snakeBodyTurn];
    }
  } else if (closerToHead.x < curr.x) {
    if (closerToTail.y < curr.y) {
      return flipV(flipH(pixelArt[PixelArt.snakeBodyTurn]));
    } else {
      return flipH(pixelArt[PixelArt.snakeBodyTurn]);
    }
  } else if (closerToHead.x > curr.x) {
    if (closerToTail.y < curr.y) {
      return flipV(pixelArt[PixelArt.snakeBodyTurn]);
    } else {
      return pixelArt[PixelArt.snakeBodyTurn];
    }
  }
  return pixelArt[PixelArt.snakeBody];
}

List<List<bool>> getTail(List<Coord> snake) {
  Coord tail = snake.last;
  Coord prev = snake[snake.length - 2];
  if (prev.x > tail.x) {
    return pixelArt[PixelArt.snakeTail];
  } else if (prev.x < tail.x) {
    return flipH(pixelArt[PixelArt.snakeTail]);
  } else if (prev.y > tail.y) {
    return flipV(rotCCW(pixelArt[PixelArt.snakeTail]));
  } else {
    return rotCCW(pixelArt[PixelArt.snakeTail]);
  }
}

class SnakePainter extends CustomPainter {
  final int width;
  final int height;
  final List<Coord> snake;
  final Direction snakeDirection;
  final Coord apple;

  SnakePainter(
      {this.width, this.height, this.snake, this.snakeDirection, this.apple});
  @override
  void paint(Canvas canvas, Size size) {
    Paint pixelPaint = Paint()..color = Color.fromARGB(255, 32, 65, 0);
    double tileSize = size.width / width;
    drawPixelTile(
        canvas,
        faceDirection(pixelArt[PixelArt.snakeHead], snakeDirection),
        snake.first.x,
        snake.first.y,
        tileSize,
        pixelPaint);
    for (int segment = 1; segment < snake.length - 1; segment++) {
      drawPixelTile(canvas, getBodySegment(snake, segment), snake[segment].x,
          snake[segment].y, tileSize, pixelPaint);
    }
    drawPixelTile(canvas, getTail(snake), snake.last.x, snake.last.y, tileSize,
        pixelPaint);
    drawPixelTile(canvas, pixelArt[PixelArt.apple], apple.x, apple.y, tileSize,
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
