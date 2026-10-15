import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.dbus as DBus

RowLayout {
    id: tray
    property real iconSize: Kirigami.Units.iconSizes.small
    property var addresses: []
    readonly property int shown: visibleChildren.filter(c => c.address !== undefined).length
    spacing: Kirigami.Units.smallSpacing * 2

    function sync() {
        const list = watcher.properties.RegisteredStatusNotifierItems || []
        if (JSON.stringify(list) !== JSON.stringify(addresses))
            addresses = list
    }

    DBus.Properties {
        id: watcher
        busType: DBus.BusType.Session
        service: "org.kde.StatusNotifierWatcher"
        path: "/StatusNotifierWatcher"
        iface: "org.kde.StatusNotifierWatcher"
        onRefreshed: tray.sync()
        onPropertiesChanged: tray.sync()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: watcher.update("RegisteredStatusNotifierItems")
    }

    Repeater {
        model: tray.addresses
        TrayIcon {
            required property string modelData
            address: modelData
            iconSize: tray.iconSize
        }
    }
}
