// Current weather where the machine is: location from the public IP (ipinfo.io), conditions from Open-Meteo.
// No API keys. On a VPN the location is the VPN exit's.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string city: ""
    property real lat: NaN
    property real lon: NaN
    property bool ready: false
    property int temperature: 0
    property int code: -1
    property bool isDay: true

    readonly property string condition: label(code)
    readonly property string icon: iconFor(code, isDay) // sun | moon | cloud | rain | snow | storm | fog

    function label(c) {
        if (c === 0) return "CLEAR";
        if (c === 1 || c === 2) return "PARTLY CLOUDY";
        if (c === 3) return "OVERCAST";
        if (c === 45 || c === 48) return "FOG";
        if (c >= 51 && c <= 57) return "DRIZZLE";
        if (c >= 61 && c <= 67) return "RAIN";
        if (c >= 71 && c <= 77) return "SNOW";
        if (c >= 80 && c <= 82) return "SHOWERS";
        if (c === 85 || c === 86) return "SNOW";
        if (c >= 95) return "STORM";
        return "";
    }

    function iconFor(c, day) {
        if (c === 0 || c === 1) return day ? "sun" : "moon";
        if (c === 2 || c === 3) return "cloud";
        if (c === 45 || c === 48) return "fog";
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
        if (c >= 95) return "storm";
        return day ? "sun" : "moon";
    }

    function getJson(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    done(JSON.parse(xhr.responseText));
                } catch (e) {
                    console.warn("weather: bad JSON from", url);
                }
            } else {
                console.warn("weather: HTTP", xhr.status, url);
                retry.restart(); // services blip (503s happen): try again in a minute, not in 15
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function locate() {
        getJson("https://ipinfo.io/json", j => {
            const [la, lo] = (j.loc || "").split(",").map(Number);
            if (isNaN(la) || isNaN(lo))
                return;
            root.city = (j.city || "").toUpperCase();
            root.lat = la;
            root.lon = lo;
            refresh();
        });
    }

    function refresh() {
        if (isNaN(lat))
            return;
        getJson("https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
            + "&current=temperature_2m,weather_code,is_day", j => {
            root.temperature = Math.round(j.current.temperature_2m);
            root.code = j.current.weather_code;
            root.isDay = j.current.is_day === 1;
            root.ready = true;
        });
    }

    Component.onCompleted: locate()

    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: isNaN(root.lat) ? root.locate() : root.refresh()
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.locate()
    }
}
