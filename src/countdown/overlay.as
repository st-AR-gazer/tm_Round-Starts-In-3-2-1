namespace RoundStartsIn321 {
    namespace Countdown {
        const int kOverlayFadeInMs = 140;
        const int kGoPulseMs = 180;
        const int kGoFadeOutMs = 160;

        int g_OverlayFont = -1;
        int g_OverlayFontBold = -1;

        void InitialiseOverlay() {
            if (g_OverlayFont < 0) g_OverlayFont = nvg::LoadFont("DroidSans.ttf");
            if (g_OverlayFontBold < 0) g_OverlayFontBold = nvg::LoadFont("DroidSans-Bold.ttf");
        }

        void SelectOverlayFont(bool bold) {
            int font = bold ? g_OverlayFontBold : g_OverlayFont;
            if (font >= 0) nvg::FontFace(font);
        }

        int DecimalMultiplier(int decimals) {
            int multiplier = 1;
            if (decimals == 1) {
                multiplier = 10;
            } else if (decimals == 2) {
                multiplier = 100;
            } else if (decimals == 3) {
                multiplier = 1000;
            }
            return multiplier;
        }

        int CountdownTicksFromMilliseconds(int remainingMs, int multiplier) {
            int safeRemainingMs = Math::Max(0, remainingMs);
            int safeMultiplier = Math::Max(1, multiplier);
            int64 numerator = int64(safeRemainingMs) * int64(safeMultiplier);
            return int((numerator + 999) / 1000);
        }

        string FormatRealCountdownValue(int remainingMs) {
            int decimals = DecimalPlaces();
            int multiplier = DecimalMultiplier(decimals);
            int ticks = CountdownTicksFromMilliseconds(remainingMs, multiplier);
            string format = "%." + tostring(decimals) + "f s";
            return Text::Format(format, float(ticks) / float(multiplier));
        }

        bool UsesFullCountdownScale(int displaySpanMs) {
            return displaySpanMs > kCountdownDisplayStart * 1000;
        }

        int AdaptiveCountdownTicks(int remainingMs, int displaySpanMs, int multiplier) {
            int safeRemainingMs = Math::Max(0, remainingMs);
            int safeDisplaySpanMs = Math::Max(1, displaySpanMs);
            int safeMultiplier = Math::Max(1, multiplier);
            if (UsesFullCountdownScale(safeDisplaySpanMs)) {
                int ticks = CountdownTicksFromMilliseconds(safeRemainingMs, safeMultiplier);
                int maximumTicks = CountdownTicksFromMilliseconds(
                    safeDisplaySpanMs,
                    safeMultiplier
                );
                return Math::Clamp(ticks, 0, maximumTicks);
            }

            int maximumTicks = kCountdownDisplayStart * safeMultiplier;
            int64 numerator = int64(safeRemainingMs) * int64(maximumTicks);
            int ticks = int((numerator + int64(safeDisplaySpanMs) - 1) / int64(safeDisplaySpanMs));
            return Math::Clamp(ticks, 0, maximumTicks);
        }

        int AdaptiveCountdownStep(int remainingMs, int displaySpanMs) {
            return AdaptiveCountdownTicks(remainingMs, displaySpanMs, 1);
        }

        vec4 BackgroundColorForFrame(int remainingMs, int displaySpanMs, bool showGo) {
            if (!S_UseStageBackgroundColors) return S_BackgroundColor;
            if (showGo) return S_GoBackgroundColor;

            int step = AdaptiveCountdownStep(remainingMs, displaySpanMs);
            if (step >= 3) return S_ThreeBackgroundColor;
            if (step == 2) return S_TwoBackgroundColor;
            return S_OneBackgroundColor;
        }

        string FormatAdaptiveCountdownValue(int remainingMs, int displaySpanMs) {
            int decimals = DecimalPlaces();
            int multiplier = DecimalMultiplier(decimals);
            int ticks = AdaptiveCountdownTicks(remainingMs, displaySpanMs, multiplier);
            string format = "%." + tostring(decimals) + "f";
            return Text::Format(format, float(ticks) / float(multiplier));
        }

        string FormatCountdownValue(int remainingMs, int displaySpanMs) {
            if (S_UseRealCountdown) return FormatRealCountdownValue(remainingMs);
            return FormatAdaptiveCountdownValue(remainingMs, displaySpanMs);
        }

        bool TryGetOverlayFrame(int &out remainingMs, int &out displaySpanMs, bool &out showGo) {
            remainingMs = 0;
            displaySpanMs = 1;
            showGo = false;

            if (TryGetPreviewFrame(remainingMs, showGo)) {
                displaySpanMs = kPreviewCountdownMs;
                return !showGo || S_ShowGo;
            }
            if (!S_Enabled) return false;
            if (S_HideWithGameUi && !UI::IsGameUIVisible()) return false;

            if (g_Phase == CountdownPhase::Counting && g_Snapshot !is null) {
                remainingMs = Math::Max(0, g_Snapshot.remainingMs);
                displaySpanMs = Math::Max(1, g_DisplayCountdownSpanMs);
                return remainingMs > 0;
            }
            if (g_Phase == CountdownPhase::Go && S_ShowGo) {
                showGo = true;
                return true;
            }
            return false;
        }

        float EaseOutCubic(float value) {
            float inverse = 1.0f - Math::Clamp(value, 0.0f, 1.0f);
            return 1.0f - inverse * inverse * inverse;
        }

        int64 OverlayFrameAgeMs(bool showGo) {
            int64 now = Time::Now;
            if (IsPreviewActive()) {
                int64 previewAge = now - g_PreviewStartedAtMs;
                if (previewAge < 0) previewAge = 0;
                int64 frameAge = showGo ? previewAge - kPreviewCountdownMs : previewAge;
                return frameAge > 0 ? frameAge : 0;
            }
            if (showGo && g_GoStartedAtMs >= 0) {
                int64 goAge = now - g_GoStartedAtMs;
                return goAge > 0 ? goAge : 0;
            }
            int64 phaseAge = now - g_LastTransitionAtMs;
            return phaseAge > 0 ? phaseAge : 0;
        }

        void GetOverlayAnimation(bool showGo, float &out opacity, float &out motionScale) {
            opacity = 1.0f;
            motionScale = 1.0f;
            if (!S_AnimateOverlay) return;

            int64 ageMs = OverlayFrameAgeMs(showGo);
            if (!showGo) {
                float progress = EaseOutCubic(float(ageMs) / float(kOverlayFadeInMs));
                opacity = progress;
                motionScale = 0.94f + 0.06f * progress;
                return;
            }

            float pulseProgress = EaseOutCubic(float(ageMs) / float(kGoPulseMs));
            motionScale = 1.12f - 0.12f * pulseProgress;
            int remainingGoMs = GoDurationMs() - int(ageMs);
            if (remainingGoMs < kGoFadeOutMs) {
                opacity = Math::Clamp(
                    float(remainingGoMs) / float(kGoFadeOutMs),
                    0.0f,
                    1.0f
                );
            }
        }

        void DrawTextWithShadow(
            const string &in text,
            const vec2 &in position,
            float fontSize,
            bool bold,
            const vec4 &in color,
            float shadowOffset
        ) {
            SelectOverlayFont(bold);
            nvg::FontSize(fontSize);
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, 0.88f * color.w));
            nvg::Text(position + vec2(shadowOffset, shadowOffset), text);
            nvg::FillColor(color);
            nvg::Text(position, text);
        }

        void RenderOverlay() {
            int remainingMs;
            int displaySpanMs;
            bool showGo;
            if (!TryGetOverlayFrame(remainingMs, displaySpanMs, showGo)) return;

            vec2 screen = Display::GetSize();
            if (screen.x <= 0.0f || screen.y <= 0.0f) return;

            InitialiseOverlay();
            float resolutionScale = Math::Min(screen.x / 1920.0f, screen.y / 1080.0f);
            resolutionScale = Math::Clamp(resolutionScale, 0.5f, 3.0f);
            float scale = resolutionScale * FontScale();
            float opacity;
            float motionScale;
            GetOverlayAnimation(showGo, opacity, motionScale);
            if (opacity <= 0.0f) return;
            string heading = showGo ? "ROUND START" : "ROUND STARTS IN";
            string value = showGo ? "GO!" : FormatCountdownValue(remainingMs, displaySpanMs);
            float headingSize = 34.0f * scale;
            float valueSize = (showGo ? 190.0f : 174.0f) * scale;
            float gap = 14.0f * scale;
            float paddingX = 44.0f * scale;
            float paddingY = 30.0f * scale;
            nvg::Save();
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            SelectOverlayFont(false);
            nvg::FontSize(headingSize);
            vec2 headingBounds = nvg::TextBounds(heading);
            SelectOverlayFont(true);
            nvg::FontSize(valueSize);
            vec2 valueBounds = nvg::TextBounds(value);
            float contentWidth = Math::Max(headingBounds.x, valueBounds.x);
            contentWidth = Math::Max(contentWidth, 420.0f * scale);
            float contentHeight = headingBounds.y + gap + valueBounds.y;
            vec2 panelSize = vec2(contentWidth + paddingX * 2.0f, contentHeight + paddingY * 2.0f);
            vec2 center = screen * 0.5f;
            vec2 panelPos = center - panelSize * 0.5f;
            nvg::GlobalAlpha(opacity);
            if (motionScale != 1.0f) {
                nvg::Translate(center);
                nvg::Scale(motionScale, motionScale);
                nvg::Translate(-center.x, -center.y);
            }
            if (S_ShowBackground) {
                nvg::BeginPath();
                nvg::RoundedRect(panelPos, panelSize, 24.0f * scale);
                nvg::FillColor(BackgroundColorForFrame(remainingMs, displaySpanMs, showGo));
                nvg::Fill();
            }

            float contentTop = center.y - contentHeight * 0.5f;
            vec2 headingPos = vec2(center.x, contentTop + headingBounds.y * 0.5f);
            vec2 valuePos = vec2(
                center.x,
                contentTop + headingBounds.y + gap + valueBounds.y * 0.5f
            );
            float shadowOffset = Math::Max(2.0f, 4.0f * scale);
            DrawTextWithShadow(
                heading,
                headingPos,
                headingSize,
                false,
                S_HeadingColor,
                shadowOffset * 0.6f
            );
            DrawTextWithShadow(
                value,
                valuePos,
                valueSize,
                true,
                showGo ? S_GoColor : S_CountdownColor,
                shadowOffset
            );
            nvg::Restore();
        }
    }
}
