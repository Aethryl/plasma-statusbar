import QtQuick
import QtQuick.Shapes
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: glyph
    property int percent: 0
    property bool charging: false
    property bool pluggedIn: false
    property color tone: Kirigami.Theme.textColor
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real px: Math.max(1, Math.round(dpr)) / dpr
    readonly property real bodyHeight: Math.round(Kirigami.Units.iconSizes.small * 0.55 * dpr) / dpr
    readonly property real bodyWidth: Math.round(Kirigami.Units.iconSizes.small * 1.15 * dpr) / dpr
    readonly property color fill: charging ? Kirigami.Theme.positiveTextColor
        : percent <= 10 ? Kirigami.Theme.negativeTextColor
        : percent <= 20 ? Kirigami.Theme.neutralTextColor
        : tone
    readonly property real boltWidth: pluggedIn ? Math.round(bodyHeight * 0.7 * dpr) / dpr : 0
    readonly property real boltGap: pluggedIn ? px * 2 : 0
    implicitWidth: boltWidth + boltGap + bodyWidth + px * 2
    implicitHeight: bodyHeight

    Shape {
        visible: glyph.pluggedIn
        width: glyph.boltWidth
        height: glyph.bodyHeight
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Kirigami.Theme.positiveTextColor
            startX: glyph.boltWidth * 0.62; startY: 0
            PathLine { x: 0; y: glyph.bodyHeight * 0.58 }
            PathLine { x: glyph.boltWidth * 0.45; y: glyph.bodyHeight * 0.58 }
            PathLine { x: glyph.boltWidth * 0.35; y: glyph.bodyHeight }
            PathLine { x: glyph.boltWidth; y: glyph.bodyHeight * 0.4 }
            PathLine { x: glyph.boltWidth * 0.55; y: glyph.bodyHeight * 0.4 }
            PathLine { x: glyph.boltWidth * 0.62; y: 0 }
        }
    }
    Rectangle {
        id: body
        x: glyph.boltWidth + glyph.boltGap
        width: glyph.bodyWidth
        height: glyph.bodyHeight
        radius: glyph.px * 2
        color: "transparent"
        border.width: glyph.px
        border.color: Qt.alpha(glyph.tone, 0.6)

        Rectangle {
            x: glyph.px * 2
            y: glyph.px * 2
            height: parent.height - glyph.px * 4
            width: Math.max(glyph.px, Math.round((parent.width - glyph.px * 4) * Math.min(100, glyph.percent) / 100 * glyph.dpr) / glyph.dpr)
            radius: glyph.px
            color: glyph.fill
        }
    }
    Rectangle {
        anchors.left: body.right
        anchors.verticalCenter: body.verticalCenter
        width: glyph.px * 2
        height: Math.round(glyph.bodyHeight * 0.45 * glyph.dpr) / glyph.dpr
        color: Qt.alpha(glyph.tone, 0.6)
    }
}
