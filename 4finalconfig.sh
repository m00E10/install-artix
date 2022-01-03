# Get and install preferred font
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/m00E10/misc/raw/main/iPortfolio.ttf
fc-cache -f -v

mkdir -p ~/.config/gtk-3.0
echo "[Settings]" >> ~/.config/gtk-3.0/settings.ini
echo "gtk-icon-theme-name = Adwaita" >> ~/.config/gtk-3.0/settings.ini
echo "gtk-theme-name = Adwaita" >> ~/.config/gtk-3.0/settings.ini
echo "gtk-font-name = DejaVu Sans 11" >> ~/.config/gtk-3.0/settings.ini
echo "gtk-application-prefer-dark-theme = true" >> ~/.config/gtk-3.0/settings.ini

flatpak install flathub org.mozilla.firefox
flatpak install flathub com.github.tchx84.Flatseal

echo "Now if youre me, you'll su into your admin user and run:"
echo "yay -S foot gomuks kickoff"
