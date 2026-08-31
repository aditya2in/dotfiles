import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  property string text: "0"
  property string prevText: "0"
  property real cardWidth: 160
  property real cardHeight: 230
  property real cardRadius: Math.max(8, cardWidth * 0.08)
  property color cardBackground: "#181825"
  property color cardBorderColor: "#313244"
  property color textColor: "#cdd6f4"
  property real fontSize: Math.floor(cardHeight * 0.62)
  property int animationDuration: 300

  width: cardWidth
  height: cardHeight

  onTextChanged: {
    if (text !== prevText) {
      flipTopAnimation.restart()
    }
  }

  // Background card base with subtle drop shadow border
  Rectangle {
    anchors.fill: parent
    radius: root.cardRadius
    color: root.cardBackground
    border.color: root.cardBorderColor
    border.width: Math.max(1, Math.round(root.cardWidth * 0.01))
  }

  // --- Static Top Half (Shows New Text) ---
  Item {
    id: staticTop
    width: root.cardWidth
    height: root.cardHeight / 2
    anchors.top: parent.top
    clip: true

    Rectangle {
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cardRadius
      color: root.cardBackground
      border.color: root.cardBorderColor
      border.width: Math.max(1, Math.round(root.cardWidth * 0.01))

      Text {
        anchors.centerIn: parent
        text: root.text
        font.family: Style.font.family
        font.pixelSize: root.fontSize
        font.weight: Font.Bold
        color: root.textColor
      }
    }
  }

  // --- Static Bottom Half (Shows Old Text during flip, then New Text) ---
  Item {
    id: staticBottom
    width: root.cardWidth
    height: root.cardHeight / 2
    anchors.bottom: parent.bottom
    clip: true

    Rectangle {
      y: -root.cardHeight / 2
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cardRadius
      color: root.cardBackground
      border.color: root.cardBorderColor
      border.width: Math.max(1, Math.round(root.cardWidth * 0.01))

      Text {
        anchors.centerIn: parent
        text: flippingBottom.isFlipping ? root.prevText : root.text
        font.family: Style.font.family
        font.pixelSize: root.fontSize
        font.weight: Font.Bold
        color: root.textColor
      }
    }
  }

  // --- Flipping Top Flap (Old Text rotates 0 -> -90 deg) ---
  Item {
    id: flippingTop
    width: root.cardWidth
    height: root.cardHeight / 2
    anchors.top: parent.top
    clip: true
    visible: flipTopAnimation.running
    transformOrigin: Item.Bottom

    transform: Rotation {
      id: topRotation
      origin.x: root.cardWidth / 2
      origin.y: root.cardHeight / 2
      axis { x: 1; y: 0; z: 0 }
      angle: 0
    }

    Rectangle {
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cardRadius
      color: root.cardBackground
      border.color: root.cardBorderColor
      border.width: Math.max(1, Math.round(root.cardWidth * 0.01))

      Text {
        anchors.centerIn: parent
        text: root.prevText
        font.family: Style.font.family
        font.pixelSize: root.fontSize
        font.weight: Font.Bold
        color: root.textColor
      }
    }
  }

  // --- Flipping Bottom Flap (New Text rotates 90 -> 0 deg) ---
  Item {
    id: flippingBottom
    property bool isFlipping: flipBottomAnimation.running
    width: root.cardWidth
    height: root.cardHeight / 2
    anchors.bottom: parent.bottom
    clip: true
    visible: flipBottomAnimation.running
    transformOrigin: Item.Top

    transform: Rotation {
      id: bottomRotation
      origin.x: root.cardWidth / 2
      origin.y: 0
      axis { x: 1; y: 0; z: 0 }
      angle: 90
    }

    Rectangle {
      y: -root.cardHeight / 2
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cardRadius
      color: root.cardBackground
      border.color: root.cardBorderColor
      border.width: Math.max(1, Math.round(root.cardWidth * 0.01))

      Text {
        anchors.centerIn: parent
        text: root.text
        font.family: Style.font.family
        font.pixelSize: root.fontSize
        font.weight: Font.Bold
        color: root.textColor
      }
    }
  }

  // Middle horizontal seam / hinge divider
  Rectangle {
    anchors.centerIn: parent
    width: parent.width
    height: Math.max(2, Math.round(root.cardHeight * 0.01))
    color: "#11111b"
    z: 10
  }

  // Top animation: 0 -> -90 deg
  NumberAnimation {
    id: flipTopAnimation
    target: topRotation
    property: "angle"
    from: 0
    to: -90
    duration: root.animationDuration / 2
    easing.type: Easing.InQuad
    onFinished: {
      flipBottomAnimation.restart()
    }
  }

  // Bottom animation: 90 -> 0 deg
  NumberAnimation {
    id: flipBottomAnimation
    target: bottomRotation
    property: "angle"
    from: 90
    to: 0
    duration: root.animationDuration / 2
    easing.type: Easing.OutQuad
    onFinished: {
      root.prevText = root.text
    }
  }
}
