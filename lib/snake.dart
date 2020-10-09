import 'dart:ui';

import 'package:flutter/material.dart';

class SnakeModel {
  final Offset head;
  final double length;
  final List<Offset> points;

  SnakeModel({this.head, this.length, this.points});
}

class _SnakePainter extends CustomPainter {
  final SnakeModel snake;
  final int boardColumns;
  final int boardRows;

  _SnakePainter(this.snake, this.boardColumns, this.boardRows);

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = size.width / boardColumns;
    Paint snakePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tileSize;

    Path snakePath = Path()
      ..moveTo(snake.head.dx * tileSize, snake.head.dy * tileSize);
    Offset lastPoint = snake.head;
    double remainingLength = snake.length;

    for (var point in snake.points) {
      double segmentLength = (point - lastPoint).distance;
      if (segmentLength < remainingLength) {
        snakePath.lineTo(point.dx * tileSize, point.dy * tileSize);
        remainingLength -= segmentLength;
      } else {
        double segmentDirection = (point - lastPoint).direction;
        Offset newPoint =
            lastPoint + Offset.fromDirection(segmentDirection, remainingLength);
        snakePath.lineTo(newPoint.dx * tileSize, newPoint.dy * tileSize);
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
