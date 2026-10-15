import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.Label {
    id: link
    signal clicked()
    color: linkHover.containsMouse ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
    font.pointSize: Kirigami.Theme.smallFont.pointSize
    MouseArea {
        id: linkHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: link.clicked()
    }
}
