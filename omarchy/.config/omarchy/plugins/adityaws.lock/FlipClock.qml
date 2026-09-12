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
  property bool isPaused: false
  property bool isIdle: false
  property bool isBreakOver: false

  readonly property color stateColor: root.isBreakOver ? "#f7768e" : (root.isBreak ? (root.phaseTitle.indexOf("Long") !== -1 ? "#bb9af7" : "#73daca") : (root.isPaused ? "#e0af68" : (root.isIdle ? "#f7768e" : "#7aa2f7")))
  readonly property string displayPhaseTitle: root.isBreakOver ? "BREAK COMPLETE (UNLOCK TO RESUME)" : root.phaseTitle
  readonly property string displayPhaseIcon: root.isBreakOver ? "⏰" : root.phaseIcon

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
    var str = root.isBreakOver ? "00:00" : (timeString || "00:00")
    var parts = str.split(":")
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

  property real colonOpacity: 1.0

  SequentialAnimation {
    id: colonPulseAnim
    running: root.isBreakOver
    loops: Animation.Infinite
    NumberAnimation { target: root; property: "colonOpacity"; to: 0.05; duration: 400; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "colonOpacity"; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
    onStopped: root.colonOpacity = 1.0
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
      color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.15)
      border.color: root.stateColor
      border.width: Math.max(1, Math.round(root.cardWidth * 0.008))

      Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: Math.max(10, Math.round(root.cardWidth * 0.04))

        Text {
          text: root.displayPhaseIcon
          font.family: Style.font.family
          font.pixelSize: Math.max(18, Math.round(root.cardHeight * 0.055))
          color: root.stateColor
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          text: root.displayPhaseTitle.toUpperCase()
          font.family: Style.font.family
          font.pixelSize: Math.max(15, Math.round(root.cardHeight * 0.045))
          font.weight: Font.DemiBold
          font.letterSpacing: 2.5
          color: root.stateColor
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
        textColor: root.stateColor
        isPulsing: root.isBreakOver
      }

      // Minute 2
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.m2
        textColor: root.stateColor
        isPulsing: root.isBreakOver
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
            color: root.stateColor
            opacity: root.isBreakOver ? root.colonOpacity : 1.0
          }
          Rectangle {
            width: Math.max(10, Math.round(root.cardWidth * 0.06))
            height: width
            radius: width / 2
            color: root.stateColor
            opacity: root.isBreakOver ? root.colonOpacity : 1.0
          }
        }
      }

      // Second 1
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.s1
        textColor: root.stateColor
        isPulsing: root.isBreakOver
      }

      // Second 2
      FlipDigit {
        cardWidth: root.cardWidth
        cardHeight: root.cardHeight
        fontSize: root.fontSize
        text: root.parsedDigits.s2
        textColor: root.stateColor
        isPulsing: root.isBreakOver
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
            ? root.stateColor
            : "#45475a"
          border.color: index < (root.completedSessions % root.totalCycleSessions)
            ? root.stateColor
            : "#585b70"
          border.width: 1
        }
      }
    }
  }
}
