pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    readonly property var preparedEntries: entries.map(a => ({
                name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
                entry: a
            }))

    function fuzzyQuery(search: string): var {
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                        entry: str,
                        score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
                    })).filter(item => item.score > root.scoreThreshold).sort((a, b) => b.score - a.score);
            return results.map(item => item.entry);
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry;
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry));
    }

    function refresh() {
        readProc.buffer = [];
        readProc.running = true;
    }

    function copy(entry) {
        Quickshell.execDetached(["bash", "-c", `clipvault get ${entry.split("\t")[0]} | wl-copy`]);
    }

    function paste(entry) {
        Quickshell.execDetached(["bash", "-c", `clipvault get ${entry.split("\t")[0]} | wl-copy; ${root.pressPasteCommand}`]);
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage)
                return true;
            return entryIsImage(entry);
        }).slice(0, count);

        const pasteCommands = [...targetEntries].reverse().map(entry => `clipvault get ${entry.split("\t")[0]} | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`).join(` && sleep ${root.pasteDelay} && `);

        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["clipvault", "delete", entry.split("\t")[0]]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart();
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh();
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: ["clipvault", "list"]

        stdout: SplitParser {
            onRead: line => {
                readProc.buffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer;
            } else {
                console.error("[Clipboard] Failed to refresh with code", exitCode, "and status", exitStatus);
            }
        }
    }

    IpcHandler {
        target: "clipboardService"

        function update(): void {
            root.refresh();
        }
    }
}
