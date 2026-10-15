import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: section
    property bool active: false
    readonly property bool available: control.isBrightnessAvailable
    visible: available
    spacing: Kirigami.Units.smallSpacing

    ScreenBrightnessControl {
        id: control
        isSilent: section.active
    }

    Repeater {
        model: control.displays
        ColumnLayout {
            id: display
            required property string displayName
            required property string label
            required property int brightness
            required property int maxBrightness
            required property int index
            readonly property int percent: maxBrightness > 0 ? Math.round(100 * brightness / maxBrightness) : 0
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            SectionHeader {
                title: display.index === 0 ? "Brightness" : display.label
                value: display.percent + "%"
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 2
                Kirigami.Icon {
                    source: "display-brightness-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
                    Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                }
                Level {
                    Layout.fillWidth: true
                    from: 0
                    to: display.maxBrightness
                    value: display.brightness
                    onMoved: value => control.setBrightness(display.displayName, Math.max(1, Math.round(value)))
                }
            }
        }
    }
}
