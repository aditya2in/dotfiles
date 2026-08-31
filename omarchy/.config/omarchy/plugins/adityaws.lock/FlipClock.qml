import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  property string timeString: "00:00"
  property string phaseTitle: "Focus Session"
  property string phaseIcon: "󰔛"
  property int completedSessions: 0
  property int totalCycleSessions: 4
  property bool isBreak: false
  property bool isRunning: false

  property real availableWidth: 1000
  property real availableHeight: 800

  readonly property bool isPortrait: availableHeight > availableWidth

  // Responsive Card Sizing Calculations
  readonly property real maxCardWidthByHeight: (availableHeight * 0.68) / 1.42
  readonly property real maxCardWidthByWidth: isPortrait
    ? (availableWidth * 0.94 - 70) / 4
    : (availableWidth * 0.82 - 160) / 4

  readonly property real cardWidth: Math.max(160, Math.min(maxCardWidthByHeight, maxCardWidthByWidth))
  readonly property real cardHeight: Math.round(cardWidth * 1.42)
  readonly property real fontSize: Math.floor(cardHeight * 0.64)

  implicitWidth: contentColumn.implicitWidth
  implicitHeight: contentColumn.implicitHeight

  // Split timeString into M1, M2, S1, S2
  readonly property var parsedDigits: {
    var parts = (timeString || "00:00").split(":")
    var mins = parts[0] || "00"
    var secs = parts[1] || "00"
    if (mins.length === 1) mins = "0" + mins
    if (secs.length === 1) secs = "0" + secs
    return {
      m1: mins.charAt(0),
      m2: mins.charAt(1),
      s1: secs.charAt(0),
      s2: secs.charAt(1)
    }
  }

  Column {
    id: contentColumn
    anchors.centerIn: parent
    spacing: Math.max(18, Math.round(root.cardHeight * 0.05))

    // --- Phase Badge ---
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      height: Math.max(40, Math.round(root.cardHeight * 0.09))
      width: badgeRow.implicitWidth + Math.max(36, Math.round(root.cardWidth * 0.18))
      radius: height / 2
      color: root.isBreak ? "#a6e3a125" : "#89b4fa25"
      border.color: root.isBreak ? "#a6e3a1" : "#89b4fa"
      border.width: Math.max(1, Math.round(root.cardWidth * 0.008))

      Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: Math.max(10, Math.round(root.cardWidth * 0.04))

        Text {
          text: root.phaseIcon
          font.family: Style.font.family
          font.pixelSize: Math.max(18, Math.round(root.cardHeight * 0.055))
          color: root.isBreak ? "#a6e3a1" : "#89b4fa"
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          text: root.phaseTitle.toUpperCase()
          font.family: Style.font.family
          font.pixelSize: Math.max(15, Math.round(root.cardHeight * 0.045))
          font.weight: Font.DemiBold
          font.letterSpacing: 2.5
          color: root.isBreak ? "#a6e3a1" : "#89b4fa"
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    // --- Colossal Flip Clock Cards Row ---
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Math.max(8, Math.round(root.cardWidth * 0.035))

      // Minute 1
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.m1
        textColor: root.isBreak ? "#a6e3a1" : "#cdd6f4"
      }

      // Minute 2
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.m2
        textColor: root.isBreak ? "#a6e3a1" : "#cdd6f4"
      }

      // Colon Divider
      Item {
        width: Math.max(24, Math.round(root.cardWidth * 0.20))
        height: root.cardHeight
        Column {
          anchors.centerIn: parent
          spacing: Math.max(20, Math.round(root.cardHeight * 0.16))
          Rectangle {
            width: Math.max(10, Math.round(root.cardWidth * 0.06))
            height: width
            radius: width / 2
            color: root.isBreak ? "#a6e3a1" : (root.isRunning ? "#89b4fa" : "#6c7086")
          }
          Rectangle {
            width: Math.max(10, Math.round(root.cardWidth * 0.06))
            height: width
            radius: width / 2
            color: root.isBreak ? "#a6e3a1" : (root.isRunning ? "#89b4fa" : "#6c7086")
          }
        }
      }

      // Second 1
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.s1
        textColor: root.isBreak ? "#a6e3a1" : "#cdd6f4"
      }

      // Second 2
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.s2
        textColor: root.isBreak ? "#a6e3a1" : "#cdd6f4"
      }
    }

    // --- Session Cycle Dots (● ● ○ ○) ---
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Math.max(14, Math.round(root.cardWidth * 0.06))
      visible: root.totalCycleSessions > 0

      Repeater {
        model: root.totalCycleSessions
        Rectangle {
          width: Math.max(12, Math.round(root.cardWidth * 0.045))
          height: width
          radius: width / 2
          color: index < (root.completedSessions % root.totalCycleSessions)
            ? (root.isBreak ? "#a6e3a1" : "#89b4fa")
            : "#45475a"
          border.color: index < (root.completedSessions % root.totalCycleSessions)
            ? (root.isBreak ? "#a6e3a1" : "#89b4fa")
            : "#585b70"
          border.width: 1
        }
      }
    }
  }
}
