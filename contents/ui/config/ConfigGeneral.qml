/*
    Azen Search 配置界面
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {

    // ---------- 外观：内部 ----------
    QQC2.RadioButton {
        Kirigami.FormData.label: i18n("内部：")
        text: i18n("纯文字（Search here）")
        checked: Plasmoid.configuration.innerStyle === "text"
        onToggled: if (checked) Plasmoid.configuration.innerStyle = "text"
    }

    QQC2.RadioButton {
        text: i18n("搜索图标 + 文字")
        checked: Plasmoid.configuration.innerStyle === "icontext"
        onToggled: if (checked) Plasmoid.configuration.innerStyle = "icontext"
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // ---------- 外观：外壳 ----------
    QQC2.RadioButton {
        Kirigami.FormData.label: i18n("外壳：")
        text: i18n("圆润（Windows 11 风）")
        checked: Plasmoid.configuration.shellStyle === "rounded"
        onToggled: if (checked) Plasmoid.configuration.shellStyle = "rounded"
    }

    QQC2.RadioButton {
        text: i18n("方形（Windows 10 风）")
        checked: Plasmoid.configuration.shellStyle === "square"
        onToggled: if (checked) Plasmoid.configuration.shellStyle = "square"
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // ---------- 外观：长度 ----------
    QQC2.RadioButton {
        Kirigami.FormData.label: i18n("长度：")
        text: i18n("仅图标")
        checked: Plasmoid.configuration.sizePreset === "iconOnly"
        onToggled: if (checked) Plasmoid.configuration.sizePreset = "iconOnly"
    }

    QQC2.RadioButton {
        text: i18n("小")
        checked: Plasmoid.configuration.sizePreset === "small"
        onToggled: if (checked) Plasmoid.configuration.sizePreset = "small"
    }

    QQC2.RadioButton {
        text: i18n("中（原来的大小）")
        checked: Plasmoid.configuration.sizePreset === "medium"
        onToggled: if (checked) Plasmoid.configuration.sizePreset = "medium"
    }

    QQC2.RadioButton {
        text: i18n("大")
        checked: Plasmoid.configuration.sizePreset === "large"
        onToggled: if (checked) Plasmoid.configuration.sizePreset = "large"
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // ---------- 搜索 ----------
    QQC2.ComboBox {
        id: engineCombo
        Kirigami.FormData.label: i18n("网页搜索引擎:")
        textRole: "text"
        valueRole: "value"
        model: [
            { text: "Google", value: "google" },
            { text: "Bing", value: "bing" },
            { text: "DuckDuckGo", value: "duckduckgo" }
        ]
        onActivated: Plasmoid.configuration.searchEngine = currentValue

        Component.onCompleted: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].value === Plasmoid.configuration.searchEngine) {
                    currentIndex = i
                    break
                }
            }
        }
    }
}
