// v2 bar plate: a bone slab the bar's groups sit on (the mock's segmented plates), dark ink on it.
import QtQuick

Rectangle {
    default property alias content: inner.data
    property int pad: 14

    implicitWidth: inner.childrenRect.width + 2 * pad
    implicitHeight: 52
    color: GroundTheme.ink

    Item {
        id: inner
        x: parent.pad
        width: childrenRect.width
        height: parent.height
    }
}
