namespace RoundStartsIn321 {
    namespace App {
        void Main() {
            logging::Start();
            RoundStartsIn321::Countdown::Initialise();
            RoundStartsIn321::Countdown::InitialiseSettingsRuntime();
            RoundStartsIn321::Countdown::InitialiseOverlay();
            logging::Entry entry("Plugin initialized", logging::Level::Info);
            entry.Context = "RoundStartsIn321::App::Main";
            entry.Tag = "lifecycle";
            entry.Add(
                "plugin",
                RoundStartsIn321::PluginMeta.Name
            );
            entry.Add(
                "version",
                RoundStartsIn321::PluginMeta.Version
            );
            entry.Add(
                "countdown_mode",
                RoundStartsIn321::Countdown::S_UseRealCountdown ? "real_seconds" : "adaptive_3_2_1_or_full_count"
            );
            entry.Add(
                "overlay_enabled",
                RoundStartsIn321::Countdown::S_Enabled
            );
            logging::Write(entry);
        }
    }
}
