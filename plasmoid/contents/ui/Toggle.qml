import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: toggle
    property bool checked: false
    signal toggled()
    implicitWidth: Kirigami.Units.gridUnit * 1.8
    implicitHeight: Kirigami.Units.gridUnit
    radius: height / 2
    opacity: enabled ? 1 : 0.4
    color: checked ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, toggleHover.containsMouse ? 0.25 : 0.15)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

    Rectangle {
        readonly property real inset: Math.round(Kirigami.Units.smallSpacing / 2)
        width: parent.height - inset * 2
        height: width
        radius: width / 2
        y: inset
        x: toggle.checked ? parent.width - width - inset : inset
        color: toggle.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        Behavior on x { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: toggleHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}
