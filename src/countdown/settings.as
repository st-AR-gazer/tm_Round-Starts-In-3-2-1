namespace RoundStartsIn321 {
    namespace Countdown {
        const int kCountdownDisplayStart = 3;
        const int kPreviewCountdownMs = 1400;
        const int kDefaultDecimalPlaces = 0;

        [Setting hidden name="Enable countdown overlay"]
        bool S_Enabled = true;
        [Setting hidden name="Hide countdown with game UI"]
        bool S_HideWithGameUi = true;
        [Setting hidden name="Flash taskbar when countdown appears"]
        bool S_FlashTaskbar = false;
        [Setting hidden name="Focus game when countdown appears"]
        bool S_FocusGame = false;
        [Setting hidden name="Seconds before start to show countdown"]
        int S_CountdownWindowSeconds = 10;
        [Setting hidden name="Countdown decimal places"]
        int S_DecimalPlaces = kDefaultDecimalPlaces;
        [Setting hidden name="Use real remaining seconds"]
        bool S_UseRealCountdown = false;
        [Setting hidden name="Countdown size"]
        float S_FontScale = 1.0f;
        [Setting hidden name="Animate countdown overlay"]
        bool S_AnimateOverlay = true;
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
        vec4 S_GoColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        [Setting hidden name="Use countdown step background colors"]
        bool S_UseStageBackgroundColors = true;
        [Setting hidden name="3 and above background color"]
        vec4 S_ThreeBackgroundColor = vec4(0.72f, 0.06f, 0.07f, 0.92f);
        [Setting hidden name="2 background color"]
        vec4 S_TwoBackgroundColor = vec4(0.85f, 0.27f, 0.02f, 0.92f);
        [Setting hidden name="1 background color"]
        vec4 S_OneBackgroundColor = vec4(0.72f, 0.52f, 0.02f, 0.92f);
        [Setting hidden name="GO background color"]
        vec4 S_GoBackgroundColor = vec4(0.05f, 0.52f, 0.16f, 0.92f);
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
            g_PreviewSoundTicks.Reset();
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
            if (elapsedMs < kPreviewCountdownMs + GoDurationMs()) {
                showGo = true;
                return true;
            }

            StopPreview();
            return false;
        }

        void ResetOverlaySettings() {
            S_Enabled = true;
            S_HideWithGameUi = false;
            S_FlashTaskbar = false;
            S_FocusGame = false;
            S_CountdownWindowSeconds = 15;
            S_DecimalPlaces = kDefaultDecimalPlaces;
            S_UseRealCountdown = false;
            S_FontScale = 1.0f;
            S_AnimateOverlay = true;
            S_ShowGo = true;
            S_GoDurationMs = 500;
            S_ShowBackground = true;
            S_HeadingColor = vec4(0.82f, 0.88f, 0.96f, 1.0f);
            S_CountdownColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
            S_GoColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
            S_UseStageBackgroundColors = true;
            S_ThreeBackgroundColor = vec4(0.72f, 0.06f, 0.07f, 0.92f);
            S_TwoBackgroundColor = vec4(0.85f, 0.27f, 0.02f, 0.92f);
            S_OneBackgroundColor = vec4(0.72f, 0.52f, 0.02f, 0.92f);
            S_GoBackgroundColor = vec4(0.05f, 0.52f, 0.16f, 0.92f);
            S_BackgroundColor = vec4(0.015f, 0.022f, 0.035f, 0.82f);
        }

        void RenderSettingsUI() {
            UI::Text("Countdown overlay");
            S_Enabled = UI::Checkbox("Enabled##round-starts-in-321-overlay", S_Enabled);
            S_HideWithGameUi = UI::Checkbox(
                "Hide when the game UI is hidden##round-starts-in-321-overlay",
                S_HideWithGameUi
            );
            S_FlashTaskbar = UI::Checkbox("Flash taskbar on countdown", S_FlashTaskbar);
            UI::SetItemTooltip("Flashes once when the countdown appears. Does not switch to the game.");
            S_FocusGame = UI::Checkbox("Focus game on countdown", S_FocusGame);
            UI::SetItemTooltip("Brings Trackmania forward when the countdown starts, including from another desktop.");
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
            UI::SetNextItemWidth(260.0f);
            S_FontScale = UI::SliderFloat(
                "Display size##round-starts-in-321-overlay",
                S_FontScale,
                0.5f,
                2.0f,
                "%.2f x"
            );
            S_AnimateOverlay = UI::Checkbox(
                "Animate appearance and GO!##round-starts-in-321-overlay",
                S_AnimateOverlay
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
                S_UseStageBackgroundColors = UI::Checkbox(
                    "Color background by countdown step##round-starts-in-321-overlay",
                    S_UseStageBackgroundColors
                );
                if (S_UseStageBackgroundColors) {
                    S_ThreeBackgroundColor = UI::InputColor4(
                        "3+ background##round-starts-in-321-overlay",
                        S_ThreeBackgroundColor
                    );
                    S_TwoBackgroundColor = UI::InputColor4(
                        "2 background##round-starts-in-321-overlay",
                        S_TwoBackgroundColor
                    );
                    S_OneBackgroundColor = UI::InputColor4(
                        "1 background##round-starts-in-321-overlay",
                        S_OneBackgroundColor
                    );
                    S_GoBackgroundColor = UI::InputColor4(
                        "GO! background##round-starts-in-321-overlay",
                        S_GoBackgroundColor
                    );
                } else {
                    S_BackgroundColor = UI::InputColor4(
                        "Background color##round-starts-in-321-overlay",
                        S_BackgroundColor
                    );
                }
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
            }
        }
    }
}
