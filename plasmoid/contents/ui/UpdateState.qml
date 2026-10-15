import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: updates
    readonly property string script: Qt.resolvedUrl("../code/updates.py").toString().replace("file://", "")
    readonly property string command: "python3 '" + script + "'"
    readonly property string refreshCommand: "pkcon refresh >/dev/null 2>&1; " + command
    property var result: null
    property bool checking: false
    property bool refreshing: false
    readonly property bool loaded: result !== null
    readonly property int total: loaded ? result.total || 0 : 0
    readonly property int security: loaded ? result.security || 0 : 0
    readonly property int flatpak: loaded ? result.flatpak || 0 : 0
    readonly property var counts: loaded ? result.counts || ({}) : ({})
    readonly property var packages: loaded ? result.packages || [] : []
    readonly property var flatpaks: loaded ? result.flatpaks || [] : []
    readonly property string error: loaded && result.error ? result.error : ""
    readonly property string checked: loaded ? new Date(result.checked * 1000).toLocaleString(Qt.locale(), "HH:mm") : ""
    readonly property string summary: total === 0 ? ""
        : total + (total === 1 ? " update" : " updates") + (security > 0 ? " (" + security + " security)" : "")

    function check() {
        if (checking || refreshing)
            return
        checking = true
        exec.connectSource(command)
    }

    function refresh() {
        if (refreshing)
            return
        refreshing = true
        exec.connectSource(refreshCommand)
    }

    function launch(cmd) {
        exec.connectSource("setsid -f " + cmd + " >/dev/null 2>&1")
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, output) => {
            disconnectSource(source)
            if (source === updates.command)
                updates.checking = false
            else if (source === updates.refreshCommand)
                updates.refreshing = false
            else
                return
            try {
                updates.result = JSON.parse(output["stdout"])
            } catch (e) {}
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updates.check()
    }
}
