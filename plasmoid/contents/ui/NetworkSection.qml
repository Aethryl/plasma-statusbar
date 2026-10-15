import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kitemmodels as KItemModels
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    required property var net
    property bool expanded: false
    property string passwordFor: ""
    readonly property int limit: 8
    spacing: Kirigami.Units.smallSpacing

    function secured(type) {
        return type !== PlasmaNM.Enums.NoneSecurity && type !== PlasmaNM.Enums.UnknownSecurity
    }

    function needsPassword(m) {
        return !m.Uuid && (m.SecurityType === PlasmaNM.Enums.StaticWep || m.SecurityType === PlasmaNM.Enums.WpaPsk
            || m.SecurityType === PlasmaNM.Enums.Wpa2Psk || m.SecurityType === PlasmaNM.Enums.SAE)
    }

    function connect(m) {
        if (m.Uuid)
            net.handler.activateConnection(m.ConnectionPath, m.DevicePath, m.SpecificPath)
        else if (needsPassword(m))
            passwordFor = passwordFor === m.ItemUniqueName ? "" : m.ItemUniqueName
        else
            net.handler.addAndActivateConnection(m.DevicePath, m.SpecificPath)
    }

    SectionHeader {
        title: "Wi-Fi"
        value: section.net.connecting ? "Connecting…"
            : section.net.wired ? "Wired"
            : section.net.online ? section.net.strength + "%"
            : section.net.wirelessEnabled ? "Offline" : "Off"
        valueColor: section.net.online ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
        toggleVisible: section.net.wirelessAvailable
        toggleEnabled: section.net.wirelessToggleable
        checked: section.net.wirelessEnabled
        onToggled: section.net.setWireless(!section.net.wirelessEnabled)
    }

    ListRow {
        visible: section.net.online
        icon: section.net.wired ? "network-wired-symbolic" : ""
        text: section.net.name
        current: true
        detail: section.net.wired ? "" : "connected"
        Kirigami.Icon {
            visible: !section.net.wired
            source: section.net.icon
            isMask: true
            color: Kirigami.Theme.highlightColor
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }
        onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement")
    }

    KItemModels.KSortFilterProxyModel {
        id: available
        sourceModel: section.net.model
        filterRowCallback: (row, parent) => {
            const index = sourceModel.index(row, 0, parent)
            const type = sourceModel.data(index, sourceModel.KItemModels.KRoleNames.role("Type"))
            const state = sourceModel.data(index, sourceModel.KItemModels.KRoleNames.role("ConnectionState"))
            const device = sourceModel.data(index, sourceModel.KItemModels.KRoleNames.role("DevicePath"))
            return type === PlasmaNM.Enums.Wireless && state !== PlasmaNM.Enums.Activated && !!device
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: section.net.wirelessEnabled
        spacing: Kirigami.Units.smallSpacing
        MoreLink {
            text: (section.expanded ? "Hide networks" : "Networks") + (available.count > 0 ? " · " + available.count : "")
            onClicked: section.expanded = !section.expanded
        }
        Item { Layout.fillWidth: true }
        MoreLink {
            text: "Settings ↗"
            onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: section.expanded && section.net.wirelessEnabled
        spacing: 0

        Repeater {
            model: section.expanded ? available : null
            ColumnLayout {
                id: networkRow
                required property var model
                required property int index
                Layout.fillWidth: true
                visible: index < section.limit
                spacing: Kirigami.Units.smallSpacing

                ListRow {
                    text: networkRow.model.ItemUniqueName
                    busy: networkRow.model.ConnectionState === PlasmaNM.Enums.Activating
                    detail: networkRow.model.ConnectionState === PlasmaNM.Enums.Activating ? "connecting" : networkRow.model.Uuid ? "saved" : ""
                    onClicked: section.connect(networkRow.model)
                    Kirigami.Icon {
                        visible: section.secured(networkRow.model.SecurityType)
                        source: "object-locked-symbolic"
                        isMask: true
                        color: Kirigami.Theme.disabledTextColor
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small * 0.75
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small * 0.75
                    }
                    Kirigami.Icon {
                        source: networkRow.model.ConnectionIcon
                        isMask: true
                        color: Kirigami.Theme.textColor
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                }

                PlasmaExtras.PasswordField {
                    id: password
                    visible: section.passwordFor === networkRow.model.ItemUniqueName
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
                    Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                    placeholderText: "Password"
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onAccepted: {
                        if (text.length < 5)
                            return
                        section.net.handler.addAndActivateConnection(networkRow.model.DevicePath, networkRow.model.SpecificPath, text)
                        text = ""
                        section.passwordFor = ""
                    }
                }
            }
        }

        PlasmaComponents.Label {
            visible: available.count === 0
            Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
            text: "Scanning…"
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
