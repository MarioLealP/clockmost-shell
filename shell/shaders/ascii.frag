// The hero's picture as ASCII art (Mario 2026-10-26, the stretch right of the orange line): one character per 12x18
// cell from a brightness ramp " .:-=+*#%@" (5x7 pixel glyphs drawn 2x), bone getting brighter with the picture,
// the densest one orange, edges fading out. t 0 -> 1 swaps picture "from" to "to": each cell scrambles through random
// glyphs and settles on the new one at its own moment.
// Compile: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o ascii.frag.qsb ascii.frag
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float time;
    vec2 size;
    vec2 fitFrom;
    vec2 fitTo;
    vec4 ink;
    vec4 hot;
};
layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;

// 10 glyphs x 7 rows, 5 bits per row (bit 4 = leftmost column)
const int GLYPHS[70] = int[70](
    0, 0, 0, 0, 0, 0, 0,                         // ' '
    0, 0, 0, 0, 0, 12, 12,                       // '.'
    0, 12, 12, 0, 12, 12, 0,                     // ':'
    0, 0, 0, 14, 0, 0, 0,                        // '-'
    0, 0, 31, 0, 31, 0, 0,                       // '='
    0, 4, 4, 31, 4, 4, 0,                        // '+'
    0, 21, 14, 31, 14, 21, 0,                    // '*'
    10, 10, 31, 10, 31, 10, 10,                  // '#'
    25, 26, 2, 4, 8, 11, 19,                     // '%'
    14, 17, 23, 21, 23, 16, 14                   // '@'
);

vec2 fit(vec2 uv, vec2 s) { return vec2((uv.x - 0.5) * s.x + 0.5, uv.y * s.y); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    const vec2 cellSize = vec2(12.0, 18.0);
    vec2 px = qt_TexCoord0 * size;
    vec2 id = floor(px / cellSize);
    vec2 local = px - id * cellSize;
    vec2 uv = (id + 0.5) * cellSize / size;

    float lf = luma(texture(from, fit(uv, fitFrom)).rgb);
    float lt = luma(texture(to, fit(uv, fitTo)).rgb);

    // this cell's swap: scrambling between start and settle, then the new picture
    float n = hash(id);
    float start = n * 0.35, settle = 0.35 + n * 0.6;
    float l = t < settle ? lf : lt;
    int g = int(clamp(l, 0.0, 0.999) * 10.0);
    if (t > start && t < settle)
        g = 1 + int(hash(id + floor(time * 14.0)) * 7.99); // bone glyphs only: no orange noise

    // the glyph's pixel (2x scale, 1 px left / 2 px top margin)
    ivec2 gp = ivec2(floor((local - vec2(1.0, 2.0)) / 2.0));
    float on = 0.0;
    if (gp.x >= 0 && gp.x < 5 && gp.y >= 0 && gp.y < 7)
        on = float((GLYPHS[g * 7 + gp.y] >> (4 - gp.x)) & 1);

    vec2 e = min(uv, 1.0 - uv);
    float edge = smoothstep(0.0, 0.12, e.x) * smoothstep(0.0, 0.18, e.y);
    vec4 c = g == 9 ? hot : ink * (0.35 + 0.65 * l);
    fragColor = c * on * edge * qt_Opacity;
}
