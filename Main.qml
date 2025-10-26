import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CustomModels 1.0


ApplicationWindow {
    width: 1200
    height: 800
    visible: true

    ItemModel {
        id: itemModel
    }

    DataGrid {
        id: dataGrid
        anchors.fill: parent
        model: itemModel
        //Table id is used to save the table settingd
        tableId: "employeeTable"

        //Define the columns
        // We can define de Width of the columns
        // The role
        columns: [
            { width: 0.20, title: "Name", role: "name", type: "string" },
            { width: 0.15, title: "Role", role: "role", type: "string" },
            { width: 0.15, title: "Department", role: "department", type: "string" },
            { width: 0.12, title: "Salary", role: "salary", type: "number", format: function(v) { return "$" + v.toFixed(2) } },
            { width: 0.10, title: "Active", role: "isActive", type: "boolean", trueText: "✓", falseText: "✗" },
            { width: 0.12, title: "Hire Date", role: "hireDate", type: "date", format: function(v) { return new Date(v).toLocaleDateString() } },
            { width: 0.08, title: "Status", role: "status", type: "string" },
            { width: 0.08, title: "Remote", role: "remoteWork", type: "boolean", trueText: "🏠", falseText: "🏢" },
            { width: 0.10, title: "Contract", role: "contractType", type: "string" }
        ]

        contextMenuActions: [
              { id: "edit", text: "Edit Item", enabled: true },
              { id: "delete", text: "Delete Item", enabled: true },
              {
                  id: "moveUp",
                  text: "Move Up",
                  enabled: function(rowIndex) {
                      return rowIndex > 0
                  }
              },
              {
                  id: "moveDown",
                  text: "Move Down",
                  enabled: function(rowIndex) {
                      return dataGrid.model ? rowIndex < dataGrid.model.rowCount() - 1 : false
                  }
              },
              { id: "duplicate", text: "Duplicate", enabled: true }
          ]

        customButtons: [
            { id: "button1", icon: "1", color: "#4CAF50", enabled: true, handler: function() { console.log("button 1 clicked") } },
            { id: "button2", icon: "2", color: currentRow >= 0 ? "#f44336" : "#cccccc", enabled: currentRow >= 0, handler: function() { button2Clicked() } },
        ]

        onDeleteRequested: (rowIndex) => {
            itemModel.removeItem(rowIndex)
        }

        onAddRowRequested: {
            itemModel.addItem(
                "New Employee",
                "Developer",
                "Engineering",
                50000,
                true,
                new Date(),
                "active",
                false,
                "Full-time"
            )
        }

        onMoveRowRequested: (fromIndex, toIndex) => {
            itemModel.moveItem(fromIndex, toIndex)
        }

        onContextMenuActionTriggered: (actionId, rowIndex) => {

        }

        function button2Clicked(){
            console.log("Button2 Clicked")
        }

    }
}
