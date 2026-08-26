namespace RoundStartsIn321 {
    namespace Status {
        string g_Status = "Ready for countdown implementation";

        void RenderPanel() {
            UI::Text(RoundStartsIn321::Shared::FormatStatusLine("Status", g_Status));
        }

        void RenderSettingsUI() {
            UI::Text("Countdown");
            UI::TextDisabled("Countdown behavior will be configured here as the feature is implemented.");
        }
    }
}
j