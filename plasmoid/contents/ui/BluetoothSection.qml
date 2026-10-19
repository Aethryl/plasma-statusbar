import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.bluetooth as PlasmaBt
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    readonly property bool operational: BluezQt.Manager.bluetoothOperational
    readonly property int connected: BluezQt.Manager.connectedDevices.length
    property bool expanded: false
    property bool active: false
    readonly property bool scanning: active && operational
    spacing: Kirigami.Units.smallSpacing

    function setEnabled(enable) {
        BluezQt.Manager.bluetoothBlocked = !enable
        BluezQt.Manager.adapters.forEach(adapter => {
            adapter.powered = enable
        })
    }

    SectionHeader {
        title: "Bluetooth"
        value: !section.operational ? "Off" : section.connected > 0 ? section.connected + " connected" : "On"
        valueColor: section.operational ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
        toggleVisible: BluezQt.Manager.bluetoothBlocked || BluezQt.Manager.adapters.length > 0
        checked: section.operational
        onToggled: section.setEnabled(!section.operational)
    }

    onScanningChanged: BluezQt.Manager.adapters.forEach(adapter => {
        if (!adapter.powered)
            return
        if (scanning && !adapter.discovering)
            adapter.startDiscovery()
        else if (!scanning && adapter.discovering)
            adapter.stopDiscovery()
    })

    PlasmaBt.DevicesProxyModel {
        id: devices
        hideBlockedDevices: true
        Component.onCompleted: sourceModel = PlasmaBt.SharedDevicesStateProxyModel
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: section.operational
        spacing: 0

        Repeater {
            model: section.operational ? devices : null
            ListRow {
                id: deviceRow
                required property var model
                readonly property bool nearby: model.Paired && !!model.Device && model.Device.rssi > -32768
                visible: model.Connected || nearby || (section.expanded && model.Paired)
                icon: (model.Icon || "network-bluetooth") + "-symbolic"
                fallbackIcon: "network-bluetooth-symbolic"
                text: model.DeviceFullName || model.Name
                current: model.Connected
                busy: model.Connecting || model.Disconnecting
                detail: model.Connecting ? "connecting" : model.Disconnecting ? "disconnecting"
                    : model.Connected && model.Battery ? model.Battery.percentage + "%" : model.Connected ? "connected"
                    : nearby ? "nearby" : ""
                onClicked: {
                    if (model.Connecting || model.Disconnecting)
                        return
                    if (model.Connected)
                        PlasmaBt.SharedDevicesStateProxyModel.registerDisconnectingCallForDeviceUbi(model.Device.disconnectFromDevice(), model.Ubi)
                    else
                        PlasmaBt.SharedDevicesStateProxyModel.registerConnectingCallForDeviceUbi(model.Device.connectToDevice(), model.Ubi)
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: section.operational
        spacing: Kirigami.Units.smallSpacing
        MoreLink {
            text: section.expanded ? "Hide paired devices" : "Paired devices"
            onClicked: section.expanded = !section.expanded
        }
        Item { Layout.fillWidth: true }
        MoreLink {
            text: "Settings ↗"
            onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_bluetooth")
        }
    }
}
