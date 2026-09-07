namespace RoundStartsIn321 {
    namespace Countdown {
        bool g_CountdownAppearanceObserved = false;

        bool ConsumeCountdownAppearance(bool gameUiVisible) {
            if (g_CountdownAppearanceObserved || !S_Enabled) return false;
            if (S_HideWithGameUi && !gameUiVisible) return false;
            if (g_Phase != CountdownPhase::Counting || g_Snapshot is null || !g_Snapshot.canTrack || g_Snapshot.remainingMs <= 0) return false;

            g_CountdownAppearanceObserved = true;
            return true;
        }

        void UpdateWindowAttention() {
            if (!ConsumeCountdownAppearance(UI::IsGameUIVisible())) return;
            if (S_FocusGame && !FocusGameWindow()) {
                logging::Warning(
                    "Windows did not grant focus to Trackmania.",
                    "RoundStartsIn321::Countdown::UpdateWindowAttention"
                );
            }
            if (!S_FlashTaskbar) return;
            auto app = cast<CTrackMania>(GetApp());
            if (app is null || app.ManiaPlanetScriptAPI is null) return;
            app.ManiaPlanetScriptAPI.FlashWindow();
        }
    }
}
