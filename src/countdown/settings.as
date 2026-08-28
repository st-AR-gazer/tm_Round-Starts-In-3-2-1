namespace RoundStartsIn321 {
    namespace Countdown {
        const int kCountdownDisplayStart = 3;
        const int kPreviewCountdownMs = 1400;

        [Setting hidden name="Enable countdown overlay"]
        bool S_Enabled = true;
        [Setting hidden name="Hide countdown with game UI"]
        bool S_HideWithGameUi = true;
        [Setting hidden name="Seconds before start to show countdown"]
        int S_CountdownWindowSeconds = 10;
        [Setting hidden name="Countdown decimal places"]
        int S_DecimalPlaces = 2;
        [Setting hidden name="Use real remaining seconds"]
        bool S_UseRealCountdown = false;
        [Setting hidden name="Countdown size"]
        float S_FontScale = 1.0f;
        [Setting hidden name="Show GO message"]
        bool S_ShowGo = true;
        [Setting hidden name="GO message duration"]
        int S_GoDurationMs = 500;
        [Setting hidden name="Show countdown background"]
        bool S_ShowBackground = true;
        [Setting hidden name="Countdown heading color"]
        vec4 S_HeadingColor = vec4(0.82f, 0.88f, 0.96f, 1.0f);
        [Setting hidden name="Countdown value color"]
        vec4 S_CountdownColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        [Setting hidden name="GO message color"]
        vec4 S_GoColor = vec4(0.30f, 1.0f, 0.48f, 1.0f);
        [Setting hidden name="Countdown background color"]
        vec4 S_BackgroundColor = vec4(0.015f, 0.022f, 0.035f, 0.82f);

        int64 g_PreviewStartedAtMs = -1;

        int CountdownWindowMs() {
            return Math::Clamp(S_CountdownWindowSeconds, 1, 60) * 1000;
        }

        int GoDurationMs() {
            return Math::Clamp(S_GoDurationMs, 100, 2000);
        }

        int DecimalPlaces() {
            return Math::Clamp(S_DecimalPlaces, 0, 3);
        }

        float FontScale() {
            return Math::Clamp(S_FontScale, 0.5f, 2.0f);
        }

        void InitialiseSettingsRuntime() {
            g_PreviewStartedAtMs = -1;
        }

        void StartPreview() {
            g_PreviewStartedAtMs = Time::Now;
        }

        void StopPreview() {
            g_PreviewStartedAtMs = -1;
        }

        bool IsPreviewActive() {
            return g_PreviewStartedAtMs >= 0;
        }

        bool TryGetPreviewFrame(int &out remainingMs, bool &out showGo) {
            remainingMs = 0;
            showGo = false;
            if (!IsPreviewActive()) return false;

            int64 elapsedMs = Time::Now - g_PreviewStartedAtMs;
            if (elapsedMs < 0) {
                StopPreview();
                return false;
            }
            if (elapsedMs < kPreviewCountdownMs) {
                remainingMs = kPreviewCountdownMs - int(elapsedMs);
                return true;
            }
            if (S_ShowGo && elapsedMs < kPreviewCountdownMs + GoDurationMs()) {
                showGo = true;
                return true;
            }

            StopPreview();
            return false;
        }

        void ResetOverlaySettings() {
            S_Enabled = true;
            S_HideWithGameUi = true;
            S_CountdownWindowSeconds = 10;
            S_DecimalPlaces = 2;
            S_UseRealCountdown = false;
            S_FontScale = 1.0f;
            S_ShowGo = true;
            S_GoDurationMs = 500;
            S_ShowBackground = true;
            S_HeadingColor = vec4(0.82f, 0.88f, 0.96f, 1.0f);
            S_CountdownColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
            S_GoColor = vec4(0.30f, 1.0f, 0.48f, 1.0f);
            S_BackgroundColor = vec4(0.015f, 0.022f, 0.035f, 0.82f);
        }

        void RenderSettingsUI() {
            UI::Text("Countdown overlay");
            S_Enabled = UI::Checkbox("Enabled##round-starts-in-321-overlay", S_Enabled);
            S_HideWithGameUi = UI::Checkbox(
                "Hide when the game UI is hidden##round-starts-in-321-overlay",
                S_HideWithGameUi
            );
            UI::SetNextItemWidth(260.0f);
            S_CountdownWindowSeconds = UI::SliderInt(
                "Show before start##round-starts-in-321-overlay",
                S_CountdownWindowSeconds,
                1,
                60,
                "%d s"
            );
            UI::SetNextItemWidth(260.0f);
            S_DecimalPlaces = UI::SliderInt(
                "Decimal places##round-starts-in-321-overlay",
                S_DecimalPlaces,
                0,
                3
            );
            S_UseRealCountdown = UI::Checkbox(
                "Use real remaining time (seconds)##round-starts-in-321-overlay",
                S_UseRealCountdown
            );
            if (S_UseRealCountdown) {
                UI::TextDisabled("Shows the detector's literal remaining time.");
            } else {
                UI::TextDisabled("Maps each detected pre-start window to 3 -> 0; the values are not seconds.");
            }
            UI::SetNextItemWidth(260.0f);
            S_FontScale = UI::SliderFloat(
                "Display size##round-starts-in-321-overlay",
                S_FontScale,
                0.5f,
                2.0f,
                "%.2f x"
            );
            UI::Separator();
            S_ShowGo = UI::Checkbox("Show GO!##round-starts-in-321-overlay", S_ShowGo);
            if (S_ShowGo) {
                UI::SetNextItemWidth(260.0f);
                S_GoDurationMs = UI::SliderInt(
                    "GO! duration##round-starts-in-321-overlay",
                    S_GoDurationMs,
                    100,
                    2000,
                    "%d ms"
                );
            }
            UI::Separator();
            S_ShowBackground = UI::Checkbox(
                "Show high-contrast background##round-starts-in-321-overlay",
                S_ShowBackground
            );
            S_HeadingColor = UI::InputColor4("Heading color##round-starts-in-321-overlay", S_HeadingColor);
            S_CountdownColor = UI::InputColor4("Countdown color##round-starts-in-321-overlay", S_CountdownColor);
            S_GoColor = UI::InputColor4("GO! color##round-starts-in-321-overlay", S_GoColor);
            if (S_ShowBackground) {
                S_BackgroundColor = UI::InputColor4(
                    "Background color##round-starts-in-321-overlay",
                    S_BackgroundColor
                );
            }
            UI::Separator();
            if (UI::Button("Preview countdown##round-starts-in-321-overlay")) {
                StartPreview();
            }
            if (IsPreviewActive()) {
                UI::SameLine();
                if (UI::Button("Stop preview##round-starts-in-321-overlay")) {
                    StopPreview();
                }
            }
            UI::SameLine();
            if (UI::Button("Reset defaults##round-starts-in-321-overlay")) {
                ResetOverlaySettings();
                StartPreview();
            }
            UI::TextDisabled("Preview rendering does not alter the live countdown detector.");
        }
    }
}
