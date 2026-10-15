import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: vpn
    property bool open: false
    readonly property string script: Qt.resolvedUrl("../code/vpn.py").toString().replace("file://", "")
    readonly property string command: "python3 '" + script + "' status"
    property var entries: []
    property var busy: ({})
    property string error: ""
    property bool loaded: false
    readonly property bool anyActive: entries.some(e => e.active)
    readonly property int activeCount: entries.filter(e => e.active).length

    function key(entry) {
        return entry.kind + ":" + entry.id
    }

    function refresh() {
        exec.connectSource(command)
    }

    function setActive(entry, up) {
        const k = key(entry)
        if (busy[k] !== undefined)
            return
        const next = Object.assign({}, busy)
        next[k] = up
        busy = next
        error = ""
        exec.connectSource("python3 '" + script + "' " + (up ? "up " : "down ") + entry.kind + " '" + entry.id + "' #" + k)
    }

    function launch(cmd) {
        exec.connectSource("setsid -f " + cmd + " >/dev/null 2>&1")
    }

    onOpenChanged: if (open) refresh()

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, output) => {
            disconnectSource(source)
            let parsed = null
            try {
                parsed = JSON.parse(output["stdout"])
            } catch (e) {}
            if (source === vpn.command) {
                if (parsed) {
                    vpn.entries = parsed.vpns || []
                    vpn.loaded = true
                }
                return
            }
            const marker = source.lastIndexOf(" #")
            if (marker < 0)
                return
            const next = Object.assign({}, vpn.busy)
            delete next[source.slice(marker + 2)]
            vpn.busy = next
            if (parsed && !parsed.ok)
                vpn.error = parsed.error || "Failed"
            vpn.refresh()
        }
    }

    Timer {
        interval: vpn.open ? 10000 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: vpn.refresh()
    }
}
