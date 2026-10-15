import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: compact
    required property var net
    required property var audio
    required property var power
    property bool open: false
    signal toggle()
    spacing: Kirigami.Units.largeSpacing

    TrayRow {
        id: tray
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        visible: tray.shown > 0
        Layout.preferredWidth: 1
        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
        Layout.alignment: Qt.AlignVCenter
        color: Kirigami.Theme.disabledTextColor
    }

    MouseArea {
        id: glyphs
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: glyphRow.implicitWidth
        Layout.preferredHeight: Math.max(glyphRow.implicitHeight, Kirigami.Units.iconSizes.small)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: compact.toggle()

        RowLayout {
            id: glyphRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 2.5
            opacity: glyphs.containsMouse || compact.open ? 1 : 0.9

            WifiGlyph {
                visible: !compact.net.wired && compact.net.wirelessAvailable
                level: compact.net.bars
                connected: compact.net.online
                tone: compact.net.connecting ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
                Layout.alignment: Qt.AlignVCenter
            }
            Kirigami.Icon {
                visible: compact.net.wired || !compact.net.wirelessAvailable
                source: compact.net.wired ? "network-wired-symbolic" : "network-offline-symbolic"
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
                Layout.alignment: Qt.AlignVCenter
            }
        }

        PlasmaComponents.ToolTip {
            visible: glyphs.containsMouse && !compact.open
            delay: Kirigami.Units.toolTipDelay
            text: [
                compact.net.online ? (compact.net.wired ? "Wired" : compact.net.name + " · " + compact.net.strength + "%") : "Offline",
                compact.audio.muted ? "Muted" : "Volume " + compact.audio.percent + "%",
                compact.power.hasBattery ? "Battery " + compact.power.percent + "% · " + compact.power.status : ""
            ].filter(s => s).join("\n")
        }
    }
}
