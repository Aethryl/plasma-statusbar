import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.Label {
    id: clock
    property date now: new Date()
    text: now.toLocaleString(Qt.locale(), "ddd d") + " · " + now.toLocaleString(Qt.locale(), "HH:mm")
    font.features: { "tnum": 1 }

    Timer {
        id: tick
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            clock.now = new Date()
            interval = (60 - clock.now.getSeconds()) * 1000 - clock.now.getMilliseconds() + 50
        }
        Component.onCompleted: triggered()
    }
}
