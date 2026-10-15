import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: iconAction
    property string icon
    property string label
    property string hint
    property color tone: Kirigami.Theme.textColor
    property bool alert: false
    signal clicked()
    implicitWidth: iconActionRow.implicitWidth + Kirigami.Units.smallSpacing * 3
    implicitHeight: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 3
    radius: Kirigami.Units.cornerRadius
    color: alert ? tone : Qt.alpha(tone, iconActionHover.containsMouse ? 0.3 : 0.15)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

    RowLayout {
        id: iconActionRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        Kirigami.Icon {
            source: iconAction.icon
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            color: iconAction.alert ? Kirigami.Theme.highlightedTextColor : iconAction.tone
            isMask: true
        }
        PlasmaComponents.Label {
            visible: text !== ""
            text: iconAction.label
            color: iconAction.alert ? Kirigami.Theme.highlightedTextColor : iconAction.tone
        }
    }
    MouseArea {
        id: iconActionHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: iconAction.clicked()
    }
    PlasmaComponents.ToolTip {
        text: iconAction.hint
        visible: iconActionHover.containsMouse && text !== ""
        delay: Kirigami.Units.toolTipDelay
    }
}
