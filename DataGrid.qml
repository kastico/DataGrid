import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

Item {
    id: tableRoot

    // ============================================================================
    // TABLE CONFIGURATION
    // ============================================================================
    property alias model: tableView.model
    property string tableId: "defaultTable"
    property int radius: 8
    property int currentRow: -1

    // ============================================================================
    // VISIBILITY & BEHAVIOR
    // ============================================================================
    property bool showHeader: true
    property bool showRowNumbers: true
    property bool enableKeyboardDelete: true
    property bool showTopHeader: true
    property bool showTopHeaderButtons: true
    property bool showSearchBar: true

    // ============================================================================
    // HEADER STYLING
    // ============================================================================
    property color headerColor: "#495a6b"
    property color headerBorderColor: "#dee2e6"
    property color headerTextColor: "white"
    property string rowNumberHeaderText: "#"

    // ============================================================================
    // TOP HEADER STYLING
    // ============================================================================
    property color topHeaderColor: "#f8f9fa"
    property color topHeaderBorderColor: "#dee2e6"
    property int topHeaderHeight: 60

    // ============================================================================
    // CELL STYLING
    // ============================================================================
    property color cellColor: "transparent"
    property color cellTextColor: "#2c3e50"
    property color cellBorderColor: "#dee2e6"

    // ============================================================================
    // SELECTION STYLING
    // ============================================================================
    property color highlightColor: "#2196f3"
    property color highlightTextColor: "white"

    // ============================================================================
    // INTERACTION STYLING
    // ============================================================================
    property color resizeHandleColor: "#3498db"

    // ============================================================================
    // COLUMN CONFIGURATION
    // ============================================================================
    property var columns: []
    property var columnOrder: []
    property var columnWidths: []
    property var columnTitles: []
    property var columnVisibility: []

    // ============================================================================
    // SORTING CONFIGURATION
    // ============================================================================
    property int sortColumn: -1
    property bool sortAscending: true

    // ============================================================================
    // MENU CONFIGURATION
    // ============================================================================
    property var contextMenuActions: []
    property string contextMenuTitle: "Row Actions"
    property var headerMenuActions: []
    property string headerMenuTitle: "Header Actions"

    // ============================================================================
    // TOOLBAR & BUTTONS
    // ============================================================================
    property var buttons: [{
            "id": "add",
            "icon": "+",
            "color": "#4CAF50",
            "enabled": true,
            "handler": function () {
                addRowRequested()
            }
        }, {
            "id": "delete",
            "icon": "×",
            "color": currentRow >= 0 ? "#f44336" : "#cccccc",
            "enabled": currentRow >= 0,
            "handler": function () {
                deleteCurrentRow()
            }
        }, {
            "id": "moveUp",
            "icon": "↑",
            "color": currentRow > 0 ? "#2196F3" : "#cccccc",
            "enabled": currentRow > 0,
            "handler": function () {
                moveRowUp(currentRow)
            }
        }, {
            "id": "moveDown",
            "icon": "↓",
            "color": currentRow >= 0
                     && currentRow < tableView.count - 1 ? "#2196F3" : "#cccccc",
            "enabled": currentRow >= 0 && currentRow < tableView.count - 1,
            "handler": function () {
                moveRowDown(currentRow)
            }
        }, {
            "id": "columns",
            "icon": "☰",
            "color": "#9C27B0",
            "enabled": true,
            "handler": function () {
                showColumnVisibilityMenu()
            }
        }]
    property var customButtons: []

    // ============================================================================
    // SEARCH CONFIGURATION
    // ============================================================================
    property string searchPlaceholder: "Search..."
    property string searchText: ""

    // ============================================================================
    // TABLE DIMENSIONS
    // ============================================================================
    width: 800 // default
    height: 600 // default

    // ============================================================================
    // RENDERING SETTINGS
    // ============================================================================
    layer.enabled: true
    layer.smooth: true
    clip: true

    // ============================================================================
    // SIGNALS
    // ============================================================================
    signal columnResized(int columnIndex, real newWidth)
    signal columnMoved(int fromIndex, int toIndex)
    signal rowSelected(int rowIndex)
    signal rowDeleted(int rowIndex)
    signal deleteRequested(int rowIndex)
    signal contextMenuActionTriggered(string actionId, int rowIndex)
    signal addRowRequested
    signal moveRowRequested(int fromIndex, int toIndex)
    signal duplicateRowRequested(int rowIndex)
    signal columnVisibilityToggled(int columnIndex, bool visible)
    signal columnSorted(int columnIndex, bool ascending)
    signal customButtonClicked(string buttonId)


    // ============================================================================
    // SETTINGS
    // ============================================================================
    Settings {
        id: tableSettings
        category: "FakeTable_" + tableRoot.tableId

        property string savedColumnOrder: ""
        property string savedColumnWidths: ""
        property string savedColumnVisibility: ""
        property bool showRowNumbers: true
        property bool showHeader: true
        property int sortColumn: -1
        property bool sortAscending: true
    }

    property bool _isInitializing: true

    property int visibleColumnsCount: {
        let count = 0
        for (var i = 0; i < columnVisibility.length; i++) {
            if (columnVisibility[i])
                count++
        }
        return count
    }

    property real rowNumberWidth: 0.06

    property var adjustedColumnWidths: {
        let adjusted = []
        let totalVisibleWidth = 1.0 - (showRowNumbers ? rowNumberWidth : 0)
        let totalOriginalWidth = 0

        // Calculate total width of visible columns
        for (var i = 0; i < columnWidths.length; i++) {
            if (columnVisibility[i]) {
                totalOriginalWidth += columnWidths[i]
            }
        }

        // Distribute proportionally
        for (i = 0; i < columnWidths.length; i++) {
            if (columnVisibility[i]) {
                let proportionalWidth = (columnWidths[i] / totalOriginalWidth) * totalVisibleWidth
                adjusted.push(proportionalWidth)
            } else {
                adjusted.push(0)
            }
        }
        return adjusted
    }

    onColumnOrderChanged: {
        if (!_isInitializing && columnOrder.length > 0 && columns.length > 0
                && columnOrder.length === columns.length) {
            let orderString = arrayToString(columnOrder)
            tableSettings.savedColumnOrder = orderString
            if (tableView)
                tableView.forceLayout()
        }
    }

    onColumnWidthsChanged: {
        if (!_isInitializing && columnWidths.length > 0 && columns.length > 0
                && columnWidths.length === columns.length) {
            let widthsString = arrayToString(columnWidths)
            tableSettings.savedColumnWidths = widthsString
            if (tableView)
                tableView.forceLayout()
        }
    }

    onShowRowNumbersChanged: {
        if (!_isInitializing) {
            tableSettings.showRowNumbers = showRowNumbers
            if (tableView)
                tableView.forceLayout()
        }
    }

    onShowHeaderChanged: {
        if (!_isInitializing) {
            tableSettings.showHeader = showHeader
        }
    }

    onColumnsChanged: {
        initializeColumnProperties()
    }

    // ============================================================================
    // CONTAINER
    // ============================================================================
    Rectangle {
        id: tableContainer
        anchors.fill: parent
        color: "transparent"
        radius: tableRoot.radius
        clip: true
        border.color: tableRoot.headerBorderColor
        border.width: 1

        Rectangle {
            id: topHeader
            width: parent.width
            height: showTopHeader ? topHeaderHeight : 0
            color: topHeaderColor
            border.color: topHeaderBorderColor
            border.width: 1
            visible: showTopHeader
            z: 3

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    height: 40
                    radius: tableRoot.radius
                    border.color: "#ced4da"
                    border.width: 1
                    visible: showSearchBar
                    Layout.alignment: Qt.AlignRight

                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 8

                        Text {
                            anchors.margins: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🔍"
                            font.pixelSize: 14
                            color: "#6c757d"
                        }

                        TextField {
                            id: searchField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            placeholderText: searchPlaceholder
                            text: searchText
                            background: Rectangle {
                                color: "transparent"
                                border.width: 0
                            }
                            onTextChanged: {
                                searchText = text
                            }
                        }
                    }
                }

                Row {
                    id: customButtonsRow
                    Layout.alignment: Qt.AlignLeft
                    spacing: 8
                    visible: showTopHeaderButtons

                    Repeater {
                        model: tableRoot.buttons
                        delegate: Rectangle {
                            width: 40
                            height: 40
                            radius: 5
                            color: buttonMouseArea.containsPress ? Qt.darker(modelData.color || "#666666", 1.2) : buttonMouseArea.containsMouse ? Qt.lighter(modelData.color || "#666666", 1.1) : (modelData.color || "#666666")

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "?"
                                font.pixelSize: modelData.iconSize || 16
                                font.bold: true
                                color: "white"
                            }

                            MouseArea {
                                id: buttonMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    customButtonClicked(modelData.id)
                                    if (modelData.handler) {
                                        modelData.handler()
                                    }
                                }
                            }
                        }
                    }

                    Repeater {
                         model: tableRoot.customButtons
                         delegate: Rectangle {
                             width: 40
                             height: 40
                             radius: 5
                             color: customButtonMouseArea.containsPress ? Qt.darker(modelData.color || "#666666", 1.2) : customButtonMouseArea.containsMouse ? Qt.lighter(modelData.color || "#666666", 1.1) : (modelData.color || "#666666")

                             Text {
                                 anchors.centerIn: parent
                                 text: modelData.icon || "?"
                                 font.pixelSize: modelData.iconSize || 16
                                 font.bold: true
                                 color: "white"
                             }

                             MouseArea {
                                 id: customButtonMouseArea
                                 anchors.fill: parent
                                 hoverEnabled: true
                                 cursorShape: Qt.PointingHandCursor
                                 onClicked: {
                                     customButtonClicked(modelData.id)
                                     if (modelData.handler) {
                                         modelData.handler()
                                     }
                                 }
                             }
                         }
                     }
                }
            }
        }

        // ============================================================================
        // MAIN TABLE VIEW
        // ============================================================================
        ListView {
            id: tableView
            anchors {
                top: topHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            clip: true

            currentIndex: -1
            onWidthChanged: forceLayout()
            keyNavigationWraps: true

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 300 }
                    NumberAnimation { properties: "x"; to: -100; duration: 300 }
                }
            }
            removeDisplaced: Transition {
                SequentialAnimation {
                    PauseAnimation { duration: 300 }
                    NumberAnimation { properties: "x,y"; duration: 300 }
                }
            }
            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
                    NumberAnimation { properties: "x"; from: 100; to: 0; duration: 300 }
                }
            }
            move: Transition {
                NumberAnimation { properties: "x,y"; duration: 300 }
            }

            headerPositioning: ListView.OverlayHeader
            header: Rectangle {
                id: header
                width: tableView.width
                height: tableRoot.showHeader ? 50 : 0
                color: tableRoot.headerColor
                z: 2
                visible: tableRoot.showHeader
                border.color: tableRoot.headerBorderColor
                border.width: 1

                Row {
                    id: headerRow
                    anchors.fill: parent
                    spacing: 0

                    // Row number column header
                    Rectangle {
                        id: rowNumberHeader
                        width: showRowNumbers ? tableView.width * rowNumberWidth : 0
                        height: parent.height
                        color: tableRoot.headerColor
                        visible: showRowNumbers
                        clip: true
                        border.color: tableRoot.headerBorderColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: tableRoot.rowNumberHeaderText
                            font.pixelSize: 14
                            font.bold: true
                            color: tableRoot.headerTextColor
                        }
                    }

                    // Column headers
                    Repeater {
                        id: headerRepeater
                        model: tableRoot.columnOrder.length

                        Rectangle {
                            id: headerItem
                            width: tableRoot.columnVisibility[tableRoot.columnOrder[index]] ? tableView.width * tableRoot.adjustedColumnWidths[tableRoot.columnOrder[index]] : 0
                            height: parent.height
                            color: tableRoot.headerColor
                            visible: tableRoot.columnVisibility[tableRoot.columnOrder[index]]
                            border.color: tableRoot.headerBorderColor
                            border.width: 1
                            property int columnIndex: tableRoot.columnOrder[index]
                            property int displayIndex: index
                            property real startX: 0
                            property real startWidth: 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tableRoot.columnTitles[columnIndex]
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: tableRoot.headerTextColor
                                    elide: Text.ElideRight
                                }

                                // Sorting indicator
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: tableRoot.sortColumn === columnIndex
                                    text: tableRoot.sortAscending ? "↑" : "↓"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: tableRoot.headerTextColor
                                }
                            }

                            // Column resize handle
                            Rectangle {
                                id: resizeHandle
                                width: 6
                                height: parent.height
                                anchors.right: parent.right
                                color: resizeMouseArea.pressed ? resizeHandleColor : "transparent"

                                MouseArea {
                                    id: resizeMouseArea
                                    anchors {
                                        fill: parent
                                        leftMargin: -3
                                        rightMargin: -3
                                    }
                                    cursorShape: Qt.SizeHorCursor
                                    preventStealing: true

                                    onPressed: {
                                        headerItem.startX = mapToItem(header,
                                                                      mouseX,
                                                                      mouseY).x
                                        headerItem.startWidth = headerItem.width
                                    }

                                    onPositionChanged: {
                                        if (pressed) {
                                            let currentX = mapToItem(header,
                                                                     mouseX,
                                                                     mouseY).x
                                            let delta = currentX - headerItem.startX
                                            let newWidth = Math.max(
                                                    50,
                                                    headerItem.startWidth + delta)

                                            let newRelativeWidth = newWidth / tableView.width

                                            if (displayIndex < tableRoot.columnOrder.length - 1) {
                                                let currentColIndex = columnIndex
                                                let nextColIndex = tableRoot.columnOrder[displayIndex + 1]

                                                let widthDiff = newRelativeWidth - tableRoot.adjustedColumnWidths[currentColIndex]
                                                let nextColumnNewWidth = tableRoot.adjustedColumnWidths[nextColIndex] - widthDiff

                                                if (nextColumnNewWidth >= 0.05) {
                                                    let scaleFactor = 1.0 / (1.0 - rowNumberWidth)
                                                    let originalNewWidth = newRelativeWidth
                                                        * scaleFactor
                                                    let originalNextWidth = nextColumnNewWidth
                                                        * scaleFactor

                                                    let newWidths = tableRoot.columnWidths.slice()
                                                    newWidths[currentColIndex] = originalNewWidth
                                                    newWidths[nextColIndex] = originalNextWidth

                                                    tableRoot.columnWidths = newWidths
                                                    tableRoot.columnResized(
                                                                currentColIndex,
                                                                newWidth)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors {
                                    left: parent.left
                                    right: resizeHandle.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.RightButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        showHeaderMenu(columnIndex)
                                    }
                                }
                            }

                            MouseArea {
                                anchors {
                                    left: parent.left
                                    right: resizeHandle.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton

                                onPressed: {
                                    dragItem.columnIndex = columnIndex
                                    dragItem.displayIndex = displayIndex
                                    dragItem.x = headerItem.mapToItem(header, 0, 0).x
                                    dragItem.width = headerItem.width
                                    dragItem.visible = true
                                }

                                onReleased: {
                                    dragItem.visible = false

                                    let dragCenter = dragItem.x + dragItem.width / 2
                                    let newDisplayIndex = -1
                                    let accumulatedWidth = showRowNumbers ? tableView.width * rowNumberWidth : 0

                                    for (var i = 0; i < tableRoot.columnOrder.length; i++) {
                                        if (!tableRoot.columnVisibility[tableRoot.columnOrder[i]])
                                            continue

                                        let colWidth = tableView.width * tableRoot.adjustedColumnWidths[tableRoot.columnOrder[i]]
                                        if (dragCenter >= accumulatedWidth && dragCenter < accumulatedWidth + colWidth) {
                                            newDisplayIndex = i
                                            break
                                        }
                                        accumulatedWidth += colWidth
                                    }

                                    if (newDisplayIndex !== -1
                                            && newDisplayIndex !== displayIndex) {
                                        tableRoot.moveColumn(displayIndex, newDisplayIndex)
                                    }
                                }

                                onPositionChanged: mouse => {
                                    if (pressed) {
                                        let minX = showRowNumbers ? tableView.width * rowNumberWidth : 0
                                        dragItem.x = Math.max(minX, Math.min(header.width - dragItem.width, mapToItem(header, mouseX, mouseY).x - dragItem.width / 2))
                                    }
                                }
                            }
                        }
                    }
                }

                // Visual drag indicator
                Rectangle {
                    id: dragItem
                    visible: false
                    height: header.height
                    color: "#3498db"
                    opacity: 0.8
                    border.color: "#2980b9"
                    border.width: 2
                    radius: 4

                    property int columnIndex: -1
                    property int displayIndex: -1
                }
            }

            // Row delegate
            delegate: Rectangle {
                id: rowDelegate
                width: tableView.width
                height: 50
                color: "transparent"

                property color rowColor: ListView.isCurrentItem ? tableRoot.highlightColor : (index % 2 === 0 ? "#f8f9fa" : "#ffffff")
                property bool isSelected: ListView.isCurrentItem

                Binding on width {
                    value: tableView.width
                }

                Row {
                    id: rowLayout
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        id: rowNumberCell
                        width: showRowNumbers ? tableView.width * rowNumberWidth : 0
                        height: parent.height
                        color: rowColor
                        visible: showRowNumbers
                        border.color: tableRoot.cellBorderColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            font.pixelSize: 12
                            font.bold: true
                            color: isSelected ? tableRoot.highlightTextColor : "#6c757d"
                        }
                    }

                    Repeater {
                        model: tableRoot.columnOrder.length

                        Rectangle {
                            id: cellItem
                            width: tableRoot.columnVisibility[tableRoot.columnOrder[index]] ? tableView.width * tableRoot.adjustedColumnWidths[tableRoot.columnOrder[index]] : 0
                            height: parent.height
                            color: rowColor
                            visible: tableRoot.columnVisibility[tableRoot.columnOrder[index]]
                            border.color: tableRoot.cellBorderColor
                            border.width: 1

                            Binding on width {
                                value: tableRoot.columnVisibility[tableRoot.columnOrder[index]] ? tableView.width * tableRoot.adjustedColumnWidths[tableRoot.columnOrder[index]] : 0
                            }

                            Text {
                                anchors {
                                    fill: parent
                                    margins: 10
                                }
                                text: getCellText(tableRoot.columnOrder[index])
                                font.pixelSize: 14
                                color: isSelected ? tableRoot.highlightTextColor : tableRoot.cellTextColor
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            tableRoot.setCurrentRow(index)
                            forceActiveFocus()
                        } else if (mouse.button === Qt.RightButton) {
                            tableRoot.setCurrentRow(index)
                            showContextMenu(index)
                        }
                    }

                    onDoubleClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            tableRoot.setCurrentRow(index)
                        }
                    }

                    onPressAndHold: {
                        tableRoot.setCurrentRow(index)
                        showContextMenu(index)
                    }
                }

                function getCellText(columnIndex) {
                    if (columnIndex < 0 || columnIndex >= tableRoot.columns.length)
                        return ""

                    let columnDef = tableRoot.columns[columnIndex]
                    let role = columnDef.role
                    let value = model[role]

                    if (value === undefined || value === null)
                        return ""

                    switch (columnDef.type) {
                    case "number":
                        return columnDef.format ? columnDef.format(value) : value.toString()
                    case "boolean":
                        return value ? (columnDef.trueText || "Yes") : (columnDef.falseText || "No")
                    case "date":
                        return columnDef.format ? columnDef.format(value) : value.toString()
                    default:
                        return value.toString()
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            cacheBuffer: 1000
            boundsBehavior: Flickable.StopAtBounds
        }
    }

    // ============================================================================
    // MENU : COLUMN VISABILITY
    // ============================================================================
    Menu {
        id: columnVisibilityMenu
        title: "Column Visibility"

        MenuItem {
            text: "Show All Columns"
            onTriggered: showAllColumns()
        }

        MenuItem {
            text: "Hide All Columns"
            onTriggered: hideAllColumns()
        }

        MenuSeparator {}

        Repeater {
            model: tableRoot.columns.length

            MenuItem {
                text: tableRoot.columnTitles[index]
                checkable: true
                checked: tableRoot.columnVisibility[index]
                onTriggered: toggleColumnVisibility(index)
            }
        }

        MenuSeparator {}

        MenuItem {
            text: tableRoot.showHeader ? "Hide Header" : "Show Header"
            onTriggered: toggleHeader()
        }

        MenuItem {
            text: tableRoot.showRowNumbers ? "Hide Numbers" : "Show Number"
            onTriggered: toggleNumbers()
        }
    }

    // ============================================================================
    // MENU: HEADER
    // ============================================================================
    Menu {
        id: headerMenu
        title: headerMenuTitle

        property int columnIndex: -1

        MenuItem {
            text: "Sort Ascending"
            onTriggered: sortByColumn(headerMenu.columnIndex, true)
        }

        MenuItem {
            text: "Sort Descending"
            onTriggered: sortByColumn(headerMenu.columnIndex, false)
        }

        MenuSeparator {}

        MenuItem {
            text: "Clear Sorting"
            onTriggered: clearSorting()
        }

        MenuSeparator {}

        MenuItem {
            text: "Hide Column"
            onTriggered: toggleColumnVisibility(headerMenu.columnIndex)
        }

        MenuItem {
            text: "Show All Columns"
            onTriggered: showAllColumns()
        }

        MenuSeparator {}

        MenuItem {
            text: tableRoot.showHeader ? "Hide Header" : "Show Header"
            onTriggered: toggleHeader()
        }

        onClosed: {
            columnIndex = -1
        }
    }

    // ============================================================================
    // MENU: ROW
    // ============================================================================
    Menu {
        id: contextMenu
        title: contextMenuTitle

        property int rowIndex: -1

        Repeater {
            model: contextMenuActions

            MenuItem {
                text: modelData.text || modelData.id
                enabled: {
                    if (typeof modelData.enabled === 'function') {
                        return modelData.enabled(contextMenu.rowIndex)
                    }
                    return modelData.enabled !== undefined ? modelData.enabled : true
                }
                visible: modelData.visible !== undefined ? modelData.visible : true

                onTriggered: {
                    contextMenuActionTriggered(modelData.id,
                                               contextMenu.rowIndex)

                    // Execute specific actions
                    switch (modelData.id) {
                    case "delete":
                        deleteRow(contextMenu.rowIndex)
                        break
                    case "moveUp":
                        moveRowUp(contextMenu.rowIndex)
                        break
                    case "moveDown":
                        moveRowDown(contextMenu.rowIndex)
                        break
                    case "duplicate":
                        duplicateRow(contextMenu.rowIndex)
                        break
                    }

                    if (modelData.handler) {
                        modelData.handler(contextMenu.rowIndex)
                    }
                }
            }
        }

        onClosed: {
            rowIndex = -1
        }
    }


    function initializeColumnProperties() {
        let order = []
        let widths = []
        let titles = []
        let visibility = []

        for (var i = 0; i < columns.length; i++) {
            order.push(i)
            widths.push(columns[i].width)
            titles.push(columns[i].title)
            visibility.push(true)
        }

        columnOrder = order
        columnWidths = widths
        columnTitles = titles
        columnVisibility = visibility
    }

    function setCurrentRow(rowIndex) {
        if (rowIndex >= 0 && rowIndex < tableView.count) {
            currentRow = rowIndex
            tableView.currentIndex = rowIndex
            tableView.positionViewAtIndex(rowIndex, ListView.Contain)
            rowSelected(rowIndex)
        }
    }

    function deleteCurrentRow() {
        if (currentRow >= 0 && currentRow < tableView.count) {
            deleteRequested(currentRow)
        }
    }


    function deleteRow(rowIndex) {
        if (rowIndex >= 0 && rowIndex < tableView.count) {
            deleteRequested(rowIndex)
        }
    }


    function moveRowUp(rowIndex) {
        if (rowIndex > 0) {
            moveRowRequested(rowIndex, rowIndex - 1)
            setCurrentRow(rowIndex - 1)
        }
    }

    function moveRowDown(rowIndex) {
        if (rowIndex < tableView.count - 1) {
            moveRowRequested(rowIndex, rowIndex + 1)
            setCurrentRow(rowIndex + 1)
        }
    }


    function duplicateRow(rowIndex) {
        if (rowIndex >= 0 && rowIndex < tableView.count) {
            duplicateRowRequested(rowIndex)
        }
    }

    function toggleColumnVisibility(columnIndex) {
        if (columnIndex >= 0 && columnIndex < columnVisibility.length) {
            let newVisibility = columnVisibility.slice()
            newVisibility[columnIndex] = !newVisibility[columnIndex]
            columnVisibility = newVisibility
            columnVisibilityToggled(columnIndex, newVisibility[columnIndex])

            if (!_isInitializing) {
                tableSettings.savedColumnVisibility = arrayToString(columnVisibility.map(v => v ? 1 : 0))
            }

            tableView.forceLayout()
        }
    }

    function showAllColumns() {
        let newVisibility = columnVisibility.map(() => true)
        columnVisibility = newVisibility

        if (!_isInitializing) {
            tableSettings.savedColumnVisibility = arrayToString(
                        newVisibility.map(v => v ? 1 : 0))
        }

        tableView.forceLayout()
    }

    function hideAllColumns() {
        let newVisibility = columnVisibility.map(() => false)
        columnVisibility = newVisibility

        if (!_isInitializing) {
            tableSettings.savedColumnVisibility = arrayToString(
                        newVisibility.map(v => v ? 1 : 0))
        }

        tableView.forceLayout()
    }

    function toggleHeader() {
        showHeader = !showHeader
        if (!_isInitializing) {
            tableSettings.showHeader = showHeader
        }
    }

    function toggleNumbers() {
        showRowNumbers = !showRowNumbers
        if (!_isInitializing) {
            tableSettings.showRowNumbers = showRowNumbers
        }
    }

    function sortByColumn(columnIndex, ascending) {
        sortColumn = columnIndex
        sortAscending = ascending
        columnSorted(columnIndex, ascending)

        if (!_isInitializing) {
            tableSettings.sortColumn = columnIndex
            tableSettings.sortAscending = ascending
        }
    }

    function clearSorting() {
        sortColumn = -1
        if (!_isInitializing) {
            tableSettings.sortColumn = -1
        }
    }

    function stringToArray(str) {
        if (!str || str === "" || str === "[]") return []

        let cleanStr = str.replace(/[\[\]\s]/g, '')
        if (cleanStr === "") return []

        return cleanStr.split(',').map(item => {
            let trimmed = item.trim()
            return Number(trimmed) || trimmed
        })
    }

    function arrayToString(arr) {
        if (!arr || arr.length === 0)
            return ""
        return arr.join(',')
    }

    function moveColumn(fromDisplayIndex, toDisplayIndex) {
        if (fromDisplayIndex === toDisplayIndex)
            return

        let newOrder = tableRoot.columnOrder.slice()
        const movedColumn = newOrder.splice(fromDisplayIndex, 1)[0]
        newOrder.splice(toDisplayIndex, 0, movedColumn)

        tableRoot.columnOrder = newOrder
        columnMoved(fromDisplayIndex, toDisplayIndex)
    }

    function showContextMenu(rowIndex) {
        contextMenu.rowIndex = rowIndex
        contextMenu.popup()
    }

    function showHeaderMenu(columnIndex) {
        headerMenu.columnIndex = columnIndex
        headerMenu.popup()
    }

    function showColumnVisibilityMenu() {
        columnVisibilityMenu.popup()
    }

    Component.onCompleted: {
        console.log("=== Initializing table ===")
        _isInitializing = true

        initializeColumnProperties()

        if (tableSettings.savedColumnOrder
                && tableSettings.savedColumnOrder !== "") {
            let loadedOrder = stringToArray(tableSettings.savedColumnOrder)
            if (loadedOrder.length === columns.length) {
                columnOrder = loadedOrder
            }
        }

        if (tableSettings.savedColumnWidths
                && tableSettings.savedColumnWidths !== "") {
            let loadedWidths = stringToArray(tableSettings.savedColumnWidths)
            if (loadedWidths.length === columns.length) {
                columnWidths = loadedWidths
            }
        }

        if (tableSettings.savedColumnVisibility
                && tableSettings.savedColumnVisibility !== "") {
            let loadedVisibility = stringToArray(
                    tableSettings.savedColumnVisibility)
            if (loadedVisibility.length === columns.length) {
                columnVisibility = loadedVisibility.map(v => v === 1)
            }
        }

        if (tableSettings.showRowNumbers !== undefined)
            showRowNumbers = tableSettings.showRowNumbers

        if (tableSettings.showHeader !== undefined)
            showHeader = tableSettings.showHeader

        if (tableSettings.sortColumn !== undefined)
            sortColumn = tableSettings.sortColumn
        if (tableSettings.sortAscending !== undefined)
            sortAscending = tableSettings.sortAscending

        Qt.callLater(() => {
                         _isInitializing = false
                         tableView.forceLayout()
                     })
    }
}
