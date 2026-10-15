import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.volume as Vol
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    required property var audio
    property bool expanded: false
    spacing: Kirigami.Units.smallSpacing

    SectionHeader {
        title: "Sound"
        value: !section.audio.available ? "No output" : section.audio.muted ? "Muted" : section.audio.percent + "%"
        valueColor: section.audio.muted ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing * 2
        enabled: section.audio.available
        IconAction {
            icon: section.audio.icon
            hint: section.audio.muted ? "Unmute" : "Mute"
            tone: section.audio.muted ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
            onClicked: section.audio.toggleMute()
        }
        Level {
            Layout.fillWidth: true
            value: section.audio.percent
            fill: section.audio.muted ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.highlightColor
            onMoved: value => section.audio.setPercent(Math.round(value))
        }
    }

    Vol.SinkModel { id: sinks }
    Vol.PulseObjectFilterModel {
        id: outputs
        filterOutInactiveDevices: true
        filterVirtualDevices: true
        sourceModel: sinks
    }

    RowLayout {
        Layout.fillWidth: true
        visible: section.audio.available
        spacing: Kirigami.Units.smallSpacing
        MoreLink {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: (section.audio.sink ? (section.audio.sink.description || section.audio.sink.name) : "") + (outputs.count > 1 ? (section.expanded ? "  ▴" : "  ▾") : "")
            onClicked: section.expanded = outputs.count > 1 && !section.expanded
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: section.expanded
        spacing: 0
        Repeater {
            model: section.expanded ? outputs : null
            ListRow {
                required property var model
                icon: model.PulseObject && model.PulseObject.default ? "checkmark-symbolic" : "audio-speakers-symbolic"
                text: model.Description || model.Name
                current: !!model.PulseObject && model.PulseObject.default
                onClicked: {
                    model.PulseObject.default = true
                    section.expanded = false
                }
            }
        }
    }
}
