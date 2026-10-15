import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: trayIcon
    required property string address
    property real iconSize: Kirigami.Units.iconSizes.small

    readonly property int slash: address.indexOf("/")
    readonly property string service: slash > 0 ? address.slice(0, slash) : address
    readonly property string objectPath: slash > 0 ? address.slice(slash) : "/StatusNotifierItem"
    readonly property var props: item.properties
    readonly property string status: plain(props.Status) || ""
    readonly property bool attention: status === "NeedsAttention"
    readonly property string iconName: plain(attention && plain(props.AttentionIconName) ? props.AttentionIconName : props.IconName) || ""
    readonly property string themePath: plain(props.IconThemePath) || ""
    readonly property var pixmaps: attention && hasPixmap(props.AttentionIconPixmap) ? props.AttentionIconPixmap : props.IconPixmap
    readonly property string menuPath: plain(props.Menu) || ""
    readonly property bool hasMenu: menuPath !== "" && menuPath !== "/" && menuPath !== "/NO_DBUSMENU"
    readonly property string title: {
        const tip = props.ToolTip
        const tipTitle = tip && tip.length > 2 ? plain(tip[2]) : ""
        return plain(props.Title) || tipTitle || plain(props.Id) || ""
    }
    readonly property string subtitle: {
        const tip = props.ToolTip
        return tip && tip.length > 3 ? String(plain(tip[3]) || "").replace(/<[^>]*>/g, "") : ""
    }
    property var menuItems: []

    visible: status !== "" && status !== "Passive"
    implicitWidth: iconSize
    implicitHeight: iconSize
    Layout.preferredWidth: iconSize
    Layout.preferredHeight: iconSize
    Layout.alignment: Qt.AlignVCenter

    function plain(x) {
        return x !== null && x !== undefined && typeof x === "object" && x.value !== undefined ? x.value : x
    }

    function hasPixmap(list) {
        return !!list && list.length > 0
    }

    function call(member, signature, args) {
        return DBus.SessionBus.asyncCall({ service: service, path: objectPath, iface: "org.kde.StatusNotifierItem", member: member, arguments: args, signature: signature })
    }

    function menuCall(member, signature, args) {
        return DBus.SessionBus.asyncCall({ service: service, path: menuPath, iface: "com.canonical.dbusmenu", member: member, arguments: args, signature: signature })
    }

    function anchor() {
        return mapToGlobal(width / 2, height)
    }

    function activate() {
        if (plain(props.ItemIsMenu) && hasMenu) {
            openMenu()
            return
        }
        const p = anchor()
        const reply = call("Activate", "(ii)", [new DBus.int32(Math.round(p.x)), new DBus.int32(Math.round(p.y))])
        reply.finished.connect(() => {
            if (reply.isError && hasMenu)
                openMenu()
        })
    }

    function secondaryActivate() {
        const p = anchor()
        call("SecondaryActivate", "(ii)", [new DBus.int32(Math.round(p.x)), new DBus.int32(Math.round(p.y))])
    }

    function contextMenu() {
        if (hasMenu) {
            openMenu()
            return
        }
        const p = anchor()
        call("ContextMenu", "(ii)", [new DBus.int32(Math.round(p.x)), new DBus.int32(Math.round(p.y))])
    }

    function label(text) {
        return String(text || "").replace(/__/g, "\u0001").replace(/_/g, "").replace(/\u0001/g, "_").replace(/&/g, "&&")
    }

    function addSeparator() {
        if (menuItems.length > 0 && menuItems[menuItems.length - 1].separator)
            return
        const obj = entry.createObject(menu, { separator: true })
        menuItems.push(obj)
        menu.addMenuItem(obj)
    }

    function addEntries(nodes, depth) {
        for (const raw of nodes) {
            const node = plain(raw)
            if (!node || node.length < 3)
                continue
            const id = plain(node[0])
            const p = node[1] || {}
            const children = node[2] || []
            if (p.visible === false)
                continue
            if (plain(p.type) === "separator") {
                if (menuItems.length > 0)
                    addSeparator()
                continue
            }
            if (plain(p["children-display"]) === "submenu" && children.length > 0) {
                menu.addSection(label(plain(p.label)))
                addEntries(children, depth + 1)
                if (depth === 0)
                    addSeparator()
                continue
            }
            const toggle = plain(p["toggle-type"]) || ""
            const obj = entry.createObject(menu, {
                text: label(plain(p.label)),
                icon: plain(p["icon-name"]) || "",
                enabled: p.enabled !== false,
                checkable: toggle !== "",
                checked: toggle !== "" && plain(p["toggle-state"]) === 1,
                dbusId: id
            })
            menuItems.push(obj)
            menu.addMenuItem(obj)
        }
    }

    function openMenu() {
        menuCall("AboutToShow", "(i)", [new DBus.int32(0)])
        const reply = menuCall("GetLayout", "(iias)", [new DBus.int32(0), new DBus.int32(-1), []])
        reply.finished.connect(() => {
            if (reply.isError || !reply.values || reply.values.length < 2)
                return
            menu.clearMenuItems()
            for (const old of menuItems)
                old.destroy()
            menuItems = []
            addEntries(reply.values[1][2] || [], 0)
            if (menuItems.length > 0 && menuItems[menuItems.length - 1].separator) {
                const last = menuItems.pop()
                menu.removeMenuItem(last)
                last.destroy()
            }
            menu.openRelative()
        })
    }

    function trigger(id) {
        menuCall("Event", "(isvu)", [new DBus.int32(id), "clicked", new DBus.variant(0), new DBus.uint32(0)])
    }

    DBus.Properties {
        id: item
        busType: DBus.BusType.Session
        service: trayIcon.service
        path: trayIcon.objectPath
        iface: "org.kde.StatusNotifierItem"
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: item.updateAll()
    }

    Kirigami.Icon {
        anchors.fill: parent
        visible: !pixmap.visible
        source: trayIcon.iconName.startsWith("/") ? "file://" + trayIcon.iconName
            : trayIcon.themePath !== "" ? "file://" + trayIcon.themePath + "/" + trayIcon.iconName + ".png"
            : trayIcon.iconName
        fallback: trayIcon.iconName
        isMask: trayIcon.attention || trayIcon.iconName.endsWith("-symbolic")
        color: trayIcon.attention ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
        active: mouse.containsMouse
    }

    PixmapIcon {
        id: pixmap
        anchors.fill: parent
        visible: trayIcon.iconName === "" && trayIcon.hasPixmap(trayIcon.pixmaps)
        pixmaps: visible ? trayIcon.pixmaps : []
        desaturate: !trayIcon.attention
        opacity: mouse.containsMouse ? 1 : 0.85
    }

    Rectangle {
        visible: trayIcon.attention
        width: Math.max(2, Math.round(Kirigami.Units.smallSpacing))
        height: width
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)
        color: Kirigami.Theme.neutralTextColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -Math.round(Kirigami.Units.smallSpacing / 2)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                trayIcon.activate()
            else if (event.button === Qt.MiddleButton)
                trayIcon.secondaryActivate()
            else
                trayIcon.contextMenu()
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0)
                trayIcon.call("Scroll", "(is)", [new DBus.int32(wheel.angleDelta.y), "vertical"])
        }
    }

    PlasmaComponents.ToolTip {
        text: trayIcon.subtitle !== "" && trayIcon.subtitle !== trayIcon.title ? trayIcon.title + "\n" + trayIcon.subtitle : trayIcon.title
        visible: mouse.containsMouse && text !== "" && menu.status !== PlasmaExtras.Menu.Open
        delay: Kirigami.Units.toolTipDelay
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: trayIcon
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    Component {
        id: entry
        PlasmaExtras.MenuItem {
            property int dbusId: -1
            onClicked: if (dbusId >= 0) trayIcon.trigger(dbusId)
        }
    }
}
