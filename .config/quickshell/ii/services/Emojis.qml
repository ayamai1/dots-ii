pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Emojis.
 */
Singleton {
    id: root
    property string emojisPath: `${Directories.assetsPath}/emojis.txt`
    property list<var> list
    readonly property var preparedEntries: list.map(a => ({
                name: Fuzzy.prepare(`${a}`),
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

    function load() {
        emojiFileView.reload();
    }

    function updateEmojis(fileContent) {
        const lines = fileContent.split("\n");
        const emojis = lines.filter(line => line.trim() !== "");
        root.list = emojis.map(line => line.trim());
    }

    FileView {
        id: emojiFileView
        path: Qt.resolvedUrl(root.emojisPath)
        onLoadedChanged: {
            const fileContent = emojiFileView.text();
            root.updateEmojis(fileContent);
        }
    }
}
