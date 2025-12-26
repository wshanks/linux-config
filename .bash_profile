. ~/.bashrc

if [[ "$(gsettings get org.gnome.desktop.interface gtk-theme)" = "'Adwaita'" ]] && \
   [[ "$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]]; then
  export GTK_THEME=Adwaita:dark
fi
