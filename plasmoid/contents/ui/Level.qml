import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: level
    property real value: 0
    property real from: 0
    property real to: 100
    property color fill: Kirigami.Theme.highlightColor
    signal moved(real value)
    readonly property real ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    implicitWidth: Kirigami.Units.gridUnit * 8
    implicitHeight: Kirigami.Units.gridUnit * 0.8
    opacity: enabled ? 1 : 0.4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Kirigami.Units.smallSpacing * 1.5
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        Rectangle {
            width: Math.max(parent.height, parent.width * level.ratio)
            height: parent.height
            radius: parent.radius
            color: level.fill
        }
    }
    Rectangle {
        width: level.height
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: (level.width - width) * level.ratio
        color: Kirigami.Theme.textColor
        visible: grab.containsMouse || grab.pressed
    }
    MouseArea {
        id: grab
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function apply(mouseX) {
            const r = Math.max(0, Math.min(1, mouseX / width))
            level.moved(level.from + r * (level.to - level.from))
        }
        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
        onWheel: wheel => level.moved(Math.max(level.from, Math.min(level.to, level.value + (wheel.angleDelta.y > 0 ? 1 : -1) * (level.to - level.from) / 20)))
    }
}
