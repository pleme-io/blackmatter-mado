// Cursor Glow — soft radial glow around the cursor position
// Uses time-based pulsing for a breathing effect.

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

    // Nord frost cyan glow color (#88C0D0)
    let glow_color = vec3<f32>(0.533, 0.753, 0.816);

    // Pulsing intensity (subtle breathing)
    let pulse = 0.3 + 0.1 * sin(uniforms.time * 2.0);

    // Cursor assumed at center-ish — in practice this would use a cursor uniform
    // For now, detect bright pixels that could be cursor
    let lum = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    let is_cursor_region = step(0.8, lum);

    // Add soft glow to cursor-like bright regions
    let glow = glow_color * pulse * is_cursor_region * 0.15;

    return vec4<f32>(color.rgb + glow, color.a);
}
