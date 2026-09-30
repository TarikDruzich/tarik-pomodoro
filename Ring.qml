import QtQuick
import QtQuick.Shapes
import qs.Commons

// Progress ring: one component, two sizes (16px in the bar, 172px in the
// popup). Modern look: soft glow, thin track, and a knob at the arc end.
// The glow and knob only appear at large sizes so the 16px bar ring stays crisp.
Item {
  id: root

  property real progress: 1.0 // 1 full -> 0 empty
  property real thickness: 10
  property real size: 172
  property string phase: "work"
  property bool paused: false

  implicitWidth: size
  implicitHeight: size
  width: size
  height: size

  property color baseColor: Color.foreground
  property color accentColor: Color.accent
  // Separate color for breaks so the phases are easy to tell apart.
  // Hardcoded, so it does not follow the theme; change it or use a theme token.
  property color breakColor: "#7bd88f"

  readonly property color fill: root.paused
    ? Util.alpha(root.baseColor, 0.55)
    : (root.phase === "work" ? root.accentColor : root.breakColor)

  // Fancy extras only when the ring is big (popup), not in the small bar.
  readonly property bool fancy: root.size > 40
  readonly property real margin: root.fancy ? root.thickness * 0.8 : 0
  readonly property real ringRadius: root.size / 2 - root.thickness / 2 - root.margin
  readonly property real center: root.size / 2

  // Smooth continuous motion between the one-second ticks; disabled on big
  // jumps (phase change, restart, restore) so the ring does not spin around.
  property real animatedProgress: root.progress
  Behavior on animatedProgress {
    enabled: Math.abs(root.progress - root.animatedProgress) <= 0.5
    NumberAnimation { duration: 950; easing.type: Easing.Linear }
  }

  Shape {
    id: shape
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    layer.enabled: true
    layer.samples: 8

    // Track (background circle)
    ShapePath {
      strokeWidth: root.thickness
      strokeColor: Util.alpha(root.baseColor, 0.14)
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.center
        centerY: root.center
        radiusX: root.ringRadius
        radiusY: root.ringRadius
        startAngle: -90
        sweepAngle: 360
      }
    }

    // Glow (wider, transparent copy of the progress arc, popup only)
    ShapePath {
      strokeWidth: root.fancy ? root.thickness + root.margin * 1.6 : -1
      strokeColor: Util.alpha(root.fill, 0.18)
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.center
        centerY: root.center
        radiusX: root.ringRadius
        radiusY: root.ringRadius
        startAngle: -90
        sweepAngle: 360 * root.animatedProgress
      }
    }

    // Progress arc
    ShapePath {
      strokeWidth: root.thickness
      strokeColor: root.fill
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.center
        centerY: root.center
        radiusX: root.ringRadius
        radiusY: root.ringRadius
        startAngle: -90
        sweepAngle: 360 * root.animatedProgress
      }
    }
  }

  // Knob at the end of the arc (popup only)
  Rectangle {
    readonly property real angle: (-90 + 360 * root.animatedProgress) * Math.PI / 180

    visible: root.fancy && root.animatedProgress > 0.01
    width: root.thickness * 0.5
    height: width
    radius: width / 2
    color: Util.alpha(root.baseColor, 0.95)
    x: root.center + root.ringRadius * Math.cos(angle) - width / 2
    y: root.center + root.ringRadius * Math.sin(angle) - height / 2
  }
}
