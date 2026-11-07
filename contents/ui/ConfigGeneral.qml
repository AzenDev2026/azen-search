/*
    Azen Search 配置界面
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    QQC2.SpinBox {
        id: widthSpin
        Kirigami.FormData.label: i18n("搜索框宽度（像素）:")
        from: 200
        to: 600
        stepSize: 20
        value: Plasmoid.configuration.pillWidth
        onValueChanged: Plasmoid.configuration.pillWidth = value
    }

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
