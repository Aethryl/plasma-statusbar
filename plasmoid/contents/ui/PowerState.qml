import QtQuick
import org.kde.plasma.private.battery
import org.kde.plasma.private.batterymonitor
import org.kde.plasma.plasma5support as P5Support

Item {
    id: power
    readonly property bool hasBattery: battery.hasBatteries
    readonly property int percent: battery.percent
    readonly property bool pluggedIn: battery.pluggedIn
    readonly property bool charging: pluggedIn && battery.state === BatteryControlModel.Charging
    readonly property bool full: pluggedIn && battery.state === BatteryControlModel.FullyCharged
    readonly property real remaining: battery.smoothedRemainingMsec
    readonly property int remainingMinutes: Math.round(remaining / 60000)
    readonly property string remainingText: remainingMinutes <= 0 ? ""
        : remainingMinutes < 60 ? remainingMinutes + "m"
        : Math.floor(remainingMinutes / 60) + "h " + remainingMinutes % 60 + "m"
    readonly property string status: full ? "Fully charged"
        : charging ? (remainingText !== "" ? remainingText + " until full" : "Charging")
        : pluggedIn ? "Plugged in, not charging"
        : remainingText !== "" ? remainingText + " remaining" : "On battery"
    readonly property bool hasProfiles: profiles.isPowerProfileDaemonInstalled && profiles.profiles.length > 0
    readonly property var profileList: profiles.profiles
    readonly property string activeProfile: profiles.activeProfile

    readonly property string holdScript: Qt.resolvedUrl("../code/lidhold.py").toString().replace("file://", "")
    readonly property string holdStatusCommand: "/usr/bin/python3 '" + holdScript + "' status"
    property bool holdAvailable: false
    property bool holdArmed: false
    property bool holdBusy: false
    property real holdDeadline: 0
    property real now: Date.now()
    readonly property int holdRemaining: holdArmed ? Math.max(0, Math.ceil((holdDeadline - now) / 1000)) : 0
    readonly property string holdRemainingText: Math.floor(holdRemaining / 60) + ":" + String(holdRemaining % 60).padStart(2, "0")

    function setHold(on) {
        if (holdBusy || on === holdArmed)
            return
        holdBusy = true
        holdExec.connectSource("/usr/bin/python3 '" + holdScript + "' " + (on ? "arm" : "disarm"))
    }

    function refreshHold() {
        holdExec.connectSource(holdStatusCommand)
    }

    function setProfile(profile) {
        if (profile !== profiles.activeProfile)
            profiles.setProfile(profile)
    }

    BatteryControlModel { id: battery }
    PowerProfilesControl {
        id: profiles
        isSilent: true
    }

    P5Support.DataSource {
        id: holdExec
        engine: "executable"
        onNewData: (source, output) => {
            disconnectSource(source)
            let parsed = null
            try {
                parsed = JSON.parse(output["stdout"])
            } catch (e) {}
            if (source !== power.holdStatusCommand) {
                power.holdBusy = false
                power.refreshHold()
                return
            }
            if (!parsed)
                return
            power.holdAvailable = parsed.available
            power.holdArmed = parsed.armed
            power.holdDeadline = parsed.deadline
            power.now = Date.now()
        }
    }

    Timer {
        interval: power.holdArmed ? 5000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: power.refreshHold()
    }

    Timer {
        interval: 1000
        running: power.holdArmed
        repeat: true
        onTriggered: power.now = Date.now()
    }
}
