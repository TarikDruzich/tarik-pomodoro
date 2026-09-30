import QtQuick
import QtQuick.Shapes
import qs.Commons

// Progress ring: one component, two sizes (16px in the bar, 172px in the
// popup). Replaces the 8 RING_GLYPHS glyphs in Rust's render.rs, which
// existed because Waybar can only render text: a restriction of the old
// host, rather than the product.
Item {
  id: root

  property real progress: 1.0 // 1 full -> 0 empty, like the Rust disk
  property real thickness: 14
  property real size: 172
  property string phase: "work"
  property bool paused: false

  implicitWidth: size
  implicitHeight: size
  width: size
  height: size

  // One theme color, three intensities: no palette of our own. Focus uses
  // full accent, breaks use the same accent at 55%, and paused fades to
  // foreground, which stays readable in any Omarchy theme.
  // The bar renderer passes the bar color (which changes with a transparent
  // bar); the popup uses the theme tokens.
  property color baseColor: Color.foreground
  property color accentColor: Color.accent
  readonly property color fill: root.paused
    ? Util.alpha(root.baseColor, 0.55)
    : (root.phase === "work" ? root.accentColor : Util.alpha(root.accentColor, 0.55))

  // The tween animates the countdown second by second; disabled on large
  // jumps (phase change, restart, restore) so the ring does not spin halfway
  // around on screen.
  property real animatedProgress: root.progress
  Behavior on animatedProgress {
    enabled: Math.abs(root.progress - root.animatedProgress) <= 0.5
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }

  Shape {
    id: shape
    anchors.fill: parent
    // CurveRenderer stays crisp at both 16px and 172px (prototype in
    // scratchpad/proto/ring.qml + DECISION.md); Shape's default renderer
    // visibly aliases the bar's thin arc.
    preferredRendererType: Shape.CurveRenderer
    layer.enabled: true
    layer.samples: 8

    ShapePath {
      strokeWidth: root.thickness
      strokeColor: Util.alpha(root.baseColor, 0.12)
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root.size / 2 - root.thickness / 2
        radiusY: radiusX
        startAngle: -90
        sweepAngle: 360
      }
    }

    ShapePath {
      strokeWidth: root.thickness
      strokeColor: root.fill
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root.size / 2 - root.thickness / 2
        radiusY: radiusX
        startAngle: -90
        sweepAngle: 360 * root.animatedProgress
      }
    }
  }
}
