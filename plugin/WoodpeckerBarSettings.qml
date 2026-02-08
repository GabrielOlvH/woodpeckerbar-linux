import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "woodpeckerBar"

    StyledText {
        width: parent.width
        text: "WoodpeckerBar Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Monitor Woodpecker CI pipeline status across your repositories."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "woodpeckerBarPath"
        label: "WoodpeckerBar Path"
        description: "Absolute path to the woodpeckerbar-linux repo"
        placeholder: "/home/gabriel/Projects/Personal/woodpeckerbar-linux"
        defaultValue: "/home/gabriel/Projects/Personal/woodpeckerbar-linux"
    }

    StringSetting {
        settingKey: "woodpeckerUrl"
        label: "Woodpecker URL"
        description: "Base URL of your Woodpecker CI instance"
        placeholder: "https://ci.kaia.systems"
        defaultValue: "https://ci.kaia.systems"
    }

    StringSetting {
        settingKey: "woodpeckerToken"
        label: "API Token"
        description: "Personal API token from Woodpecker CI"
        placeholder: "eyJ..."
        defaultValue: ""
    }

    SelectionSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "How often to fetch pipeline status"
        options: [
            {label: "30 seconds", value: "30"},
            {label: "1 minute", value: "60"},
            {label: "2 minutes", value: "120"},
            {label: "5 minutes", value: "300"}
        ]
        defaultValue: "60"
    }
}
