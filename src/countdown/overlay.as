namespace RoundStartsIn321 {
    namespace Countdown {
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

        string FormatRealCountdownValue(int remainingMs) {
            int decimals = DecimalPlaces();
            int resolutionMs = 1000;
            if (decimals == 1) {
                resolutionMs = 100;
            } else if (decimals == 2) {
                resolutionMs = 10;
            } else if (decimals == 3) {
                resolutionMs = 1;
            }
            int safeRemainingMs = Math::Max(0, remainingMs);
            int roundedMs = safeRemainingMs;
            if (resolutionMs > 1) {
                roundedMs = ((safeRemainingMs + resolutionMs - 1) / resolutionMs) * resolutionMs;
            }

            string format = "%." + tostring(decimals) + "f s";
            return Text::Format(format, float(roundedMs) / 1000.0f);
        }

        string FormatNormalizedCountdownValue(int remainingMs, int displaySpanMs) {
            int multiplier = 1;
            int decimals = DecimalPlaces();
            if (decimals == 1) {
                multiplier = 10;
            } else if (decimals == 2) {
                multiplier = 100;
            } else if (decimals == 3) {
                multiplier = 1000;
            }

            int safeRemainingMs = Math::Max(0, remainingMs);
            int safeDisplaySpanMs = Math::Max(1, displaySpanMs);
            int maximumTicks = kCountdownDisplayStart * multiplier;
            int64 numerator = int64(safeRemainingMs) * int64(maximumTicks);
            int ticks = int((numerator + int64(safeDisplaySpanMs) - 1) / int64(safeDisplaySpanMs));
            ticks = Math::Clamp(ticks, 0, maximumTicks);
            string format = "%." + tostring(decimals) + "f";
            return Text::Format(format, float(ticks) / float(multiplier));
        }

        string FormatCountdownValue(int remainingMs, int displaySpanMs) {
            if (S_UseRealCountdown) return FormatRealCountdownValue(remainingMs);
            return FormatNormalizedCountdownValue(remainingMs, displaySpanMs);
        }

        bool TryGetOverlayFrame(int &out remainingMs, int &out displaySpanMs, bool &out showGo) {
            remainingMs = 0;
            displaySpanMs = 1;
            showGo = false;

            if (TryGetPreviewFrame(remainingMs, showGo)) {
                displaySpanMs = kPreviewCountdownMs;
                return true;
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
            resolutionScale = Math::Clamp(resolutionScale, 0.67f, 3.0f);
            float scale = resolutionScale * FontScale();
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
            if (S_ShowBackground) {
                nvg::BeginPath();
                nvg::RoundedRect(panelPos, panelSize, 24.0f * scale);
                nvg::FillColor(S_BackgroundColor);
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
