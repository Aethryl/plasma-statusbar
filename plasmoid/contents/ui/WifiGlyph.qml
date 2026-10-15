import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Canvas {
    id: glyph
    property int level: 0
    property bool connected: true
    property color tone: Kirigami.Theme.textColor
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property int lit: connected ? Math.max(0, Math.min(3, level - 1)) : -1
    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small
    onLitChanged: requestPaint()
    onToneChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const cx = w / 2, cy = h * 0.86
        const stroke = Math.max(1.5, Math.round(w * 0.11 * dpr) / dpr)
        const dim = Qt.alpha(tone, 0.25)
        ctx.lineCap = "round"
        ctx.lineWidth = stroke
        const radii = [h * 0.3, h * 0.52, h * 0.74]
        for (let i = 0; i < 3; i++) {
            ctx.strokeStyle = i < lit ? tone : dim
            ctx.beginPath()
            ctx.arc(cx, cy, radii[i], -Math.PI * 0.75, -Math.PI * 0.25)
            ctx.stroke()
        }
        ctx.fillStyle = connected ? tone : dim
        ctx.beginPath()
        ctx.arc(cx, cy, stroke * 0.9, 0, Math.PI * 2)
        ctx.fill()
    }
}
