namespace RoundStartsIn321 {
    namespace App {
        void RenderGeneralSettingsUI() {
            bool open = UI::BeginChild("##round-starts-in-321-settings-general", vec2(0, 0), false);
            if (open) {
                RoundStartsIn321::Countdown::RenderSettingsUI();
            }
            UI::EndChild();
        }

        void RenderLoggingSettingsUI() {
            bool open = UI::BeginChild("##round-starts-in-321-settings-logging", vec2(0, 0), false);
            if (open) {
                logging::RenderSettingsUI("round-starts-in-321-logging");
            }
            UI::EndChild();
        }
    }
}
