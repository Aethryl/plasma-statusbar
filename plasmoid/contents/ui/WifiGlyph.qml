import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: glyph
    property int level: 0
    property bool connected: true
    property color tone: Kirigami.Theme.textColor
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real cell: Math.max(2, Math.round(Kirigami.Units.gridUnit * 0.17 * dpr)) / dpr
    readonly property real gap: Math.max(1, Math.round(dpr)) / dpr
    readonly property real tall: Math.round(Kirigami.Units.iconSizes.small * 0.75 * dpr) / dpr
    implicitWidth: cell * 4 + gap * 3
    implicitHeight: tall

    Row {
        anchors.bottom: parent.bottom
        spacing: glyph.gap
        Repeater {
            model: 4
            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: glyph.cell
                height: Math.round(glyph.tall * (index + 1) / 4 * glyph.dpr) / glyph.dpr
                color: glyph.connected && index < glyph.level ? glyph.tone : Qt.alpha(glyph.tone, 0.22)
            }
        }
    }
}
