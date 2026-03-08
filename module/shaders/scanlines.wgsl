// Scanlines — CRT-style horizontal line overlay
// Subtle darkening of alternating rows for retro aesthetics.

struct Uniforms {
    time: f32,
    resolution: vec2<f32>,
    _padding: f32,
};

@group(0) @binding(0) var input_texture: texture_2d<f32>;
@group(0) @binding(1) var input_sampler: sampler;
@group(0) @binding(2) var<uniform> uniforms: Uniforms;

@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let color = textureSample(input_texture, input_sampler, uv);

    // Pixel y-coordinate
    let y = uv.y * uniforms.resolution.y;

    // Scanline pattern: darken every other pixel row slightly
    let scanline = 0.95 + 0.05 * sin(y * 3.14159);

    // Subtle vignette at edges
    let vignette_x = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
    let vignette_y = smoothstep(0.0, 0.1, uv.y) * smoothstep(1.0, 0.9, uv.y);
    let vignette = mix(0.92, 1.0, vignette_x * vignette_y);

    return vec4<f32>(color.rgb * scanline * vignette, color.a);
}
