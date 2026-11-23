/*
    Azen Search 配置清单
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("外观与搜索")
        icon: "edit-find"
        source: "ConfigGeneral.qml"
    }
}
