pragma Singleton
pragma ComponentBehavior: Bound

// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

/**
 * For managing brightness of monitors with brightnessctl.
 */
Singleton {
    id: root

    signal brightnessChanged

    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComp.createObject(root, {
            screen
        }))

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.screen === screen);
    }

    function increaseBrightness(): void {
        const focusedName = Hyprland.focusedMonitor.name;
        const monitor = monitors.find(m => focusedName === m.screen.name);
        if (monitor)
            monitor.setBrightness(monitor.brightness + 0.05);
    }

    function decreaseBrightness(): void {
        const focusedName = Hyprland.focusedMonitor.name;
        const monitor = monitors.find(m => focusedName === m.screen.name);
        if (monitor)
            monitor.setBrightness(monitor.brightness - 0.05);
    }

    reloadableId: "brightness"

    Process {
        id: setProc
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        property int rawMaxBrightness: 100
        property real brightness
        property bool ready: false

        onBrightnessChanged: {
            if (monitor.ready) {
                root.brightnessChanged();
            }
        }

        function initialize() {
            monitor.ready = false;
            initProc.command = ["sh", "-c", `echo "a b c $(brightnessctl g) $(brightnessctl m)"`];
            initProc.running = true;
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const [, , , current, max] = data.split(" ");
                    monitor.rawMaxBrightness = parseInt(max);
                    monitor.brightness = parseInt(current) / monitor.rawMaxBrightness;
                    monitor.ready = true;
                }
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0.01, Math.min(1, value));
            const rounded = Math.round(value * monitor.rawMaxBrightness);
            if (Math.round(brightness * monitor.rawMaxBrightness) === rounded)
                return;
            brightness = value;
            setProc.command = ["brightnessctl", "s", rounded, "--quiet"];
            setProc.startDetached();
        }

        Component.onCompleted: {
            initialize();
        }
    }

    Component {
        id: monitorComp

        BrightnessMonitor {}
    }

    IpcHandler {
        target: "brightness"

        function increment() {
            onPressed: root.increaseBrightness();
        }

        function decrement() {
            onPressed: root.decreaseBrightness();
        }
    }

    GlobalShortcut {
        name: "brightnessIncrease"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    GlobalShortcut {
        name: "brightnessDecrease"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }
}
