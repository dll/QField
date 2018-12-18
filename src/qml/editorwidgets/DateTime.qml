import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls 1.4 as Controls
import QtQuick.Layouts 1.1
import "../js/style.js" as Style

/*
  Config:
  * field_format
  * display_format
  * calendar_popup
  * allow_null

  If the calendar_popup is enabled, no direct editing is possible in the TextField.
  If not, it will try to match the display_format with the best possible InputMask.
  A Date/Time object (Date in QML) is used even with text field as source (not DateTime)
  to allow a full flexibility of field and display formats.

 */

Item {
  signal valueChanged(var value, bool isNull)

  height: childrenRect.height
  anchors { right: parent.right; left: parent.left }

  ColumnLayout {
    id: main
    property var currentValue: value

    anchors { right: parent.right; left: parent.left }

    Item {
      anchors { right: parent.right; left: parent.left }
      Layout.minimumHeight: 48 * dp

      Rectangle {
        anchors.fill: parent
        id: backgroundRect
        border.color: comboBox.pressed ? "#17a81a" : "#21be2b"
        border.width: comboBox.visualFocus ? 2 : 1
        color: "#dddddd"
        radius: 2
      }

      TextField {
        id: label

        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        font.pointSize: 16

        inputMethodHints: Qt.ImhDigitsOnly

        // this is a bit difficult to auto generate input mask out of date/time format using regex
        // mainly because number of caracters is variable (e.g. "d": the day as number without a leading zero)
        // not saying impossible, but keep it for next regex challenge or at least not the day before vacation
        inputMask:      if (config['display_format'] === "yyyy-MM-dd" ) { "9999-09-09;_" }
                   else if (config['display_format'] === "yyyy.MM.dd" ) { "9999.09.09;_" }
                   else if (config['display_format'] === "yyyy-MM-dd HH:mm:ss" ) { "9999-09-09 09:09:00;_" }
                   else if (config['display_format'] === "HH:mm:ss" ) { "09:09:00;_" }
                   else if (config['display_format'] === "HH:mm" ) { "09:09;_" }
                   else { "" }

        text: if ( value === undefined )
              {
                qsTr('(no date)')
              }
              else
              {
                if ( value instanceof Date )
                {
                  Qt.formatDateTime(value, config['display_format'])
                }
                else
                {
                  var date = Date.fromLocaleString(Qt.locale(), value, config['field_format'])
                  Qt.formatDateTime(date, config['display_format'])
                }
              }

        color: value === undefined ? 'gray' : 'black'

        MouseArea {
          enabled: config['calendar_popup']
          anchors.fill: parent
          onClicked: {
            popup.open()
          }
        }

        onActiveFocusChanged: {
            if (activeFocus) {
              var mytext = label.text
              var cur = label.cursorPosition
              while ( cur > 0 )
              {
                if (!mytext.charAt(cur-1).match("[0-9]") )
                  break
                cur--
              }
              label.cursorPosition = cur
            }
        }

        Image {
          source: Style.getThemeIcon("ic_clear_black_18dp")
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: ( value !== undefined ) && config['allow_null']

          MouseArea {
            anchors.fill: parent
            onClicked: {
              main.currentValue = undefined
            }
          }
        }
      }
    }

    Popup {
      id: popup
      modal: true
      focus: true
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
      parent: ApplicationWindow.overlay

      ColumnLayout {
        Controls.Calendar {
          id: calendar
          selectedDate: currentValue
          weekNumbersVisible: true
          focus: false

          onSelectedDateChanged: {
            if ( main.currentValue instanceof Date )
            {
              main.currentValue = selectedDate
            }
            else
            {
              main.currentValue = Qt.formatDateTime(selectedDate, config['field_format'])
            }
          }
        }

        RowLayout {
          Button {
            text: qsTr( "Ok" )
            Layout.fillWidth: true

            onClicked: popup.close()
          }
        }
      }
    }

    onCurrentValueChanged: {
      valueChanged(currentValue, main.currentValue === undefined)
    }
  }
}
