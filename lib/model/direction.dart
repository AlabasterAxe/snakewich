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
