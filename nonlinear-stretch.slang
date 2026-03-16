#version 450

/*
    Non-Linear Stretch Shader ~ v1.0.3
    Author: sevdestruct

    Description:
    - Applies a nonlinear horizontal stretch to video/emulated content.
    - Designed to adapt 4:3 / 8:7 / 10:9 etc. to widescreen without harsh uniform distortion.
    - Uses a blended sine/quintic warp curve, configurable with intensity and profile.
    - Overscan crop removes black pillars or letterboxes added by some cores/games.
    - Debug grid subdivides the *visible* warped region (post-warp, post-overscan) into NxM cells with ~1px yellow lines.

    Parameters:
    - "Nonlinear Stretch Intensity": Overall intensity (0 = linear, 1 = curved).
    - "Curve Profile": Blend between two curve shapes (low = gradual, high = protects center, but dramatically stretches edges).
    - "Overscan X": Horizontal crop (pixels).
    - "Overscan Y": Vertical crop (pixels).
    - "Debug Grid Overlay": Toggle grid on/off.
    - "Grid Subdivisions X": Number of columns (e.g., 17).
    - "Grid Subdivisions Y": Number of rows (e.g., 9).
*/

layout(push_constant) uniform Push
{
    vec4 SourceSize;     // (w, h, 1/w, 1/h)
    vec4 OriginalSize;
    vec4 OutputSize;     // (w, h, 1/w, 1/h)
    uint FrameCount;

    float stretch_strength;
    float curve_profile;
    float overscan_x;    // horizontal crop in pixels
    float overscan_y;    // vertical crop in pixels

    // Debug overlay
    float debug_grid;    // 0 = off, 1 = on
    float grid_div_x;    // columns (e.g., 16)
    float grid_div_y;    // rows    (e.g., 8)
} params;

#pragma parameter stretch_strength "Nonlinear Stretch Intensity" 0.40 0.0 1.0 0.05
#pragma parameter curve_profile    "Curve Profile"               0.60 0.0 1.0 0.05
#pragma parameter overscan_x       "Overscan X (pixels)"         1.0  0.0 32.0 1.0
#pragma parameter overscan_y       "Overscan Y (pixels)"         0.0  0.0 32.0 1.0
#pragma parameter debug_grid       "Debug Grid Overlay"          0.0  0.0 1.0 1.0
#pragma parameter grid_div_x       "Grid Subdivisions X"         15.0  0.0 30.0 15.0
#pragma parameter grid_div_y       "Grid Subdivisions Y"         0.0   0.0 18.0 9.0

// --- Aliases ---
#define Strength     params.stretch_strength
#define Profile      params.curve_profile
#define OverscanX    params.overscan_x
#define OverscanY    params.overscan_y
#define InvW         params.SourceSize.z
#define InvH         params.SourceSize.w
#define DebugGrid    params.debug_grid
#define Gx           params.grid_div_x
#define Gy           params.grid_div_y

layout(std140, set = 0, binding = 0) uniform UBO { mat4 MVP; } global;

// --- Vertex ---
#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

// --- Fragment ---
#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D Source;

const float PI = 3.14159265358979323846;
const vec3  YELLOW = vec3(1.0, 1.0, 0.0); // bright yellow

// Blended curve: sine vs. quintic, mixed by Profile
float hybrid_curve(float x, float profile)
{
    float sin_shape = sin(0.5 * PI * x);

    float x2 = x * x;
    float x3 = x2 * x;
    float x5 = x3 * x2;
    float quintic_shape = 0.5 * x5 - 1.5 * x3 + 2.0 * x;

    return mix(sin_shape, quintic_shape, profile);
}

// Anti-aliased line mask around integer boundaries of t*N (t in [0,1])
float grid_line_mask(float t, float N)
{
    // Scale coordinate by number of cells
    float u = t * N;

    // Distance to nearest integer boundary in u-space
    float frac = fract(u);
    float dist_to_edge = min(frac, 1.0 - frac);

    // Derivative for ~1 pixel line thickness in screen space
    // fwidth(u) approximates change in u per pixel
    float fw = max(fwidth(u), 1e-6);

    // We want ~1 pixel in screen -> in u-space that's ~fw
    // Use a narrow smoothstep around zero to keep lines thin
    // Half-width ~ 0.5 * fw gives ~1px total thickness
    float halfw = 0.5 * fw;

    // Soft mask: 1 near edge, 0 elsewhere
    float m = 1.0 - smoothstep(halfw, halfw + fw, dist_to_edge);
    return m;
}

void main()
{
    // 1) Map screen X to [-1, 1]
    float x = vTexCoord.x * 2.0 - 1.0;

    // 2) Warp
    float curved = hybrid_curve(x, Profile);
    float warped = mix(x, curved, Strength);

    // 3) Back to [0, 1]
    float final_x = 0.5 * warped + 0.5;

    // 4) Convert overscan pixels → normalized UVs
    float ox = clamp(OverscanX * InvW, 0.0, 0.25);
    float oy = clamp(OverscanY * InvH, 0.0, 0.25);

    // 5) Apply crop (post-warp visible region)
    float sample_x = ox + final_x     * (1.0 - 2.0 * ox);
    float sample_y = oy + vTexCoord.y * (1.0 - 2.0 * oy);

    sample_x = clamp(sample_x, 0.0, 1.0);
    sample_y = clamp(sample_y, 0.0, 1.0);

    // Base color
    vec4 color = texture(Source, vec2(sample_x, sample_y));

    // --- Debug overlay grid: subdivide the *visible* warped region ---
    if (DebugGrid >= 0.5)
    {
        // Ensure sane subdivision counts
        float Nx = max(Gx, 1.0);
        float Ny = max(Gy, 1.0);

        // Grid lines at integer boundaries of (sample_* * N)
        float vMask = grid_line_mask(sample_x, Nx);
        float hMask = grid_line_mask(sample_y, Ny);

        // Combine (cap at 1 to avoid overbright)
        float mask = clamp(vMask + hMask, 0.0, 1.0);

        // Draw lines as solid bright yellow (~1px thick via fwidth)
        color = mix(color, vec4(YELLOW, 1.0), mask);
    }

    FragColor = color;
}
