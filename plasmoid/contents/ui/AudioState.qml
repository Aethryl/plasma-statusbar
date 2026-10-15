import QtQuick
import org.kde.plasma.private.volume as Vol

QtObject {
    readonly property var sink: Vol.PreferredDevice.sink
    readonly property bool available: !!sink && sink.name !== "auto_null"
    readonly property real normal: Vol.PulseAudio.NormalVolume
    readonly property int percent: available ? Math.round(sink.volume / normal * 100) : 0
    readonly property bool muted: !available || sink.muted
    readonly property string icon: muted || percent <= 0 ? "audio-volume-muted-symbolic"
        : percent <= 25 ? "audio-volume-low-symbolic"
        : percent <= 75 ? "audio-volume-medium-symbolic"
        : "audio-volume-high-symbolic"

    function setPercent(value) {
        if (!available)
            return
        sink.volume = Math.round(normal * Math.max(0, Math.min(100, value)) / 100)
        if (sink.muted && value > 0)
            sink.muted = false
    }

    function toggleMute() {
        if (available)
            sink.muted = !sink.muted
    }
}
