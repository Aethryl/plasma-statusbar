import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property Item compactItem: null
    property bool drooped: false

    readonly property real ear: Kirigami.Units.gridUnit * 0.7
    readonly property real bottomRadius: Kirigami.Units.gridUnit * 1.1

    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.backgroundHints: inPanel ? "NoBackground" : "DefaultBackground"
    toolTipMainText: ""
    toolTipSubText: ""

    NetState {
        id: netState
        scanning: root.drooped || !root.inPanel
        vpnActive: vpnState.anyActive
    }
    AudioState { id: audioState }
    PowerState { id: powerState }
    UpdateState { id: updateState }
    VpnState {
        id: vpnState
        open: root.drooped || !root.inPanel
    }

    compactRepresentation: CompactRow {
        net: netState
        audio: audioState
        power: powerState
        updates: updateState
        vpn: vpnState
        open: root.drooped
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Component.onCompleted: root.compactItem = this
        onToggle: root.drooped = !root.drooped
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: windowed.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: windowed.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: windowed
            visible: !root.inPanel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.largeSpacing
            width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 20)
            spacing: Kirigami.Units.largeSpacing

            CompactRow {
                net: netState
                audio: audioState
                power: powerState
                updates: updateState
                vpn: vpnState
                Layout.alignment: Qt.AlignRight
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
            }
            Hairline {}
            NotchContent {
                net: netState
                audio: audioState
                power: powerState
                updates: updateState
                vpn: vpnState
                active: true
                Layout.fillWidth: true
            }
        }
    }

    onDroopedChanged: {
        if (drooped && !compactItem) {
            drooped = false
            return
        }
        if (drooped) {
            updateState.check()
            let bar = compactItem
            while (bar.parent && bar.parent.parent && bar.parent.parent.parent)
                bar = bar.parent
            const corner = bar.mapToGlobal(bar.width, bar.height)
            droop.x = Math.floor(corner.x - notch.bodyWidth - ear)
            droop.y = Math.floor(corner.y) - Kirigami.Units.cornerRadius
            notch.edgeX = corner.x - droop.x
            notch.edgeY = corner.y - droop.y
            droop.visible = true
            droop.requestActivate()
            reveal.to = 1
            reveal.easing.type = Easing.OutBack
            reveal.duration = Kirigami.Units.longDuration * 1.6
        } else {
            reveal.to = 0
            reveal.easing.type = Easing.InCubic
            reveal.duration = Kirigami.Units.longDuration * 0.8
        }
        reveal.restart()
    }

    NumberAnimation {
        id: reveal
        target: notch
        property: "progress"
        onFinished: if (!root.drooped) droop.visible = false
    }

    PlasmaCore.Dialog {
        id: droop
        location: PlasmaCore.Types.TopEdge
        type: PlasmaCore.Dialog.PopupMenu
        flags: Qt.WindowStaysOnTopHint
        backgroundHints: PlasmaCore.Dialog.NoBackground
        hideOnWindowDeactivate: true
        onVisibleChanged: if (!visible) { root.drooped = false; notch.progress = 0 }

        mainItem: Item {
            id: notch
            property real progress: 0
            property real edgeX: bodyWidth + root.ear
            property real edgeY: Kirigami.Units.cornerRadius
            readonly property real bodyWidth: Kirigami.Units.gridUnit * 20
            readonly property real fullHeight: content.implicitHeight + Kirigami.Units.gridUnit * 1.6
            readonly property real shownHeight: Math.max(0, fullHeight * progress)
            width: edgeX
            height: edgeY + fullHeight * 1.1
            focus: true
            Keys.onEscapePressed: root.drooped = false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false

            Shape {
                width: notch.edgeX
                height: parent.height
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    id: sp
                    readonly property real c: notch.edgeY
                    readonly property real e: root.ear
                    readonly property real w: notch.bodyWidth
                    readonly property real right: notch.edgeX
                    readonly property real left: right - w
                    readonly property real h: c + Math.max(notch.shownHeight, e + 1)
                    readonly property real r: Math.min(root.bottomRadius, h - c - e)
                    readonly property real o: 0.5
                    strokeWidth: -1
                    fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.alpha(Kirigami.Theme.textColor, 0.08))
                    startX: sp.right; startY: 0
                    PathLine { x: sp.right; y: sp.h - sp.r }
                    PathArc { x: sp.right - sp.r; y: sp.h; radiusX: sp.r; radiusY: sp.r }
                    PathLine { x: sp.left + sp.r; y: sp.h }
                    PathArc { x: sp.left; y: sp.h - sp.r; radiusX: sp.r; radiusY: sp.r }
                    PathLine { x: sp.left; y: sp.c + sp.e }
                    PathArc { x: sp.left - sp.e; y: sp.c; radiusX: sp.e; radiusY: sp.e; direction: PathArc.Counterclockwise }
                    PathLine { x: sp.left - sp.e; y: 0 }
                    PathLine { x: sp.right; y: 0 }
                }
                ShapePath {
                    strokeWidth: 1
                    strokeColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.alpha(Kirigami.Theme.textColor, 0.14))
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    startX: sp.right - sp.o; startY: 0
                    PathLine { x: sp.right - sp.o; y: sp.h - sp.r }
                    PathArc { x: sp.right - sp.r; y: sp.h - sp.o; radiusX: sp.r - sp.o; radiusY: sp.r - sp.o }
                    PathLine { x: sp.left + sp.r; y: sp.h - sp.o }
                    PathArc { x: sp.left + sp.o; y: sp.h - sp.r; radiusX: sp.r - sp.o; radiusY: sp.r - sp.o }
                    PathLine { x: sp.left + sp.o; y: sp.c + sp.e }
                    PathArc { x: sp.left - sp.e; y: sp.c - sp.o; radiusX: sp.e + sp.o; radiusY: sp.e + sp.o; direction: PathArc.Counterclockwise }
                }
            }

            Item {
                x: notch.edgeX - notch.bodyWidth
                y: notch.edgeY
                width: notch.bodyWidth
                height: notch.shownHeight
                clip: true

                NotchContent {
                    id: content
                    x: Kirigami.Units.gridUnit * 0.8
                    y: Kirigami.Units.gridUnit * 0.6
                    width: parent.width - Kirigami.Units.gridUnit * 1.6
                    opacity: Math.min(1, Math.max(0, notch.progress * 1.6 - 0.4))
                    net: netState
                    audio: audioState
                    power: powerState
                    updates: updateState
                    vpn: vpnState
                    active: root.drooped
                    onClose: root.drooped = false
                }
            }
        }
    }
}
