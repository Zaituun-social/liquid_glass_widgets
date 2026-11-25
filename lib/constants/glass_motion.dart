import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The motion the package's own surfaces move with, for app chrome that
/// should move the same way.
///
/// [GlassTabBar] and [GlassModalSheet] read these; a widget built from the
/// package's primitives can too, instead of choosing its own springs.
abstract final class GlassMotion {
  /// The tab bar's pills: their widths and positions as the bar minimizes,
  /// expands, or opens its search field. Retarget it with the axis's
  /// in-flight velocity so a reversal mid-way carries on instead of
  /// stalling.
  static const SpringDescription tabBarSpring = SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 30.0,
  );

  /// How much the tab bar's pills blend, all the time: neighbours close
  /// enough pull towards each other like liquid.
  static const double tabBarBlend = 10.0;

  /// The most two glass shapes blend while one buds from or merges into
  /// the other, midway through (see [budBlendAt]); the navigation shell's
  /// pinned chrome buds this way.
  static const double budBlend = 20.0;

  /// The blend of the layer two shapes share at position [t] (0 to 1) of a
  /// bud or merge: none at rest at either end, where it would swell the
  /// partner's edge, and the most as a bridge between them midway.
  static double budBlendAt(double t) => budBlend * math.sin(math.pi * t);

  /// The tab bar's accessory moving between its row above the bar and its
  /// place inline beside it.
  static const Duration accessoryDuration = Duration(milliseconds: 300);

  /// See [accessoryDuration].
  static const Curve accessoryCurve = Curves.easeOutCubic;

  /// A sheet settling on a detent after a drag or a snap, carrying the
  /// release velocity.
  static const SpringDescription sheetSnapSpring = SpringDescription(
    mass: 1.0,
    stiffness: 220.0,
    damping: 30.0,
  );

  /// How far into a sheet's travel from its peek its shape has settled:
  /// width, margins and corners reach their open values by this fraction,
  /// on [sheetShapeCurve], and only its height moves after.
  static const double sheetShapeSettle = 0.15;

  /// See [sheetShapeSettle].
  static const Curve sheetShapeCurve = Curves.easeOut;

  /// How much of a drag past its ends a sheet follows.
  static const double sheetResistance = 0.08;

  /// A flick faster than this, in logical pixels a second, sends a sheet
  /// to the next detent in its direction, wherever it is.
  static const double sheetFlickVelocity = 700.0;

  /// Released slower than [sheetFlickVelocity], a sheet goes to the next
  /// detent once past this share of the way to it.
  static const double sheetSnapThreshold = 0.4;

  /// [position] dragged past [min] or [max] gives way by only [resistance]
  /// of the overflow, as a sheet does at its ends.
  static double resist(
    double position, {
    required double min,
    required double max,
    double resistance = sheetResistance,
  }) {
    if (position < min) return min - (min - position) * resistance;
    if (position > max) return max + (position - max) * resistance;
    return position;
  }

  /// The share of a sheet's shape change done at [travel] (0 to 1) of its
  /// way open (see [sheetShapeSettle]).
  static double sheetShapeAt(double travel) => sheetShapeCurve.transform(
        (travel / sheetShapeSettle).clamp(0.0, 1.0),
      );
}
