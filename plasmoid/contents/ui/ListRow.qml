import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: listRow
    property string icon
    property string fallbackIcon
    property string text
    property string detail
    property bool current: false
    property bool busy: false
    default property alias trailing: trailingSlot.data
    signal clicked()
    Layout.fillWidth: true
    implicitWidth: rowLayout.implicitWidth + Kirigami.Units.smallSpacing * 3
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.4)
    radius: Kirigami.Units.cornerRadius
    color: hover.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.25) : "transparent"

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: listRow.clicked()
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 1.5
        anchors.rightMargin: Kirigami.Units.smallSpacing * 1.5
        spacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            visible: listRow.icon !== ""
            source: listRow.icon
            fallback: listRow.fallbackIcon
            isMask: true
            color: listRow.current ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: listRow.text
            elide: Text.ElideRight
            font.weight: listRow.current ? Font.DemiBold : Font.Normal
            opacity: listRow.busy ? 0.6 : 1
        }
        PlasmaComponents.Label {
            visible: text !== ""
            text: listRow.detail
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.features: { "tnum": 1 }
        }
        RowLayout {
            id: trailingSlot
            spacing: Kirigami.Units.smallSpacing
        }
    }
}
