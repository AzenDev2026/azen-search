/*
    Azen Search — Windows 11 风格搜索框
    Copyright (C) 2026 AzenDev2026
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation


    Layout.preferredWidth: Plasmoid.configuration.pillWidth
    Layout.minimumWidth: Kirigami.Units.gridUnit * 2
    Layout.maximumWidth: Kirigami.Units.gridUnit * 30

    // 网页搜索地址（根据配置的搜索引擎）
    readonly property string webSearchBase: {
        switch (Plasmoid.configuration.searchEngine) {
            case "bing": return "https://www.bing.com/search?q="
            case "duckduckgo": return "https://duckduckgo.com/?q="
            default: return "https://www.google.com/search?q="
        }
    }

    // 当前搜索文字（弹出面板里的输入框会双向同步到这里）
    property string queryText: ""

    // 结果模型：每个 runner（应用、文件、最近文档……）一组
    Kicker.RunnerModel {
        id: runnerModel
        mergeResults: false
        runners: [
            "krunner_services",
            "krunner_systemsettings",
            "recentdocuments",
            "baloosearch",
            "locations",
            "windows",
            "calculator",
            "unitconverter"
        ]
        query: root.queryText

    }

    // 启动一个搜索结果
    function runMatch(subModel, row) {
        if (!subModel || row < 0 || row >= subModel.count) return
        if (subModel.trigger(row, "", "")) {
            root.expanded = false
        }
    }

    // 回车：启动第一个结果；没有结果就去网页搜索
    function runFirst() {
        for (var i = 0; i < runnerModel.count; ++i) {
            var sub = runnerModel.modelForRow(i)
            if (sub && sub.count > 0) {
                runMatch(sub, 0)
                return
            }
        }
        if (root.queryText.length > 0) openWebSearch()
    }

    function openWebSearch() {
        Qt.openUrlExternally(root.webSearchBase + encodeURIComponent(root.queryText))
        root.expanded = false
    }

    // ---------- 面板上的胶囊搜索框 ----------
    compactRepresentation: MouseArea {
        id: pill
        hoverEnabled: true
        implicitWidth: Plasmoid.configuration.pillWidth
        implicitHeight: 32

        onClicked: root.expanded = !root.expanded

        Rectangle {
            id: pillBg
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: parent.height * 0.8
            radius: height / 2
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b,
                           pill.containsMouse ? 0.14 : 0.09)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                  Kirigami.Theme.textColor.g,
                                  Kirigami.Theme.textColor.b, 0.08)
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.94
            height: parent.height * 0.8
            spacing: 9

            Kirigami.Icon {
                source: "search"
                width: 16
                height: 16
                opacity: 0.75
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: i18n("搜索")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.defaultFont
                Layout.fillWidth: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                visible: pill.width >= 140
            }
        }
    }

    // ---------- 展开后的搜索面板 ----------
    fullRepresentation: Rectangle {
        id: panel
        width: Math.max(540, Plasmoid.configuration.pillWidth + 40)
        height: panelColumn.implicitHeight + 20
        radius: 8
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.15)

        Layout.preferredWidth: width
        Layout.preferredHeight: height

        // 展开时聚焦输入框
        onVisibleChanged: {
            if (visible) {
                searchField.forceActiveFocus()
                searchField.selectAll()
            }
        }

        Keys.onEscapePressed: root.expanded = false

        ColumnLayout {
            id: panelColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // ---- 搜索输入框 ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "search"
                    width: 20
                    height: 20
                    opacity: 0.6
                }

                PC3.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18n("搜索应用、文件和网页")
                    focus: true
                    text: root.queryText
                    onTextChanged: root.queryText = text
                    onAccepted: root.runFirst()
                }
            }

            // ---- 结果列表（各组按顺序堆叠成一条平铺列表） ----
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 400)
                contentHeight: resultsColumn.height
                clip: true
                visible: searchField.text.length > 0

                Column {
                    id: resultsColumn
                    width: parent.width

                    Repeater {
                        model: runnerModel

                        delegate: Column {
                            id: runnerColumn
                            width: resultsColumn.width

                            // 该 runner 的结果子模型
                            property var sub: runnerModel.modelForRow(index)

                            // 限制每组显示的数量，避免列表过长
                            function applyLimit() {
                                if (sub) {
                                    try {
                                        if ("limit" in sub) {
                                            sub.limit = (index === 0 ? 5
                                                         : index === 1 ? 4 : 3)
                                        }
                                    } catch (e) { }
                                }
                            }

                            onSubChanged: applyLimit()
                            Component.onCompleted: applyLimit()

                            ListView {
                                width: resultsColumn.width
                                height: contentHeight
                                interactive: false
                                model: runnerColumn.sub
                                visible: runnerColumn.sub ? runnerColumn.sub.count > 0 : false

                                delegate: ResultDelegate {
                                    width: resultsColumn.width
                                    onClicked: root.runMatch(runnerColumn.sub, index)
                                }
                            }
                        }
                    }
                }
            }

            // ---- 空状态提示 ----
            PC3.Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n("输入关键字搜索应用、文件和网页")
                color: Kirigami.Theme.disabledTextColor
                visible: searchField.text.length === 0
            }

            // ---- 分隔线 + 网页搜索 ----
            Item {
                visible: searchField.text.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.1)
                }
            }

            ResultDelegate {
                Layout.fillWidth: true
                visible: searchField.text.length > 0
                iconName: "internet-services"
                title: i18n("在网页中搜索“%1”", searchField.text)
                onClicked: root.openWebSearch()
            }
        }
    }

    // ---------- 单条结果样式 ----------
    component ResultDelegate: MouseArea {
        id: resultItem
        height: resultRow.implicitHeight + 12
        hoverEnabled: true

        // 独立使用时（如网页搜索行）手动指定这些
        property string iconName: ""
        property string title: ""
        property string subTitle: ""

        // 在结果列表里使用时，model 提供 name / subtext / icon 角色
        readonly property bool hasModel: typeof model !== "undefined" && model

        readonly property string displayName: title.length > 0 ? title
            : (hasModel && model.name !== undefined ? model.name : "")

        readonly property string displaySub: subTitle.length > 0 ? subTitle
            : (hasModel && model.subtext !== undefined ? model.subtext : "")

        readonly property string displayIcon: iconName.length > 0 ? iconName
            : (hasModel && model.icon !== undefined && String(model.icon).length > 0
               ? String(model.icon) : "application-x-executable")

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: resultItem.containsMouse
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                          Kirigami.Theme.textColor.b, 0.08)
                : "transparent"
        }

        RowLayout {
            id: resultRow
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Kirigami.Icon {
                source: displayIcon
                width: 24
                height: 24
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: displayName
                    elide: Text.ElideRight
                    font: Kirigami.Theme.defaultFont
                    color: Kirigami.Theme.textColor
                }

                Text {
                    Layout.fillWidth: true
                    text: displaySub
                    elide: Text.ElideRight
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                    visible: displaySub.length > 0
                }
            }
        }
    }
}
