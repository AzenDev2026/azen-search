/*
    Azen Search — Windows 11 style search box for the panel
    Copyright (C) 2026 AzenDev2026
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation

    Layout.preferredWidth: pillWidth
    Layout.minimumWidth: Kirigami.Units.gridUnit * 2
    Layout.maximumWidth: Kirigami.Units.gridUnit * 30

    // ---------- 外观：长度（仅图标 / 小 / 中 / 大） ----------
    readonly property string sizePreset: Plasmoid.configuration.sizePreset
    readonly property int pillWidth: {
        switch (sizePreset) {
            case "iconOnly": return 44
            case "small": return 100
            case "large": return 240
            default: return 120  // medium，也就是原来的尺寸
        }
    }

    // ---------- 外观：内部（纯文字 / 图标 + 文字） ----------
    readonly property bool showIcon: sizePreset === "iconOnly"
        || Plasmoid.configuration.innerStyle === "icontext"
    readonly property bool showText: sizePreset !== "iconOnly"

    // ---------- 外观：外壳（圆润 Windows 11 / 方形 Windows 10） ----------
    readonly property bool roundedShell: Plasmoid.configuration.shellStyle !== "square"
    readonly property int panelRadius: roundedShell ? 12 : 4

    // ---------- 网页搜索地址 ----------
    readonly property string webSearchBase: {
        switch (Plasmoid.configuration.searchEngine) {
            case "bing": return "https://www.bing.com/search?q="
            case "duckduckgo": return "https://duckduckgo.com/?q="
            default: return "https://www.google.com/search?q="
        }
    }

    // 当前搜索文字（面板输入框与 runner 双向同步）
    property string queryText: ""

    // ---------- KRunner 结果模型 ----------
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

    // 回车兜底：第一个结果，或者网页搜索
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

    // ---------- 结果管线：采集 C++ 模型 → 模糊打分 → 过滤排序分组 ----------
    // flat 数组：每行是结果对象；分组标题是 {isHeader: true, title}
    property var pendingRows: []
    property var resultRows: []
    property int selectedIndex: -1
    property int collectOrder: 0

    Timer {
        id: publishTimer
        interval: 260
        onTriggered: root.publishResults()
    }

    onQueryTextChanged: {
        pendingRows = []
        resultRows = []
        selectedIndex = -1
        collectOrder = 0
        publishTimer.restart()
    }

    function addPendingRow(row) {
        row.order = collectOrder
        collectOrder++
        var a = pendingRows
        a.push(row)
        publishTimer.restart()
    }

    function removePendingRow(row) {
        var a = pendingRows
        var idx = a.indexOf(row)
        if (idx >= 0) a.splice(idx, 1)
        publishTimer.restart()
    }

    // 隐藏采集器：把 C++ 模型的每一行拷贝成 JS 对象（用正确的角色名：
    // display 名称 / description 说明 / decoration 图标 / group 分类）
    Repeater {
        id: collector
        model: runnerModel
        delegate: Item {
            property int groupIdx: index
            property var sub: runnerModel.modelForRow(index)
            Repeater {
                model: sub
                delegate: Item {
                    property var rowObj: null
                    Component.onCompleted: {
                        rowObj = {
                            disp: model.display,
                            desc: model.description,
                            icon: model.decoration,
                            group: model.group,
                            groupIdx: groupIdx,
                            sub: sub,
                            row: index,
                            isNew: model.isNewlyInstalled === true
                        }
                        root.addPendingRow(rowObj)
                    }
                    Component.onDestruction: {
                        if (rowObj) root.removePendingRow(rowObj)
                    }
                }
            }
        }
    }

    // ---------- 模糊匹配打分 ----------
    // 完全包含 = 1.0+；按顺序散落匹配 = 部分分（词首/连续/首字母有加分）
    function fuzzyScore(text, query) {
        if (query.length === 0) return 1
        var t = String(text || "").toLowerCase()
        var q = query.toLowerCase()
        var pos = t.indexOf(q)
        if (pos >= 0) return pos === 0 ? 1.5 : 1.0
        var qi = 0, last = -1, first = -1, total = 0
        for (var i = 0; i < t.length && qi < q.length; ++i) {
            if (t.charAt(i) === q.charAt(qi)) {
                var bonus = 1.0
                if (i === 0 || " ._-/".indexOf(t.charAt(i - 1)) >= 0) bonus += 0.5
                else if (i === last + 1) bonus += 0.3
                if (first < 0) first = i
                total += bonus
                last = i
                qi++
            }
        }
        if (qi < q.length) return 0
        if (t.charAt(0) === q.charAt(0)) total += 0.3
        return Math.min(1.0, total / (q.length * 1.5))
    }

    function sectionTitle(group) {
        switch (String(group)) {
            case "Applications": return i18n("应用")
            case "System Settings": return i18n("系统设置")
            case "System Information": return i18n("系统信息")
            case "Windows": return i18n("窗口")
            case "Recent Documents": return i18n("最近使用")
            case "Files": return i18n("文件")
            case "Locations":
            case "Places": return i18n("位置")
            case "Calculator": return i18n("计算器")
            case "Unit Converter": return i18n("单位换算")
            default: return String(group || i18n("结果"))
        }
    }

    function publishResults() {
        var q = queryText.trim().toLowerCase()
        if (q.length === 0) {
            resultRows = []
            selectedIndex = -1
            return
        }
        var rows = pendingRows.slice()
        var i
        for (i = 0; i < rows.length; ++i) {
            rows[i].score = fuzzyScore(rows[i].disp, q)
        }
        // 应用组做模糊过滤：去掉乱匹配的杂音（只在该组内过滤，计算器等不受影响）
        var kept = []
        for (i = 0; i < rows.length; ++i) {
            var r = rows[i]
            if (r.group === "Applications" && q.length >= 2 && r.score < 0.55) continue
            kept.push(r)
        }
        // 组内按模糊得分排序，组间保持 runner 顺序（应用在最前）
        kept.sort(function (a, b) {
            if (a.groupIdx !== b.groupIdx) return a.groupIdx - b.groupIdx
            if (a.score !== b.score) return b.score - a.score
            return a.order - b.order
        })
        // 分组 + 每组上限（应用 6 条，其他 4 条，总共最多 24 条）
        var flat = []
        var lastKey = null
        var groupCount = 0
        var total = 0
        for (i = 0; i < kept.length; ++i) {
            var row = kept[i]
            var key = String(row.group)
            if (key !== lastKey) {
                groupCount = 0
                flat.push({ isHeader: true, title: sectionTitle(row.group) })
                lastKey = key
            }
            var cap = (key === "Applications") ? 6 : 4
            if (groupCount >= cap || total >= 24) continue
            flat.push(row)
            groupCount++
            total++
        }
        // 去掉没有结果的分组标题
        var cleaned = []
        for (i = 0; i < flat.length; ++i) {
            if (flat[i].isHeader) {
                if (i + 1 < flat.length && !flat[i + 1].isHeader) cleaned.push(flat[i])
            } else {
                cleaned.push(flat[i])
            }
        }
        resultRows = cleaned
        // 预选第一条结果（回车直接启动，Windows 风格）
        selectedIndex = -1
        for (i = 0; i < cleaned.length; ++i) {
            if (!cleaned[i].isHeader) {
                selectedIndex = i
                break
            }
        }
    }

    // ---------- 键盘导航 ----------
    function moveSelection(delta) {
        var rows = resultRows
        if (rows.length === 0) return
        if (selectedIndex < 0) selectedIndex = 0
        var guard = 0
        do {
            selectedIndex = (selectedIndex + delta + rows.length) % rows.length
            if (++guard > rows.length) break
        } while (rows[selectedIndex].isHeader)
    }

    function activateSelected() {
        var rows = resultRows
        if (selectedIndex >= 0 && selectedIndex < rows.length) {
            var r = rows[selectedIndex]
            if (!r.isHeader && r.sub) {
                runMatch(r.sub, r.row)
                return
            }
        }
        runFirst()
    }

    function ensureVisible(rowY, rowH) {
        var top = resultsFlick.contentY
        var bottom = top + resultsFlick.height
        if (rowY < top) {
            resultsFlick.contentY = Math.max(0, rowY - 8)
        } else if (rowY + rowH > bottom) {
            resultsFlick.contentY = rowY + rowH - resultsFlick.height + 8
        }
    }

    // ---------- 面板上的胶囊搜索框 ----------
    compactRepresentation: MouseArea {
        id: pill
        hoverEnabled: true
        implicitWidth: root.pillWidth
        implicitHeight: root.sizePreset === "iconOnly" ? 36 : 32

        onClicked: root.expanded = !root.expanded

        Rectangle {
            id: pillBg
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: parent.height * 0.8
            radius: root.roundedShell ? height / 2 : 4
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
                visible: root.showIcon
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: i18n("Search here")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.defaultFont
                Layout.fillWidth: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: root.showIcon ? Text.AlignLeft : Text.AlignHCenter
                visible: root.showText
            }
        }
    }

    // ---------- 展开后的搜索面板 ----------
    fullRepresentation: Rectangle {
        id: panel
        width: Math.max(520, root.pillWidth + 80)
        height: panelColumn.implicitHeight + 24
        radius: root.panelRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.15)

        Layout.preferredWidth: width
        Layout.preferredHeight: height

        // ---------- 弹窗居中：把面板窗口移到屏幕正中间（Windows 搜索风格） ----------
        // 弹窗是面板这一项的克隆实例，所以居中逻辑必须写在这里面，
        // 用自己的 Window.window 才能拿到真正的弹窗窗口。
        property int centerTicks: 0
        Timer {
            id: centerPopupTimer
            interval: 30
            repeat: true
            onTriggered: {
                panel.centerTicks++
                if (panel.centerTicks > 20) {
                    stop()
                    return
                }
                var win = panel.Window.window
                if (!win || win.width < 200) return
                var scr = root.screenGeometry
                if (!scr || scr.width <= 0) return
                var cx = Math.round(scr.x + (scr.width - win.width) / 2)
                var cy = Math.round(scr.y + (scr.height - win.height) / 2)
                win.x = cx
                win.y = cy
            }
        }

        function recenter() {
            if (!panel.visible) return
            panel.centerTicks = 0
            centerPopupTimer.start()
        }

        // 展开、以及结果加载导致尺寸变化时，重新居中
        onVisibleChanged: {
            if (visible) {
                recenter()
                searchField.forceActiveFocus()
                searchField.selectAll()
            }
        }
        onHeightChanged: recenter()
        onWidthChanged: recenter()

        ColumnLayout {
            id: panelColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ---- 搜索输入框 ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "search"
                    width: 20
                    height: 20
                    opacity: 0.6
                    Layout.alignment: Qt.AlignVCenter
                }

                PC3.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18n("搜索应用、文件和网页")
                    focus: true
                    text: root.queryText
                    onTextChanged: root.queryText = text
                    onAccepted: root.activateSelected()

                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onEscapePressed: root.expanded = false
                }
            }

            // ---- 结果列表（分组标题 + 结果行） ----
            Flickable {
                id: resultsFlick
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 420)
                contentHeight: resultsColumn.height
                clip: true
                visible: root.queryText.length > 0 && root.resultRows.length > 0

                Column {
                    id: resultsColumn
                    width: parent.width

                    Repeater {
                        model: root.resultRows
                        delegate: RowDelegate
                    }
                }
            }

            // ---- 没有结果时的提示 ----
            PC3.Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n("没有找到匹配的结果")
                color: Kirigami.Theme.disabledTextColor
                visible: root.queryText.length > 0 && root.resultRows.length === 0
            }

            // ---- 空状态提示 ----
            PC3.Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n("输入关键字搜索应用、文件和网页")
                color: Kirigami.Theme.disabledTextColor
                visible: root.queryText.length === 0
            }

            // ---- 分隔线 + 网页搜索 ----
            Item {
                visible: root.queryText.length > 0
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

            ResultRow {
                Layout.fillWidth: true
                visible: root.queryText.length > 0
                iconName: "internet-services"
                title: i18n("在网页中搜索“%1”", root.queryText)
                onClicked: root.openWebSearch()
            }
        }
    }

    // ---------- 单条结果样式（列表里通过 modelData 提供角色） ----------
    component RowDelegate: Item {
        id: rowItem
        width: parent.width
        height: modelData.isHeader === true ? 30 : rowContent.implicitHeight + 14
        property int rowY: Math.round(y)
        readonly property bool isHeaderRow: modelData.isHeader === true
        readonly property bool isSelected: !isHeaderRow && index === root.selectedIndex

        onIsSelectedChanged: { if (isSelected) root.ensureVisible(rowY, height) }
        onYChanged: { if (isSelected) root.ensureVisible(rowY, height) }
        onHeightChanged: { if (isSelected) root.ensureVisible(rowY, height) }

        // 分组标题
        PC3.Label {
            visible: rowItem.isHeaderRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.title
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            opacity: 0.85
        }

        // 结果行
        MouseArea {
            visible: !rowItem.isHeaderRow
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.runMatch(modelData.sub, modelData.row)

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: rowItem.isSelected
                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                              Kirigami.Theme.highlightColor.g,
                              Kirigami.Theme.highlightColor.b, 0.30)
                    : (parent.containsMouse
                        ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                  Kirigami.Theme.textColor.b, 0.08)
                        : "transparent")
            }

            RowLayout {
                id: rowContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                spacing: 10

                Kirigami.Icon {
                    source: modelData.icon
                    width: 26
                    height: 26
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: modelData.disp || ""
                        elide: Text.ElideRight
                        font: Kirigami.Theme.defaultFont
                        color: Kirigami.Theme.textColor
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.desc || ""
                        elide: Text.ElideRight
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.disabledTextColor
                        visible: String(modelData.desc || "").length > 0
                    }
                }

                // 右侧分类小标签（Windows 风格）
                Text {
                    text: root.sectionTitle(modelData.group)
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                    opacity: 0.75
                    Layout.alignment: Qt.AlignVCenter
                    visible: String(modelData.group || "").length > 0 && !modelData.isNew
                }

                // 新安装的应用徽章
                Rectangle {
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                                   Kirigami.Theme.highlightColor.g,
                                   Kirigami.Theme.highlightColor.b, 0.22)
                    Layout.alignment: Qt.AlignVCenter
                    visible: modelData.isNew === true
                    PC3.Label {
                        anchors.centerIn: parent
                        text: i18n("新")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                        color: Kirigami.Theme.highlightColor
                    }
                }
            }
        }
    }

    // ---------- 独立结果行（网页搜索等固定行） ----------
    component ResultRow: MouseArea {
        id: resultItem
        Layout.fillWidth: true
        implicitHeight: resultRow.implicitHeight + 12
        hoverEnabled: true

        property string iconName: ""
        property string title: ""

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
                source: iconName
                width: 24
                height: 24
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                Layout.fillWidth: true
                text: title
                elide: Text.ElideRight
                font: Kirigami.Theme.defaultFont
                color: Kirigami.Theme.textColor
            }
        }
    }
}
