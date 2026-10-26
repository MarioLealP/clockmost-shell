// A halftone field with no picture (Mario 2026-10-26, the empty stretch right of the orange line): dots on the
// ground's grid, big and orange at the left (by the line) shrinking to nothing at the right, a slow wave swelling
// them, and a pulse that rolls through left to right when the hero swaps its art.
// Compile: /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o field.frag.qsb field.frag
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;   // seconds
    float pulse;  // 0..1 the swap's front crossing, < 0 = none
    float cell;   // dot pitch, px (dots centred on multiples of it)
    vec2 size;
    vec4 hot;     // the big dots
    vec4 cold;    // the small ones
};

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 id = floor((px + cell * 0.5) / cell);
    vec2 centre = id * cell;
    vec2 uv = centre / size;

    // the gradient: full at the left, nothing past ~85%, a little fuller at the bottom
    float g = clamp(1.0 - uv.x / 0.85, 0.0, 1.0);
    g = g * g * (0.75 + 0.25 * uv.y);
    // the slow wave, travelling right
    float wave = 0.78 + 0.22 * sin(time * 0.7 - uv.x * 9.0 + uv.y * 3.0);
    // the swap pulse: a band of bigger dots moving across
    float front = pulse < 0.0 ? 0.0 : exp(-pow((uv.x - (pulse * 1.3 - 0.15)) * 7.0, 2.0));

    float r = cell * 0.5 * clamp(g * wave + front * 0.6 * (1.0 - g * 0.5), 0.0, 1.0);
    float inside = smoothstep(r + 0.8, r - 0.8, length(px - centre));
    vec4 c = mix(cold, hot, clamp(g * 1.4, 0.0, 1.0));
    fragColor = c * inside * (r > 0.4 ? 1.0 : 0.0) * qt_Opacity;
}
