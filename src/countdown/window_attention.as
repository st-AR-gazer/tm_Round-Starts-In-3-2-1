namespace RoundStartsIn321 {
    namespace Countdown {
        bool g_CountdownAppearanceObserved = false;

        bool ShouldFlashCountdownWindow(bool gameUiVisible) {
            if (g_CountdownAppearanceObserved || !S_Enabled) return false;
            if (S_HideWithGameUi && !gameUiVisible) return false;
            if (g_Phase != CountdownPhase::Counting || g_Snapshot is null
                || !g_Snapshot.canTrack || g_Snapshot.remainingMs <= 0) return false;

            g_CountdownAppearanceObserved = true;
            return S_FlashTaskbar;
        }

        void UpdateWindowAttention() {
            if (!ShouldFlashCountdownWindow(UI::IsGameUIVisible())) return;
            auto app = cast<CTrackMania>(GetApp());
            if (app is null || app.ManiaPlanetScriptAPI is null) return;
            app.ManiaPlanetScriptAPI.FlashWindow();
        }
    }
}
