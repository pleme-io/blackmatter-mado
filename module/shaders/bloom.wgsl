// Bloom — subtle glow on bright terminal text
// Samples neighboring pixels and adds weighted glow to bright regions.

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
    let texel = vec2<f32>(1.0 / uniforms.resolution.x, 1.0 / uniforms.resolution.y);
    let color = textureSample(input_texture, input_sampler, uv);

    // Luminance of the center pixel
    let lum = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));

    // Only bloom bright pixels (threshold at 0.6)
    let bloom_threshold = 0.6;
    if lum < bloom_threshold {
        return color;
    }

    // 5-tap Gaussian blur for glow
    let intensity = 0.15;
    let radius = 2.0;
    var glow = vec3<f32>(0.0);
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(-radius, 0.0) * texel).rgb * 0.1;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(radius, 0.0) * texel).rgb * 0.1;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(0.0, -radius) * texel).rgb * 0.1;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(0.0, radius) * texel).rgb * 0.1;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(-radius, -radius) * texel).rgb * 0.05;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(radius, -radius) * texel).rgb * 0.05;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(-radius, radius) * texel).rgb * 0.05;
    glow += textureSample(input_texture, input_sampler, uv + vec2<f32>(radius, radius) * texel).rgb * 0.05;

    let bloom_factor = (lum - bloom_threshold) / (1.0 - bloom_threshold);
    return vec4<f32>(color.rgb + glow * intensity * bloom_factor, color.a);
}
