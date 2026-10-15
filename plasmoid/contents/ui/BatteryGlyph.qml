import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: glyph
    property int percent: 0
    property bool charging: false
    property color tone: Kirigami.Theme.textColor
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real px: Math.max(1, Math.round(dpr)) / dpr
    readonly property real bodyHeight: Math.round(Kirigami.Units.iconSizes.small * 0.55 * dpr) / dpr
    readonly property real bodyWidth: Math.round(Kirigami.Units.iconSizes.small * 1.15 * dpr) / dpr
    readonly property color fill: charging ? Kirigami.Theme.positiveTextColor
        : percent <= 10 ? Kirigami.Theme.negativeTextColor
        : percent <= 20 ? Kirigami.Theme.neutralTextColor
        : tone
    implicitWidth: bodyWidth + px * 2
    implicitHeight: bodyHeight

    Rectangle {
        id: body
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
