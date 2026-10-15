var panel = panels().filter(function (p) { return p.location === "top"; })[0];
var present = false;
panel.widgets().forEach(function (w) {
    if (w.type === "org.kde.plasma.systemtray" || w.type === "org.kde.plasma.digitalclock")
        w.remove();
    else if (w.type === "io.github.aethryl.statusbar")
        present = true;
});
if (!present)
    panel.addWidget("io.github.aethryl.statusbar");
