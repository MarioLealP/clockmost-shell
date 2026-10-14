// Reads the playing cover's pixels for Media.pick(). Lives on the bar (always on screen - a Canvas only paints in a
// window); sits under the chip's art, which covers it once the cover loads.
import QtQuick

Canvas {
    id: root

    readonly property string url: Media.player?.trackArtUrl ?? ""
    property string loaded: ""

    width: 24
    height: 24

    onUrlChanged: {
        if (loaded)
            unloadImage(loaded);
        loaded = url;
        if (url)
            loadImage(url);
        else
            Media.reset();
    }
    onImageLoaded: requestPaint()
    onPaint: {
        if (!url || !isImageLoaded(url))
            return;
        const ctx = getContext("2d");
        ctx.reset();
        ctx.drawImage(url, 0, 0, width, height);
        Media.pick(ctx.getImageData(0, 0, width, height).data);
    }
}
