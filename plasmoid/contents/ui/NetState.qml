import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

Item {
    id: net
    property bool scanning: false
    readonly property alias handler: handler
    readonly property alias model: proxy
    readonly property bool wirelessAvailable: devices.wirelessDeviceAvailable
    readonly property bool wirelessEnabled: enabledConnections.wirelessEnabled
    readonly property bool wirelessToggleable: !PlasmaNM.Configuration.airplaneModeEnabled && devices.wirelessDeviceAvailable && enabledConnections.wirelessHwEnabled
    readonly property bool connecting: connectionIcon.connecting
    readonly property string icon: connectionIcon.connectionIcon
    readonly property var primary: {
        let wifi = null
        for (let i = 0; i < rows.count; i++) {
            const row = rows.objectAt(i)
            if (!row || !row.activated)
                continue
            if (row.type === PlasmaNM.Enums.Wired)
                return row
            if (row.type === PlasmaNM.Enums.Wireless && !wifi)
                wifi = row
        }
        return wifi
    }
    readonly property bool online: primary !== null
    readonly property bool wired: online && primary.type === PlasmaNM.Enums.Wired
    readonly property string name: online ? primary.name : ""
    readonly property int strength: online && !wired ? primary.strength : 0

    function setWireless(on) {
        handler.enableWireless(on)
    }

    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkStatus { id: status }
    PlasmaNM.ConnectionIcon {
        id: connectionIcon
        connectivity: status.connectivity
    }
    PlasmaNM.Handler { id: handler }
    PlasmaNM.NetworkModel { id: networkModel }
    PlasmaNM.AppletProxyModel {
        id: proxy
        sourceModel: networkModel
    }

    Instantiator {
        id: rows
        model: proxy
        delegate: QtObject {
            required property var model
            readonly property bool activated: model.ConnectionState === PlasmaNM.Enums.Activated
            readonly property int type: model.Type
            readonly property string name: model.ItemUniqueName
            readonly property int strength: model.Signal || 0
        }
    }

    Timer {
        interval: 10200
        repeat: true
        triggeredOnStart: true
        running: net.scanning && net.wirelessEnabled && !PlasmaNM.Configuration.airplaneModeEnabled
        onTriggered: handler.requestScan()
    }
}
