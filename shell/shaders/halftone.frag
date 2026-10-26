// The hero's art swap (Mario 2026-10-26): picture A dissolves into a halftone (one dot per cell, the cell's colour,
// bigger where it's brighter), the dots change size and colour into picture B's halftone, and B forms back. t runs
// 0 -> 1 for A -> B (and 1 -> 0 goes back the same way). Each cell gets a small random delay, so it ripples.
// Compile: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o halftone.frag.qsb halftone.frag
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;      // 0 = picture A .. 1 = picture B
    float cell;   // dot pitch, px
    vec2 size;    // the item, px
    vec2 fitA;    // cover-fit scale per picture (x centred, y from the top)
    vec2 fitB;
    vec4 bg;      // between the dots
};
layout(binding = 1) uniform sampler2D srcA;
layout(binding = 2) uniform sampler2D srcB;

vec2 fit(vec2 uv, vec2 s) { return vec2((uv.x - 0.5) * s.x + 0.5, uv.y * s.y); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 id = floor(px / cell);
    vec2 centre = (id + 0.5) * cell;
    float n = hash(id);

    vec4 pixA = texture(srcA, fit(qt_TexCoord0, fitA));
    vec4 pixB = texture(srcB, fit(qt_TexCoord0, fitB));
    vec4 dotA = texture(srcA, fit(centre / size, fitA));
    vec4 dotB = texture(srcB, fit(centre / size, fitB));

    // three phases with a per-cell delay: A -> dots(A), dots(A) -> dots(B), dots(B) -> B
    float k1 = smoothstep(0.00 + n * 0.12, 0.28 + n * 0.12, t);
    float k2 = smoothstep(0.36 + n * 0.16, 0.56 + n * 0.16, t);
    float k3 = smoothstep(0.72 + n * 0.12, 0.88 + n * 0.12, t);

    float full = cell * 0.75; // covers the whole cell: the plain picture
    float rA = cell * 0.5 * mix(0.12, 1.0, luma(dotA.rgb));
    float rB = cell * 0.5 * mix(0.12, 1.0, luma(dotB.rgb));
    float r = mix(mix(mix(full, rA, k1), rB, k2), full, k3);
    vec4 c = mix(mix(mix(pixA, dotA, k1), dotB, k2), pixB, k3);

    float inside = smoothstep(r + 0.8, r - 0.8, length(px - centre));
    fragColor = mix(bg, c, inside) * qt_Opacity;
}
