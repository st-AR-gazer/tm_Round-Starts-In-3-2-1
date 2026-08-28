namespace RoundStartsIn321 {
    namespace App {
        void Main() {
            RoundStartsIn321::Countdown::Initialise();
            RoundStartsIn321::Countdown::InitialiseSettingsRuntime();
            RoundStartsIn321::Countdown::InitialiseOverlay();
            log(
                "Loaded " + RoundStartsIn321::PluginMeta.Name + " v" + RoundStartsIn321::PluginMeta.Version,
                LogLevel::Debug,
                4,
                "RoundStartsIn321::App::Main"
            );
        }
    }
}
