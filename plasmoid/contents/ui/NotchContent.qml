import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: content
    required property var net
    required property var audio
    required property var power
    property bool active: false
    signal close()
    spacing: Kirigami.Units.largeSpacing

    onActiveChanged: if (!active) session.disarm()

    NetworkSection {
        net: content.net
        Layout.fillWidth: true
    }
    Hairline {}
    BluetoothSection {
        Layout.fillWidth: true
    }
    Hairline {}
    VolumeSection {
        audio: content.audio
        Layout.fillWidth: true
    }
    BrightnessSection {
        id: brightness
        active: content.active
        Layout.fillWidth: true
    }
    Hairline {}
    BatterySection {
        power: content.power
        Layout.fillWidth: true
    }
    Hairline {}
    SessionRow {
        id: session
        Layout.fillWidth: true
        onDone: content.close()
    }
}
