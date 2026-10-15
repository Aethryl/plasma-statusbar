import QtQuick

Canvas {
    id: canvas
    property var pixmaps: []
    property bool desaturate: true
    property string signature: ""

    function plain(x) {
        return x !== null && x !== undefined && typeof x === "object" && x.value !== undefined ? x.value : x
    }

    function best() {
        const target = Math.max(width, height) * (Screen.devicePixelRatio || 1)
        let pick = null
        for (const p of pixmaps || []) {
            const w = plain(p[0]), h = plain(p[1])
            if (!w || !h || !p[2] || p[2].length < w * h * 4)
                continue
            if (!pick || (pick.w < target && w > pick.w) || (w >= target && w < pick.w))
                pick = { w: w, h: h, bytes: p[2] }
        }
        return pick
    }

    function refresh() {
        const pick = best()
        let sig = ""
        if (pick) {
            let sum = 0
            for (let i = 0; i < pick.bytes.length; i += 29)
                sum = (sum * 31 + plain(pick.bytes[i])) % 1000000007
            sig = pick.w + "x" + pick.h + ":" + sum + (desaturate ? "g" : "c")
        }
        if (sig !== signature) {
            signature = sig
            requestPaint()
        }
    }

    onPixmapsChanged: refresh()
    onDesaturateChanged: refresh()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const pick = best()
        if (!pick)
            return
        const img = ctx.createImageData(pick.w, pick.h)
        const out = img.data
        const n = pick.w * pick.h
        for (let i = 0; i < n; i++) {
            const a = plain(pick.bytes[i * 4]), r = plain(pick.bytes[i * 4 + 1]), g = plain(pick.bytes[i * 4 + 2]), b = plain(pick.bytes[i * 4 + 3])
            if (desaturate) {
                const y = Math.round(0.3 * r + 0.59 * g + 0.11 * b)
                out[i * 4] = y
                out[i * 4 + 1] = y
                out[i * 4 + 2] = y
            } else {
                out[i * 4] = r
                out[i * 4 + 1] = g
                out[i * 4 + 2] = b
            }
            out[i * 4 + 3] = a
        }
        ctx.drawImage(img, 0, 0, width, height)
    }
}
