// Film Grain — subtle animated noise for organic screen texture
// Very low intensity to avoid distracting from terminal content.

struct Uniforms {
    time: f32,
    resolution: vec2<f32>,
    _padding: f32,
};

@group(0) @binding(0) var input_texture: texture_2d<f32>;
@group(0) @binding(1) var input_sampler: sampler;
@group(0) @binding(2) var<uniform> uniforms: Uniforms;

// Hash function for pseudo-random noise
fn hash(p: vec2<f32>) -> f32 {
    let h = dot(p, vec2<f32>(127.1, 311.7));
    return fract(sin(h) * 43758.5453);
}

@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let color = textureSample(input_texture, input_sampler, uv);

    // Time-varying seed for animation
    let seed = floor(uniforms.time * 12.0);

    // Generate noise at pixel resolution
    let pixel = uv * uniforms.resolution;
    let noise = hash(pixel + seed) * 2.0 - 1.0;

    // Very subtle grain (0.02 intensity)
    let grain_intensity = 0.02;
    let grain = noise * grain_intensity;

    return vec4<f32>(color.rgb + grain, color.a);
}
