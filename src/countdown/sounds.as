namespace RoundStartsIn321 {
    namespace Countdown {
        enum TickSound {
            None,
            SoftTick,
            LowBeep,
            HighBeep,
            Chime
        }

        [Setting hidden name="Enable countdown sounds"]
        bool S_SoundsEnabled = false;
        [Setting hidden name="Countdown sound volume"]
        float S_SoundVolume = 0.5f;
        [Setting hidden name="Sound for ticks 4 and above"]
        int S_EarlyTickSound = TickSound::SoftTick;
        [Setting hidden name="Sound for tick 3"]
        int S_ThreeTickSound = TickSound::LowBeep;
        [Setting hidden name="Sound for tick 2"]
        int S_TwoTickSound = TickSound::LowBeep;
        [Setting hidden name="Sound for tick 1"]
        int S_OneTickSound = TickSound::LowBeep;
        [Setting hidden name="Sound for GO"]
        int S_GoTickSound = TickSound::Chime;

        array<Audio::Sample@> g_TickSamples(5);
        SoundTickTracker g_SoundTicks;
        SoundTickTracker g_PreviewSoundTicks;

        string TickSoundName(int sound) {
            if (sound >= kBuiltinSoundCount && sound < int(g_TickSamples.Length)) {
                return g_CustomSoundFiles[sound - kBuiltinSoundCount] + " (custom)";
            }
            switch (sound) {
            case TickSound::SoftTick : return "Soft tick";
            case TickSound::LowBeep : return "Low beep";
            case TickSound::HighBeep : return "High beep";
            case TickSound::Chime : return "Chime";
            }
            return sound == TickSound::None ? "None" : "Unavailable sound";
        }

        void InitialiseSounds() {
            g_TickSamples.Resize(kBuiltinSoundCount);
            array<string> files = {"", "tick.wav", "low.wav", "high.wav", "chime.wav"};
            for (uint i = 1; i < files.Length; i++) {
                try {
                    @g_TickSamples[i] = Audio::LoadSample("src/countdown/audio/" + files[i]);
                } catch {
                    logging::Warning(
                        "Could not load countdown sound: " + files[i] + ": " + getExceptionInfo(),
                        "RoundStartsIn321::Countdown::InitialiseSounds"
                    );
                }
            }
            LoadCustomSounds();
        }

        bool IsSoundAvailable(int sound) {
            int index = int(sound);
            return index > 0 && index < int(g_TickSamples.Length) && g_TickSamples[index] !is null;
        }

        void PlayTickSound(int sound) {
            if (!IsSoundAvailable(sound)) return;
            Audio::Play(g_TickSamples[int(sound)], Math::Clamp(S_SoundVolume, 0.0f, 1.0f));
        }

        int SoundForStep(int step) {
            if (step >= 4) return S_EarlyTickSound;
            if (step == 3) return S_ThreeTickSound;
            if (step == 2) return S_TwoTickSound;
            if (step == 1) return S_OneTickSound;
            if (step == 0) return S_GoTickSound;
            return TickSound::None;
        }

        int SoundStep(int remainingMs, int displaySpanMs) {
            if (S_UseRealCountdown) return CountdownTicksFromMilliseconds(remainingMs, 1);
            return AdaptiveCountdownStep(remainingMs, displaySpanMs);
        }

        class SoundTickTracker {
            int lastStep = 0;
            bool finished = false;

            void Reset() {
                lastStep = 0;
                finished = false;
            }

            bool Consume(int step) {
                if (step < 0 || finished) return false;
                if (step == 0) {
                    finished = true;
                    return true;
                }
                if (lastStep > 0 && step >= lastStep) return false;
                lastStep = step;
                return true;
            }
        }

        void UpdateSounds() {
            int remainingMs;
            bool showGo;
            bool preview = TryGetPreviewFrame(remainingMs, showGo);
            if (preview) {
                int step = showGo ? 0 : SoundStep(remainingMs, kPreviewCountdownMs);
                if (g_PreviewSoundTicks.Consume(step) && S_SoundsEnabled) {
                    PlayTickSound(SoundForStep(step));
                }
            }
            if ((g_Phase != CountdownPhase::Counting && g_Phase != CountdownPhase::Go) || g_Snapshot is null || !g_Snapshot.canTrack) return;
            int step = g_Phase == CountdownPhase::Go ? 0 : SoundStep(g_Snapshot.remainingMs, g_DisplayCountdownSpanMs);
            if (!g_SoundTicks.Consume(step)) return;
            if (preview || !S_SoundsEnabled || !S_Enabled) return;
            if (!IsCountdownSessionAllowed()) return;
            if (S_HideWithGameUi && !UI::IsGameUIVisible()) return;
            PlayTickSound(SoundForStep(step));
        }

        int RenderSoundChoice(const string &in label, int selected) {
            UI::SetNextItemWidth(220.0f);
            if (UI::BeginCombo(label, TickSoundName(selected))) {
                for (int i = 0; i < int(g_TickSamples.Length); i++) {
                    int choice = i;
                    if (UI::Selectable(TickSoundName(choice), selected == choice)) selected = choice;
                }
                UI::EndCombo();
            }
            UI::SameLine();
            if (UI::Button("Play##" + label)) PlayTickSound(selected);
            if (selected != TickSound::None && !IsSoundAvailable(selected)) {
                UI::SameLine();
                UI::Text("Unavailable");
                UI::SetItemTooltip("Reload the plugin to retry loading this sound.");
            }
            return selected;
        }

        void RenderSoundsSettingsUI() {
            S_SoundsEnabled = UI::Checkbox("Enable countdown sounds", S_SoundsEnabled);
            UI::SetNextItemWidth(260.0f);
            S_SoundVolume = UI::SliderFloat("Volume", S_SoundVolume, 0.0f, 1.0f, "%.2f");
            UI::Separator();
            S_EarlyTickSound = RenderSoundChoice("4+", S_EarlyTickSound);
            S_ThreeTickSound = RenderSoundChoice("3", S_ThreeTickSound);
            S_TwoTickSound = RenderSoundChoice("2", S_TwoTickSound);
            S_OneTickSound = RenderSoundChoice("1", S_OneTickSound);
            S_GoTickSound = RenderSoundChoice("GO", S_GoTickSound);
            UI::Separator();
            UI::BeginDisabled();
            UI::Button("Add audio file...");
            UI::EndDisabled();
            if (UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
                UI::SetTooltip("Requires the upcoming fileexplorer integration.");
            }
            if (g_CustomSoundError.Length > 0) UI::TextWrapped(g_CustomSoundError);
            UI::Separator();
            if (UI::Button("Preview countdown##sounds")) StartPreview();
            if (IsPreviewActive()) {
                UI::SameLine();
                if (UI::Button("Stop preview##sounds")) StopPreview();
            }
            UI::SameLine();
            if (UI::Button("Reset sound defaults")) {
                S_SoundsEnabled = false;
                S_SoundVolume = 0.5f;
                S_EarlyTickSound = TickSound::SoftTick;
                S_ThreeTickSound = TickSound::LowBeep;
                S_TwoTickSound = TickSound::LowBeep;
                S_OneTickSound = TickSound::LowBeep;
                S_GoTickSound = TickSound::Chime;
            }
        }
    }
}
