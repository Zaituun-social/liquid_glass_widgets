import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'liquid_morph_physics.dart';

/// Where the two blobs of a liquid morph sit on one frame, in the caller's
/// coordinate space.
///
/// Draw [anchor] (scaled by [anchorScale] about its centre) and [body] as two
/// grouped glass shapes in one blend layer, with the layer's blend set to the
/// state's [LiquidMorphState.blend]: the body detaches from the anchor and
/// inflates into its destination, joined by a liquid bridge while they
/// overlap.
@immutable
class LiquidMorphFrame {
  /// Creates a frame.
  const LiquidMorphFrame({
    required this.anchor,
    required this.anchorScale,
    required this.body,
    required this.bodyRadius,
  });

  /// The ghost of the trigger the morph leaves from, nudged by the closing
  /// bounce.
  final Rect anchor;

  /// How much of the anchor is left, 1 to 0; it shrinks away early so the
  /// bridge breaks cleanly.
  final double anchorScale;

  /// The travelling body, growing from the trigger's size to the
  /// destination's.
  final Rect body;

  /// The body's corner radius on this frame.
  final double bodyRadius;
}

/// The geometry [GlassMenu] gives its two blobs, for any widget that morphs
/// a trigger into a larger glass surface with a [GlassMorphController].
///
/// Pair it with the controller: compute [LiquidMorphState] with
/// `controller.computeState(finalDx: travel.dx, finalDy: travel.dy)`, then
/// resolve the frame here.
abstract final class LiquidMorphGeometry {
  /// The most a large surface's pinned edge drifts from the trigger while
  /// opening, in logical pixels.
  static const double maxAnchorDrift = 8.0;

  /// The frame for [state].
  ///
  /// [from] is the trigger's rect and [fromRadius] its corner radius; [toSize]
  /// and [toRadius] are the destination's. [travel] is how far the
  /// destination's centre lies from the trigger's (the `finalDx` and
  /// `finalDy` the state was computed with). [closing] is the controller's
  /// `isClosing`. [premium] says whether the blend renders (premium quality
  /// on a renderer that supports shaders): without it a close collapses as a
  /// single shape straight into the trigger, with no gap to bridge. With
  /// [fromZero] the body grows from a point at the trigger's centre instead
  /// of from its size.
  static LiquidMorphFrame resolve({
    required LiquidMorphState state,
    required Rect from,
    required double fromRadius,
    required Size toSize,
    required double toRadius,
    required Offset travel,
    required bool closing,
    required bool premium,
    bool fromZero = false,
  }) {
    final startW = fromZero ? 0.0 : from.width;
    final startH = fromZero ? 0.0 : from.height;

    // During the close undershoot (sizeT < 0) the body squeezes relative to
    // the trigger's size; lerping against the destination would collapse it.
    final height = state.sizeT < 0.0
        ? (startH * (1.0 + state.sizeT * 0.25)).clamp(1.0, double.infinity)
        : lerpDouble(startH, toSize.height, state.sizeT)!
            .clamp(0.0, double.infinity);
    final width = state.sizeT < 0.0
        ? (startW * (1.0 + state.sizeT * 0.25)).clamp(1.0, double.infinity)
        : lerpDouble(startW, toSize.width, state.sizeT)!
            .clamp(0.0, double.infinity);

    final maxRadius = math.min(width, height) / 2.0;
    final radiusT = Curves.easeInExpo.transform(state.sizeT.clamp(0.0, 1.0));
    final radius = closing
        ? (premium ? maxRadius : lerpDouble(fromRadius, toRadius, radiusT)!)
        : lerpDouble(maxRadius, toRadius, radiusT)!;

    final double dx;
    final double dy;
    if (closing) {
      // Premium: the droplet travels the centroid path back to the trigger,
      // leaving a gap for the bridge to form on approach. Otherwise it
      // collapses straight into the trigger's bounds.
      final t = premium ? state.pathT : state.sizeT;
      dx = travel.dx * t;
      dy = travel.dy * t;
    } else {
      // A large surface's pinned edge never drifts more than
      // [maxAnchorDrift] from the trigger in flight.
      final driftX = (travel.dx * (state.pathT - state.sizeT)).clamp(
        -maxAnchorDrift,
        maxAnchorDrift,
      );
      final driftY = (travel.dy * (state.pathT - state.sizeT)).clamp(
        -maxAnchorDrift,
        maxAnchorDrift,
      );
      dx = travel.dx * state.sizeT + driftX;
      dy = travel.dy * state.sizeT + driftY;
    }

    final centre = from.center + Offset(dx, dy);
    return LiquidMorphFrame(
      anchor: from.shift(Offset(state.pushDx, state.pushDy)),
      anchorScale: state.anchorScale,
      body: Rect.fromCenter(center: centre, width: width, height: height),
      bodyRadius: radius,
    );
  }
}
