import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: header
    property string title
    property string value
    property color valueColor: Kirigami.Theme.textColor
    property bool toggleVisible: false
    property bool checked: false
    property bool toggleEnabled: true
    signal toggled()
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 2

    Caption {
        text: header.title
    }
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        text: header.value
        color: header.valueColor
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    Toggle {
        visible: header.toggleVisible
        enabled: header.toggleEnabled
        checked: header.checked
        onToggled: header.toggled()
    }
}
