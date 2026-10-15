import QtQuick
import org.kde.plasma.private.battery
import org.kde.plasma.private.batterymonitor

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

    function setProfile(profile) {
        if (profile !== profiles.activeProfile)
            profiles.setProfile(profile)
    }

    BatteryControlModel { id: battery }
    PowerProfilesControl {
        id: profiles
        isSilent: true
    }
}
