class HandCommand {
  final int thumb;
  final int index;
  final int middle;
  final int ring;
  final int pinky;

  HandCommand({
    this.thumb = 0,
    this.index = 0,
    this.middle = 0,
    this.ring = 0,
    this.pinky = 0
  }) :
    assert(_isValid(thumb), 'thumb must be between 0 and 100'),
    assert(_isValid(index), 'index must be between 0 and 100'),
    assert(_isValid(middle), 'middle must be between 0 and 100'),
    assert(_isValid(ring), 'ring must be between 0 and 100'),
    assert(_isValid(pinky), 'pinky must be between 0 and 100');

  Map<String, dynamic> toJson() {
    return {
      'thumb': thumb,
      'index': index,
      'middle': middle,
      'ring': ring,
      'pinky': pinky,
    };
  }

  factory HandCommand.fromJson(Map<String, dynamic> json) {
    return HandCommand(
      thumb: json['thumb'] as int,
      index: json['index'] as int,
      middle: json['middle'] as int,
      ring: json['ring'] as int,
      pinky: json['pinky'] as int,
    );
  }

  @override
  String toString() => 'HandCommand(thumb: $thumb, index: $index, middle: $middle, ring: $ring, pinky: $pinky)';
  
  static bool _isValid(int value) => value >= 0 && value <= 100;
}