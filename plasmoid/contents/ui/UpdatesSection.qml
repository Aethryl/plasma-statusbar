import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: updatesSection
    required property var updates
    property bool expanded: false
    property string filter: ""
    readonly property bool busy: updates.refreshing || (updates.checking && !updates.loaded)
    readonly property var kinds: [
        { key: "security", label: "Security" },
        { key: "bugfix", label: "Bug fix" },
        { key: "enhancement", label: "Enhancement" },
        { key: "other", label: "Other" },
        { key: "flatpak", label: "Flatpak" }
    ]
    readonly property var labels: ({ security: "Security", bugfix: "Bug fix", enhancement: "Enhancement", other: "Other", flatpak: "Flatpak" })
    readonly property int shownCount: filter === "" ? updates.total : count(filter)
    signal done()
    spacing: Kirigami.Units.smallSpacing

    function count(key) {
        return key === "flatpak" ? updates.flatpak : (updates.counts[key] || 0)
    }

    function launch(cmd) {
        updates.launch(cmd)
        done()
    }

    function fill() {
        rows.clear()
        if (!expanded)
            return
        for (const p of updates.packages)
            if (filter === "" || filter === p.kind)
                rows.append({ group: labels[p.kind], name: p.name, version: p.version })
        for (const f of updates.flatpaks)
            if (filter === "" || filter === "flatpak")
                rows.append({ group: "Flatpak", name: f.name, version: f.version || f.branch })
    }

    onExpandedChanged: fill()
    onFilterChanged: fill()
    Connections {
        target: updatesSection.updates
        function onResultChanged() {
            if (updatesSection.filter !== "" && updatesSection.count(updatesSection.filter) === 0)
                updatesSection.filter = ""
            updatesSection.fill()
        }
    }

    ListModel { id: rows }

    SectionHeader {
        title: "Updates"
        value: updatesSection.busy ? "Checking…"
            : !updatesSection.updates.loaded ? ""
            : updatesSection.updates.total === 0 ? (updatesSection.updates.error !== "" ? "Unavailable" : "Up to date · checked " + updatesSection.updates.checked)
            : updatesSection.updates.total + (updatesSection.updates.total === 1 ? " update" : " updates")
                + (updatesSection.updates.security > 0 ? " · " + updatesSection.updates.security + " security" : "")
        valueColor: updatesSection.updates.total === 0 || updatesSection.busy ? Kirigami.Theme.disabledTextColor
            : updatesSection.updates.security > 0 ? Kirigami.Theme.neutralTextColor
            : Kirigami.Theme.textColor
    }

    Flow {
        visible: updatesSection.updates.total > 0
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        Repeater {
            model: updatesSection.kinds
            Chip {
                required property var modelData
                visible: updatesSection.count(modelData.key) > 0
                text: modelData.label + " " + updatesSection.count(modelData.key)
                active: updatesSection.filter === modelData.key
                onClicked: {
                    updatesSection.filter = updatesSection.filter === modelData.key ? "" : modelData.key
                    updatesSection.expanded = updatesSection.filter !== "" || updatesSection.expanded
                }
            }
        }
    }

    ListView {
        id: list
        visible: updatesSection.expanded && updatesSection.updates.total > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 12)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: rows
        section.property: "group"
        section.delegate: Caption {
            required property string section
            text: section
            leftPadding: Kirigami.Units.smallSpacing * 1.5
            topPadding: Kirigami.Units.smallSpacing
            bottomPadding: Kirigami.Units.smallSpacing
        }
        delegate: ListRow {
            required property string name
            required property string version
            width: ListView.view.width - (list.contentHeight > list.height ? Kirigami.Units.largeSpacing : 0)
            text: name
            detail: version
        }
        PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {}
    }

    PlasmaComponents.Label {
        visible: updatesSection.updates.error !== ""
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: updatesSection.updates.error
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        MoreLink {
            visible: updatesSection.updates.total > 0
            text: updatesSection.expanded ? "Hide packages" : "Packages · " + updatesSection.shownCount
            onClicked: {
                updatesSection.expanded = !updatesSection.expanded
                if (!updatesSection.expanded)
                    updatesSection.filter = ""
            }
        }
        Item { Layout.fillWidth: true }
        PlasmaComponents.Label {
            visible: updatesSection.updates.total > 0 && updatesSection.updates.checked !== ""
            text: "checked " + updatesSection.updates.checked
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.features: { "tnum": 1 }
        }
    }

    RowLayout {
        visible: updatesSection.updates.total > 0
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        IconAction {
            Layout.fillWidth: true
            icon: "utilities-terminal-symbolic"
            label: "Terminal"
            hint: "sudo dnf upgrade --refresh && flatpak update"
            onClicked: updatesSection.launch("ghostty -e sh -c 'sudo dnf upgrade --refresh && flatpak update; exec $SHELL'")
        }
        IconAction {
            Layout.fillWidth: true
            icon: Qt.resolvedUrl("../images/update.svg")
            label: "Discover"
            hint: "Open updates in Discover"
            tone: updatesSection.updates.security > 0 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.highlightColor
            onClicked: updatesSection.launch("plasma-discover --mode update")
        }
        IconAction {
            icon: "view-refresh-symbolic"
            label: updatesSection.updates.refreshing ? "Refreshing…" : ""
            hint: "Refresh package lists"
            opacity: updatesSection.updates.refreshing ? 0.6 : 1
            onClicked: updatesSection.updates.refresh()
        }
    }
}
