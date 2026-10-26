// A silhouette picture as ASCII art (Mario 2026-10-26: the FFXIV meteor, right of the orange line): one character per
// 12x18 cell, 5x7 pixel glyphs drawn 2x. Dark parts of the picture are the shape, filled with a soft diagonal
// shading of bone glyphs ': - = + * #' (no orange edge - Mario), the rest empty. presence 1 -> 0 dissolves it (an HA
// section opening): each cell flickers through random glyphs around its own threshold. Materializing replays the
// start-up scramble from nothing (fromEmpty). t 0 -> 1 = a scramble (on every hero
// art swap): each cell runs random glyphs - some empty cells too, a burst around the shape - and settles back.
// Compile: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o ascii.frag.qsb ascii.frag
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float time;
    float presence;
    float fromEmpty; // 1 = the scramble builds up from nothing (start-up, materializing)
    vec2 size;
    vec4 ink;
};
layout(binding = 1) uniform sampler2D src;

// 10 glyphs x 7 rows, 5 bits per row (bit 4 = leftmost column): ' ' . : - = + * # % @
const int GLYPHS[70] = int[70](
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 12, 12,
    0, 12, 12, 0, 12, 12, 0,
    0, 0, 0, 14, 0, 0, 0,
    0, 0, 31, 0, 31, 0, 0,
    0, 4, 4, 31, 4, 4, 0,
    0, 21, 14, 31, 14, 21, 0,
    10, 10, 31, 10, 31, 10, 10,
    25, 26, 2, 4, 8, 11, 19,
    14, 17, 23, 21, 23, 16, 14
);
const vec2 CELL = vec2(12.0, 18.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
// is this cell part of the shape (dark in the picture)?
bool shape(vec2 id) {
    vec2 uv = (id + 0.5) * CELL / size;
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0)
        return false;
    vec4 c = texture(src, uv);
    return c.a > 0.5 && dot(c.rgb, vec3(0.299, 0.587, 0.114)) < 0.5;
}

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 id = floor(px / CELL);
    vec2 local = px - id * CELL;
    vec2 uv = (id + 0.5) * CELL / size;

    bool in0 = shape(id);
    int g = 0;
    if (in0)
        g = 2 + int(clamp(0.5 + 0.45 * sin(uv.x * 5.0 + uv.y * 3.5), 0.0, 0.999) * 6.0); // : - = + * #

    // the scramble: cells in or around the shape (and a quarter of the empty ones) run random glyphs, then settle
    float n = hash(id);
    float start = n * 0.3, settle = 0.35 + n * 0.6;
    if (t > start && t < settle && (in0 || hash(id + 7.0) < 0.25))
        g = 1 + int(hash(id + floor(time * 14.0)) * 7.99);
    else if (fromEmpty > 0.5 && t <= start)
        g = 0;

    // dissolve / materialize: gone below this cell's threshold, flickering just above it
    float thr = hash(id + 3.0);
    if (presence < 1.0) {
        if (presence < thr * 0.85)
            g = 0;
        else if (presence < thr * 0.85 + 0.15 && in0)
            g = 1 + int(hash(id + floor(time * 14.0)) * 7.99);
    }

    ivec2 gp = ivec2(floor((local - vec2(1.0, 2.0)) / 2.0));
    float on = 0.0;
    if (gp.x >= 0 && gp.x < 5 && gp.y >= 0 && gp.y < 7)
        on = float((GLYPHS[g * 7 + gp.y] >> (4 - gp.x)) & 1);

    fragColor = ink * 0.85 * on * qt_Opacity;
}
