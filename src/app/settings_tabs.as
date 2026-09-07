[SettingsTab name="General" icon="Cog" order=1]
void RenderRoundStartsIn321GeneralSettingsTab() {
    RoundStartsIn321::App::RenderGeneralSettingsUI();
}

[SettingsTab name="Sounds" icon="Music" order=2]
void RenderRoundStartsIn321SoundsSettingsTab() {
    RoundStartsIn321::Countdown::RenderSoundsSettingsUI();
}

[SettingsTab name="Logging" icon="ListAlt" order=99]
void RenderRoundStartsIn321LoggingSettingsTab() {
    RoundStartsIn321::App::RenderLoggingSettingsUI();
}
