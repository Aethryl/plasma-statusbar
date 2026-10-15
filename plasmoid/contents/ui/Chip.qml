import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: chip
    property string text
    property string icon
    property bool active: false
    signal clicked()
    implicitWidth: chipRow.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: Math.max(chipLabel.implicitHeight, Kirigami.Units.iconSizes.small) + Kirigami.Units.smallSpacing * 2
    radius: height / 2
    color: active ? Kirigami.Theme.highlightColor
        : chipHover.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.25)
        : Qt.alpha(Kirigami.Theme.textColor, 0.08)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        Kirigami.Icon {
            visible: chip.icon !== ""
            source: chip.icon
            isMask: true
            color: chipLabel.color
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }
        PlasmaComponents.Label {
            id: chipLabel
            text: chip.text
            color: chip.active ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            font.features: { "tnum": 1 }
        }
    }
    MouseArea {
        id: chipHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
