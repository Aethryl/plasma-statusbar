import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.sessions
import org.kde.kirigami as Kirigami

RowLayout {
    id: sessionRow
    property string armed: ""
    signal done()
    spacing: Kirigami.Units.smallSpacing

    function disarm() {
        armed = ""
    }

    function confirm(action, run) {
        if (armed === action) {
            armed = ""
            done()
            run()
        } else {
            armed = action
            disarmTimer.restart()
        }
    }

    SessionManagement { id: session }

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: sessionRow.armed = ""
    }

    Caption {
        text: "Session"
        Layout.fillWidth: true
    }
    IconAction {
        visible: session.canLock
        icon: "system-lock-screen-symbolic"
        hint: "Lock"
        onClicked: {
            sessionRow.done()
            session.lock()
        }
    }
    IconAction {
        visible: session.canSuspend
        icon: "system-suspend-symbolic"
        hint: "Sleep"
        onClicked: {
            sessionRow.done()
            session.suspend()
        }
    }
    IconAction {
        visible: session.canLogout
        icon: "system-log-out-symbolic"
        tone: Kirigami.Theme.neutralTextColor
        alert: sessionRow.armed === "logout"
        label: alert ? "Log out?" : ""
        hint: alert ? "Click again to log out" : "Log out"
        onClicked: sessionRow.confirm("logout", () => session.requestLogout(SessionManagement.Skip))
    }
    IconAction {
        visible: session.canShutdown
        icon: "system-shutdown-symbolic"
        tone: Kirigami.Theme.negativeTextColor
        alert: sessionRow.armed === "shutdown"
        label: alert ? "Power off?" : ""
        hint: alert ? "Click again to power off" : "Power off"
        onClicked: sessionRow.confirm("shutdown", () => session.requestShutdown(SessionManagement.Skip))
    }
}
