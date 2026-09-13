[SettingsTab name="General" icon="Cog" order=1]
void RenderRoundStartsIn321GeneralSettingsTab() {
    RoundStartsIn321::App::RenderGeneralSettingsUI();
}

[SettingsTab name="Appearance" icon="PaintBrush" order=2]
void RenderRoundStartsIn321AppearanceSettingsTab() {
    RoundStartsIn321::App::RenderAppearanceSettingsUI();
}

[SettingsTab name="Sounds" icon="Music" order=3]
void RenderRoundStartsIn321SoundsSettingsTab() {
    RoundStartsIn321::Countdown::RenderSoundsSettingsUI();
}

[SettingsTab name="Window" icon="Desktop" order=4]
void RenderRoundStartsIn321WindowSettingsTab() {
    RoundStartsIn321::App::RenderWindowSettingsUI();
}

[SettingsTab name="Logging" icon="ListAlt" order=99]
void RenderRoundStartsIn321LoggingSettingsTab() {
    RoundStartsIn321::App::RenderLoggingSettingsUI();
}
