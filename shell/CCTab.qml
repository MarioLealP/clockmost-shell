// A control-center tab page: content stacks from the top, the footer is pinned to the bottom, and the page is
// at least as tall as the tab rail (so short tabs don't leave the footer floating mid-panel).
import QtQuick

Item {
    id: root

    property real minHeight: 0
    property string code: ""
    property string codePrefix: "CLOCKMOST · "
    default property alias content: body.data
    property alias actions: footer.actions // buttons on the footer's right

    width: 432
    implicitHeight: Math.max(minHeight, body.implicitHeight + footer.implicitHeight)

    Column {
        id: body
        width: parent.width
    }
    CCFooter {
        id: footer
        anchors.bottom: parent.bottom
        code: root.code
        prefix: root.codePrefix
    }
}
