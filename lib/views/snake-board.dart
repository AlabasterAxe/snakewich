import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snakewich/model/direction.dart';

class SnakeBoardTile {
  final int x;
  final int y;

  Map<Direction, SnakeBoardTile> neighbors = {};

  SnakeBoardTile(this.x, this.y);

  SnakeBoardTile getNeighbor(Direction d) =>
      neighbors.containsKey(d) ? neighbors[d] : null;
}

class SnakeBoard {
  final int width;
  final int height;
  final List<List<SnakeBoardTile>> tiles;

  SnakeBoard(this.width, this.height)
      : tiles = List.generate(
            height, (y) => List.generate(width, (x) => SnakeBoardTile(x, y))) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        SnakeBoardTile tile = tiles[y][x];
        if (x > 0) {
          tile.neighbors[Direction.west] = tiles[y][x - 1];
        }
        if (y > 0) {
          tile.neighbors[Direction.north] = tiles[y - 1][x];
        }
        if (x < tiles[y].length - 1) {
          tile.neighbors[Direction.east] = tiles[y][x + 1];
        }
        if (y < tiles.length - 1) {
          tile.neighbors[Direction.south] = tiles[y + 1][x];
        }
      }
    }
  }
}

class SnakePainter extends CustomPainter {
  final SnakeBoard board;
  final List<SnakeBoardTile> snake;
  final List<SnakeBoardTile> apples;

  SnakePainter({this.board, this.snake, this.apples});
  @override
  void paint(Canvas canvas, Size size) {
    Paint tileColor = Paint()
      ..color = Colors.red[200]
      ..style = PaintingStyle.fill;
    Paint snakeColor = Paint()
      ..color = Colors.green[200]
      ..style = PaintingStyle.fill;
    Paint appleColor = Paint()
      ..color = Colors.red.shade800
      ..style = PaintingStyle.fill;
    double tileSize = size.width / board.tiles[0].length;
    for (List<SnakeBoardTile> row in board.tiles) {
      for (SnakeBoardTile t in row) {
        canvas.drawRect(
            Rect.fromLTWH(t.x * tileSize, t.y * tileSize, tileSize, tileSize)
                .deflate(2),
            tileColor);
      }
    }
    for (SnakeBoardTile snake in snake) {
      canvas.drawRect(
          Rect.fromLTWH(
                  snake.x * tileSize, snake.y * tileSize, tileSize, tileSize)
              .deflate(2),
          snakeColor);
    }
    for (SnakeBoardTile apple in apples) {
      canvas.drawRect(
          Rect.fromLTWH(
                  apple.x * tileSize, apple.y * tileSize, tileSize, tileSize)
              .deflate(3),
          appleColor);
    }
  }

  @override
  bool shouldRepaint(SnakePainter old) {
    return true;
  }
}
