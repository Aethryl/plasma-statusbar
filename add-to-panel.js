var panel = panels().filter(function (p) { return p.location === "top"; })[0];
var present = false;
panel.widgets().forEach(function (w) {
    if (w.type === "org.kde.plasma.digitalclock")
        w.remove();
    else if (w.type === "io.github.aethryl.statusbar")
        present = true;
});
if (panel.widgets("org.kde.plasma.systemtray").length === 0)
    panel.addWidget("org.kde.plasma.systemtray");
if (!present)
    panel.addWidget("io.github.aethryl.statusbar");
