import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: glyph
    property int strength: 0
    property bool locked: false
    property color tone: Kirigami.Theme.textColor
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real cell: Math.max(1, Math.round(Kirigami.Units.iconSizes.small / 8 * dpr)) / dpr
    readonly property int bars: strength >= 75 ? 4 : strength >= 50 ? 3 : strength >= 25 ? 2 : 1
    readonly property string suffix: locked ? "-locked.svg" : ".svg"
    implicitWidth: cell * (locked ? 12 : 9)
    implicitHeight: cell * 8

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/wifi-full" + glyph.suffix)
        isMask: true
        roundToIconSize: false
        color: Qt.alpha(glyph.tone, 0.3)
    }
    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/wifi-" + glyph.bars + glyph.suffix)
        isMask: true
        roundToIconSize: false
        color: glyph.tone
    }
}
