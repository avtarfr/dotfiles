function rquickshare
    fish -c "env GDK_BACKEND=x11 WEBKIT_DISABLE_DMABUF_RENDERER=1 LIBGL_ALWAYS_SOFTWARE=1 /usr/bin/rquickshare >/dev/null 2>&1" & disown
end
