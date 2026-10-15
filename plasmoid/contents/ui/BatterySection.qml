import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    required property var power
    readonly property var profileLabels: ({ "power-saver": "Saver", "balanced": "Balanced", "performance": "Performance" })
    readonly property var profileIcons: ({ "power-saver": "power-profile-power-saver-symbolic", "balanced": "power-profile-balanced-symbolic", "performance": "power-profile-performance-symbolic" })
    spacing: Kirigami.Units.smallSpacing

    SectionHeader {
        visible: section.power.hasBattery
        title: "Battery"
        value: section.power.percent + "%"
        valueColor: section.power.charging ? Kirigami.Theme.positiveTextColor
            : section.power.percent <= 10 ? Kirigami.Theme.negativeTextColor
            : section.power.percent <= 20 ? Kirigami.Theme.neutralTextColor
            : Kirigami.Theme.textColor
    }

    Rectangle {
        visible: section.power.hasBattery
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.smallSpacing * 1.5
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        Rectangle {
            width: Math.max(parent.height, parent.width * Math.min(100, section.power.percent) / 100)
            height: parent.height
            radius: parent.radius
            color: section.power.charging ? Kirigami.Theme.positiveTextColor
                : section.power.percent <= 20 ? Kirigami.Theme.neutralTextColor
                : Kirigami.Theme.highlightColor
        }
    }

    PlasmaComponents.Label {
        visible: section.power.hasBattery
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: section.power.status
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    RowLayout {
        visible: section.power.hasProfiles
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        Caption {
            text: "Power"
            Layout.fillWidth: true
        }
        Repeater {
            model: section.power.profileList
            Chip {
                required property string modelData
                text: section.profileLabels[modelData] || modelData
                icon: section.profileIcons[modelData] || ""
                active: section.power.activeProfile === modelData
                onClicked: section.power.setProfile(modelData)
            }
        }
    }
}
