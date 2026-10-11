local hg = require("hyprglass")

hg.config({
    default_theme = "dark",
    default_preset = "clear",
    blur_strength = 2.0,
    blur_iterations = 3,
    refraction_strength = 0.6,
    chromatic_aberration = 0.5,
    fresnel_strength = 0.6,
    specular_strength = 0.8,
    glass_opacity = 0.85,
    edge_thickness = 0.06,
    lens_distortion = 0.5,
    tint_color = 0x8899aa22,
    dark = {
        brightness = 0.82,
        contrast = 0.90,
        saturation = 0.80,
        vibrancy = 0.15,
    },
})
