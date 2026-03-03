class BanknoteRange {
  final int from;
  final int to;

  const BanknoteRange({
    required this.from,
    required this.to,
  });

  bool contains(int serial) => serial >= from && serial <= to;

  String get rangeString => '$from - $to';
}
