import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    required property var vpn
    readonly property var kinds: ({ nm: "NetworkManager", netbird: "NetBird app" })
    signal done()
    spacing: Kirigami.Units.smallSpacing

    function open(entry) {
        if (entry.app) {
            vpn.launch(entry.app)
            done()
        } else
            KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement")
    }

    SectionHeader {
        title: "VPN"
        value: !section.vpn.loaded ? ""
            : section.vpn.activeCount === 0 ? "Off"
            : section.vpn.activeCount === 1 ? section.vpn.entries.find(e => e.active).name
            : section.vpn.activeCount + " on"
        valueColor: section.vpn.anyActive ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: section.vpn.entries
            Rectangle {
                id: vpnRow
                required property var modelData
                readonly property var target: section.vpn.busy[section.vpn.key(modelData)]
                readonly property bool working: target !== undefined || modelData.pending
                readonly property string kindLabel: section.kinds[modelData.kind] + (modelData.flavour ? " · " + modelData.flavour : "")
                readonly property string status: target === true || (target === undefined && modelData.pending && !modelData.active) ? "connecting…"
                    : target === false || (target === undefined && modelData.pending) ? "disconnecting…"
                    : modelData.detail || (modelData.active ? "connected" : "off")
                Layout.fillWidth: true
                implicitWidth: vpnLayout.implicitWidth + Kirigami.Units.smallSpacing * 3
                implicitHeight: vpnLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: vpnHover.containsMouse ? Qt.alpha(Kirigami.Theme.highlightColor, 0.25) : "transparent"

                MouseArea {
                    id: vpnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: section.open(vpnRow.modelData)
                }

                RowLayout {
                    id: vpnLayout
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 1.5
                    anchors.rightMargin: Kirigami.Units.smallSpacing * 1.5
                    spacing: Kirigami.Units.smallSpacing * 2

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: vpnRow.modelData.name
                            elide: Text.ElideRight
                            font.weight: vpnRow.modelData.active ? Font.DemiBold : Font.Normal
                            opacity: vpnRow.working ? 0.6 : 1
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing * 2
                            Caption {
                                text: vpnRow.kindLabel
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: vpnRow.status
                                elide: Text.ElideRight
                                color: Kirigami.Theme.disabledTextColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.features: { "tnum": 1 }
                            }
                        }
                    }
                    Toggle {
                        visible: vpnRow.modelData.toggle === "cli"
                        enabled: !vpnRow.working
                        checked: vpnRow.target !== undefined ? vpnRow.target : vpnRow.modelData.active
                        onToggled: section.vpn.setActive(vpnRow.modelData, !vpnRow.modelData.active)
                    }
                    MoreLink {
                        visible: vpnRow.modelData.toggle !== "cli"
                        text: "Open ↗"
                        onClicked: section.open(vpnRow.modelData)
                    }
                }
            }
        }
    }

    PlasmaComponents.Label {
        visible: section.vpn.loaded && section.vpn.entries.length === 0
        Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
        text: "No VPN connections"
        color: Kirigami.Theme.disabledTextColor
    }

    PlasmaComponents.Label {
        visible: section.vpn.error !== ""
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
        elide: Text.ElideRight
        text: section.vpn.error
        color: Kirigami.Theme.negativeTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }
}
