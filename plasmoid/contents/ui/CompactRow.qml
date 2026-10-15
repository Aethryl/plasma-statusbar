import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami

RowLayout {
    id: compact
    required property var net
    required property var audio
    required property var power
    required property var updates
    required property var vpn
    property bool open: false
    signal toggle()
    spacing: Kirigami.Units.largeSpacing

    MouseArea {
        id: glyphs
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: glyphRow.implicitWidth
        Layout.preferredHeight: Math.max(glyphRow.implicitHeight, Kirigami.Units.iconSizes.small)
        hoverEnabled: true
        onClicked: compact.toggle()

        RowLayout {
            id: glyphRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing * 1.5
            opacity: glyphs.containsMouse || compact.open ? 1 : 0.9

            Kirigami.Icon {
                visible: compact.updates.total > 0
                source: Qt.resolvedUrl("../images/update.svg")
                isMask: true
                color: compact.updates.security > 0 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Icon {
                source: compact.net.icon
                isMask: true
                color: compact.net.connecting ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Icon {
                visible: compact.vpn.anyActive
                source: "network-vpn-symbolic"
                isMask: true
                color: Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Icon {
                visible: BluezQt.Manager.bluetoothOperational
                source: BluezQt.Manager.connectedDevices.length > 0 ? "network-bluetooth-activated-symbolic" : "network-bluetooth-symbolic"
                isMask: true
                color: BluezQt.Manager.connectedDevices.length > 0 ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Icon {
                source: compact.audio.icon
                isMask: true
                color: compact.audio.muted ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            BatteryGlyph {
                visible: compact.power.hasBattery
                percent: compact.power.percent
                charging: compact.power.charging
                Layout.alignment: Qt.AlignVCenter
            }
            Clock {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
