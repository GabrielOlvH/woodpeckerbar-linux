import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "woodpeckerbar"

    property string woodpeckerBarPath: pluginData.woodpeckerBarPath || "/home/gabriel/Projects/Personal/woodpeckerbar-linux"
    property string woodpeckerUrl: pluginData.woodpeckerUrl || "https://ci.kaia.systems"
    property string woodpeckerToken: pluginData.woodpeckerToken || ""
    property int refreshInterval: parseInt(pluginData.refreshInterval) || 60

    property var repos: []
    property int runningCount: 0
    property int failingCount: 0
    property bool loading: true
    property int nowEpoch: Math.floor(Date.now() / 1000)

    property bool allGreen: failingCount === 0 && runningCount === 0 && repos.length > 0
    property bool hasRunning: runningCount > 0
    property bool hasFailing: failingCount > 0

    Timer {
        interval: 1000
        running: root.hasRunning
        repeat: true
        onTriggered: root.nowEpoch = Math.floor(Date.now() / 1000)
    }

    Timer {
        id: fetchTimer
        interval: root.hasRunning ? 5000 : root.refreshInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchData()
    }

    function statusColor(status) {
        if (status === "success") return Theme.primary
        if (status === "running" || status === "pending") return "#2196F3"
        if (status === "failure" || status === "error") return Theme.error
        if (status === "killed" || status === "declined") return Theme.surfaceVariantText
        return Theme.surfaceVariantText
    }

    function statusIcon(status) {
        if (status === "success") return "check_circle"
        if (status === "running") return "play_circle"
        if (status === "pending") return "schedule"
        if (status === "failure" || status === "error") return "cancel"
        if (status === "killed") return "stop_circle"
        return "help"
    }

    function pillColor() {
        if (loading) return Theme.surfaceVariantText
        if (hasFailing) return Theme.error
        if (hasRunning) return "#2196F3"
        return Theme.primary
    }

    function formatDuration(secs) {
        if (!secs || secs <= 0) return ""
        var m = Math.floor(secs / 60)
        var s = secs % 60
        if (m > 0) return m + "m " + s + "s"
        return s + "s"
    }

    function liveDuration(pipeline) {
        if (!pipeline) return ""
        if (pipeline.status === "running" && pipeline.started > 0) {
            return formatDuration(root.nowEpoch - pipeline.started)
        }
        return formatDuration(pipeline.duration)
    }

    function timeAgo(epochSecs) {
        if (!epochSecs) return ""
        var diff = root.nowEpoch - epochSecs
        if (diff < 60) return "just now"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        return Math.floor(diff / 86400) + "d ago"
    }

    function eventLabel(event) {
        if (event === "pull_request") return "PR"
        if (event === "pull_request_closed") return "PR closed"
        return event || ""
    }

    function currentStepInfo(pipeline) {
        if (!pipeline || !pipeline.steps || pipeline.steps.length === 0) return ""
        var completed = 0
        var currentName = ""
        var total = pipeline.steps.length
        for (var i = 0; i < total; i++) {
            if (pipeline.steps[i].state === "success") completed++
            if (pipeline.steps[i].state === "running") currentName = pipeline.steps[i].name
        }
        if (currentName) return currentName + " (" + (completed + 1) + "/" + total + ")"
        return ""
    }

    function runningPipelineText() {
        for (var i = 0; i < repos.length; i++) {
            var p = repos[i].last_pipeline
            if (p && (p.status === "running" || p.status === "pending")) {
                var step = currentStepInfo(p)
                var elapsed = p.started > 0 ? formatDuration(root.nowEpoch - p.started) : ""
                var parts = [repos[i].name]
                if (step) parts.push(step)
                if (elapsed) parts.push(elapsed)
                return parts.join(" \u00B7 ")
            }
        }
        return ""
    }

    function fetchData() {
        if (!root.woodpeckerToken) return
        Proc.runCommand(
            "woodpeckerBar.fetch",
            ["bun", "run", root.woodpeckerBarPath + "/src/index.ts",
             "--token", root.woodpeckerToken,
             "--url", root.woodpeckerUrl],
            (stdout, exitCode) => {
                if (exitCode === 0 && stdout.trim()) {
                    try {
                        var data = JSON.parse(stdout)
                        if (!data.error) {
                            root.repos = data.repos || []
                            root.runningCount = data.running || 0
                            root.failingCount = data.failing || 0
                            root.loading = false
                        }
                    } catch (e) {
                        console.error("WoodpeckerBar: Failed to parse JSON:", e)
                    }
                }
            },
            500
        )
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "rocket_launch"
                color: root.pillColor()
                size: Theme.fontSizeLarge
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.loading) return "..."
                    if (root.hasRunning) return root.runningPipelineText()
                    if (root.hasFailing) return root.failingCount + " failing"
                    return "all green"
                }
                color: root.pillColor()
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "rocket_launch"
                color: root.pillColor()
                size: Theme.fontSizeMedium
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.loading ? ".." : (root.hasFailing ? root.failingCount + "!" : (root.hasRunning ? root.runningCount + "\u25B6" : "\u2713"))
                color: root.pillColor()
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: ""
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - Theme.spacingL

                Flickable {
                    anchors.fill: parent
                    contentHeight: mainCol.implicitHeight
                    clip: true

                    Column {
                        id: mainCol
                        width: parent.width
                        spacing: Theme.spacingM

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "rocket_launch"
                                color: Theme.surfaceText
                                size: Theme.fontSizeLarge
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: "Woodpecker CI"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    text: root.repos.length + " repos"
                                        + (root.runningCount > 0 ? (" \u00B7 " + root.runningCount + " building") : "")
                                        + (root.failingCount > 0 ? (" \u00B7 " + root.failingCount + " failing") : "")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                }
                            }
                        }

                        Repeater {
                            model: root.repos

                            Column {
                                width: mainCol.width
                                spacing: 4

                                property var repo: modelData
                                property var pipeline: modelData.last_pipeline
                                property bool isRunning: pipeline && (pipeline.status === "running" || pipeline.status === "pending")

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: pipeline ? root.statusIcon(pipeline.status) : "help"
                                        color: pipeline ? root.statusColor(pipeline.status) : Theme.surfaceVariantText
                                        size: Theme.fontSizeMedium
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - Theme.fontSizeMedium - Theme.spacingS

                                        Row {
                                            spacing: Theme.spacingXS

                                            StyledText {
                                                text: repo.name
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                            }

                                            Item {
                                                width: buildNumText.width
                                                height: buildNumText.height
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: !!pipeline

                                                StyledText {
                                                    id: buildNumText
                                                    text: pipeline ? ("#" + pipeline.number) : ""
                                                    color: Theme.primary
                                                    font.pixelSize: Theme.fontSizeSmall - 2
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -4
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Qt.openUrlExternally(repo.link)
                                                }
                                            }

                                            StyledRect {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: durText.width + 8
                                                height: durText.height + 2
                                                radius: height / 2
                                                color: pipeline ? Qt.rgba(root.statusColor(pipeline.status).r, root.statusColor(pipeline.status).g, root.statusColor(pipeline.status).b, 0.15) : "transparent"
                                                visible: pipeline && (pipeline.duration > 0 || isRunning)

                                                StyledText {
                                                    id: durText
                                                    anchors.centerIn: parent
                                                    text: root.liveDuration(pipeline)
                                                    color: pipeline ? root.statusColor(pipeline.status) : Theme.surfaceVariantText
                                                    font.pixelSize: Theme.fontSizeSmall - 3
                                                    font.weight: Font.Medium
                                                }
                                            }
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: pipeline ? pipeline.message : "No pipelines"
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall - 2
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        // Step progress for running pipelines
                                        Flow {
                                            width: parent.width
                                            spacing: 6
                                            visible: isRunning && pipeline && pipeline.steps && pipeline.steps.length > 0

                                            Repeater {
                                                model: (pipeline && pipeline.steps) ? pipeline.steps : []

                                                Row {
                                                    spacing: 3

                                                    Rectangle {
                                                        width: 6
                                                        height: 6
                                                        radius: 3
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        color: root.statusColor(modelData.state)
                                                    }

                                                    StyledText {
                                                        text: modelData.name
                                                        color: modelData.state === "running" ? Theme.surfaceText : Theme.surfaceVariantText
                                                        font.pixelSize: Theme.fontSizeSmall - 3
                                                        font.weight: modelData.state === "running" ? Font.Medium : Font.Normal
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            spacing: Theme.spacingS
                                            visible: !!pipeline

                                            StyledText {
                                                text: pipeline ? root.eventLabel(pipeline.event) : ""
                                                color: Theme.surfaceContainerHighest
                                                font.pixelSize: Theme.fontSizeSmall - 3
                                                visible: text !== ""
                                            }

                                            StyledText {
                                                text: pipeline ? pipeline.branch : ""
                                                color: Theme.primary
                                                font.pixelSize: Theme.fontSizeSmall - 3
                                            }

                                            StyledText {
                                                text: pipeline ? pipeline.commit : ""
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 3
                                                font.family: "monospace"
                                            }

                                            StyledText {
                                                text: pipeline ? root.timeAgo(pipeline.created) : ""
                                                color: Theme.surfaceContainerHighest
                                                font.pixelSize: Theme.fontSizeSmall - 3
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Theme.surfaceContainerHighest
                                    visible: index < root.repos.length - 1
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: !root.woodpeckerToken

                            DankIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: "key_off"
                                color: Theme.surfaceVariantText
                                size: 32
                            }

                            StyledText {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "Set your API token in settings"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeMedium
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 400
}
