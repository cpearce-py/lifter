import 'package:flutter/material.dart';

enum GripType {
  halfCrimp("Half crimp"),
  openHand("Open hand"),
  fullCrimp("Full crimp"),
  threeFingerDrag("3-finger drag"),
  frontTwo("Front 2"),
  middleTwo("Middle 2"),
  backTwo("Back 2"),
  pinch("Pinch"),
  sloper("Sloper");

  final String label;

  const GripType(this.label);

  /// Reads a stored name, ignoring anything unknown so old or edited rows
  /// don't break loading.
  static GripType? tryParse(String? name) {
    if (name == null) return null;
    for (final g in values) {
      if (g.name == name) return g;
    }
    return null;
  }
}

/// The common edge depths on hangboards and lifting edges, in mm.
const edgeSizesMm = [6, 8, 10, 12, 14, 15, 18, 20, 22, 25, 30, 35];

/// What a set was pulled on. Either half can be left unset, e.g. a pinch
/// has no edge, and workouts logged before this existed have neither.
@immutable
class GripSetup {
  final GripType? grip;
  final int? edgeMm;

  const GripSetup({this.grip, this.edgeMm});

  static const none = GripSetup();

  bool get isSet => grip != null || edgeMm != null;

  GripSetup withGrip(GripType? grip) => GripSetup(grip: grip, edgeMm: edgeMm);
  GripSetup withEdge(int? edgeMm) => GripSetup(grip: grip, edgeMm: edgeMm);

  /// e.g. "20mm · Half crimp", "Pinch", or "" when nothing is set.
  String get label => [
        if (edgeMm != null) '${edgeMm}mm',
        if (grip != null) grip!.label,
      ].join(' · ');

  Map<String, dynamic> toMap() => {'grip': grip?.name, 'edge_mm': edgeMm};

  factory GripSetup.fromMap(Map<String, dynamic> map) => GripSetup(
        grip: GripType.tryParse(map['grip'] as String?),
        edgeMm: map['edge_mm'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is GripSetup && other.grip == grip && other.edgeMm == edgeMm;

  @override
  int get hashCode => Object.hash(grip, edgeMm);
}

/// Narrows charts to one grip and/or edge. A null half matches anything.
@immutable
class GripFilter {
  final GripType? grip;
  final int? edgeMm;

  const GripFilter({this.grip, this.edgeMm});

  static const all = GripFilter();

  bool get isAll => grip == null && edgeMm == null;

  bool matches(GripSetup setup) =>
      (grip == null || setup.grip == grip) &&
      (edgeMm == null || setup.edgeMm == edgeMm);

  GripFilter withGrip(GripType? grip) => GripFilter(grip: grip, edgeMm: edgeMm);
  GripFilter withEdge(int? edgeMm) => GripFilter(grip: grip, edgeMm: edgeMm);

  @override
  bool operator ==(Object other) =>
      other is GripFilter && other.grip == grip && other.edgeMm == edgeMm;

  @override
  int get hashCode => Object.hash(grip, edgeMm);
}
