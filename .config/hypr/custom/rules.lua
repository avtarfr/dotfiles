hl.window_rule({
    match = { class = "rquickshare" },
    float = true,
})

-- Opaque active window (no blur), semi-transparent & blurred inactive window
hl.window_rule({
    match = { class = ".*" },
    opacity = "1.00 0.5",
    no_blur = false,
})
hl.window_rule({
    match = { class = "org.pwmt.zathura" },
    opacity = "1.00 0.85",
    no_blur = false,
})

hl.window_rule({
    match = { class = "com.microsoft.VSCode" },
    opacity = "0.82 0.72",
    no_blur = false,
})
hl.window_rule({
    match = { class = "Emote" },
    opacity = "1.00 0.75",
    no_blur = false,
    float = true
})
hl.layer_rule({ match = { namespace = "swayosd" }, blur = true})
hl.layer_rule({ match = { namespace = "swayosd" }, ignore_alpha = 0.7})
hl.layer_rule({ match = { namespace = "swayosd" }, blur_popups = true})

-- Swappy screenshot annotation tool
hl.window_rule({
    match = { class = "swappy" },
    float = true,
    center = true,
    opacity = "1.00 0.95",
    no_blur = false,
})

-- Fuzzel menu blur & styling
hl.layer_rule({ match = { namespace = "fuzzel" }, blur = true })
hl.layer_rule({ match = { namespace = "fuzzel" }, ignore_alpha = 0.5 })

-- Ulauncher application launcher
hl.window_rule({
    match = { class = "^(ulauncher)$" },
    float = true,
    no_blur = false,
    border_size = 0,
})

