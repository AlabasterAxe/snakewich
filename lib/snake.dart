import 'dart:ui';

import 'package:flutter/material.dart';

class SnakeModel {
  final Offset head;
  final double length;
  final List<Offset> points;

  SnakeModel({this.head, this.length, this.points});

  Offset get direction {
    return Offset.fromDirection((head - points.first).direction);
  }
}

class _SnakePainter extends CustomPainter {
  final SnakeModel snake;
  final int boardColumns;
  final int boardRows;

  _SnakePainter(this.snake, this.boardColumns, this.boardRows);

  Offset bToP(Offset offset, Size size) {
    double tileSize = size.width / boardColumns;
    return offset * tileSize + Offset(tileSize / 2, tileSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = size.width / boardColumns;
    Paint tileColor = Paint()
      ..color = Colors.red[200]
      ..style = PaintingStyle.fill;

    for (int y = 0; y < this.boardRows; y++) {
      for (int x = 0; x < this.boardColumns; x++) {
        canvas.drawRect(
            Rect.fromCenter(
                    center: bToP(Offset(x.toDouble(), y.toDouble()), size),
                    width: tileSize,
                    height: tileSize)
                .deflate(2),
            tileColor);
      }
    }
    Paint snakePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tileSize;

    Offset snakeHeadPixel = bToP(snake.head, size);
    Path snakePath = Path()..moveTo(snakeHeadPixel.dx, snakeHeadPixel.dy);
    Offset lastPoint = snake.head;
    double remainingLength = snake.length;

    for (var point in snake.points) {
      double segmentLength = (point - lastPoint).distance;
      if (segmentLength < remainingLength) {
        Offset snakePointPixel = bToP(point, size);
        snakePath.lineTo(snakePointPixel.dx, snakePointPixel.dy);
        remainingLength -= segmentLength;
      } else {
        double segmentDirection = (point - lastPoint).direction;
        Offset newPointPixels = bToP(
            lastPoint + Offset.fromDirection(segmentDirection, remainingLength),
            size);
        snakePath.lineTo(newPointPixels.dx, newPointPixels.dy);
        break;
      }
      lastPoint = point;
    }

    canvas.drawPath(snakePath, snakePaint);
  }

  @override
  bool shouldRepaint(_SnakePainter oldDelegate) {
    return true;
  }
}

class SnakeWidget extends StatelessWidget {
  final SnakeModel snake;
  final int boardColumns;
  final int boardRows;
  const SnakeWidget({Key key, this.snake, this.boardColumns, this.boardRows})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: _SnakePainter(snake, boardColumns, boardRows),
      ),
    );
  }
}
