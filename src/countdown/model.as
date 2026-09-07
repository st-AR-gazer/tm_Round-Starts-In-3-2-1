namespace RoundStartsIn321 {
    namespace Countdown {
        const int kClockRewindToleranceMs = 50;
        const int kStartTimeCorrectionToleranceMs = 100;
        const int kTransientUnavailableGraceMs = 150;

        [Setting hidden name="Log countdown state transitions"]
        bool S_LogStateTransitions = true;

        enum CountdownPhase {
            Unavailable,
            Armed,
            Counting,
            Go,
            Hidden
        }

        class CountdownSnapshot {
            bool hasMap = false;
            bool hasPlayground = false;
            bool hasClientApi = false;
            bool hasUiConfig = false;
            bool hasTerminal = false;
            bool hasLocalUser = false;
            bool hasLocalPlayer = false;
            bool hasScriptPlayer = false;
            bool isSpectator = false;
            bool canTrack = false;
            string reason = "Awaiting first game snapshot";
            string mapUid = "";
            string localLogin = "";
            string playerLogin = "";
            string playerSource = "None";
            string controlledPlayerLogin = "";
            string guiPlayerLogin = "";
            bool guiIsControlled = false;
            int gameTime = 0;
            int startTime = -1;
            int nativePlayerStartTime = -1;
            int currentRaceTime = 0;
            int remainingMs = 0;
            int rawRaceTime = 0;
            int raceTimeDeltaMs = 0;
            int countdownEndTime = -1;
            CGamePlaygroundUIConfig::EUISequence uiSequence =
            CGamePlaygroundUIConfig::EUISequence::None;
            CSmScriptPlayer::ESpawnStatus spawnStatus =
            CSmScriptPlayer::ESpawnStatus::NotSpawned;
        }

        CountdownSnapshot@ g_Snapshot = CountdownSnapshot();
        CountdownPhase g_Phase = CountdownPhase::Unavailable;
        string g_TrackedMapUid = "";
        string g_TrackedPlayerLogin = "";
        int g_TrackedStartTime = -1;
        bool g_ObservedFutureStart = false;
        int g_DisplayCountdownSpanMs = 0;
        bool g_HasPreviousEligibleSample = false;
        int g_PreviousRemainingMs = 0;
        bool g_HasPreviousClockSample = false;
        int g_PreviousGameTime = 0;
        string g_PreviousMapUid = "";
        int64 g_UnavailableSinceMs = -1;
        int64 g_GoStartedAtMs = -1;
        uint g_TransitionCount = 0;
        uint g_ResetCount = 0;
        uint g_StartTimeCorrectionCount = 0;
        uint g_TransientUnavailableCount = 0;
        string g_LastTransitionReason = "Awaiting first game snapshot";
        string g_LastResetReason = "Plugin initialization";
        int64 g_LastTransitionAtMs = 0;

        string PhaseName(CountdownPhase phase) {
            switch (phase) {
            case CountdownPhase::Unavailable : return "Unavailable";
            case CountdownPhase::Armed : return "Armed";
            case CountdownPhase::Counting : return "Counting";
            case CountdownPhase::Go : return "Go";
            case CountdownPhase::Hidden : return "Hidden";
            }
            return "Unknown";
        }

        string SequenceName(CGamePlaygroundUIConfig::EUISequence sequence) {
            switch (sequence) {
            case CGamePlaygroundUIConfig::EUISequence::None : return "None";
            case CGamePlaygroundUIConfig::EUISequence::Playing : return "Playing";
            case CGamePlaygroundUIConfig::EUISequence::Intro : return "Intro";
            case CGamePlaygroundUIConfig::EUISequence::Outro : return "Outro";
            case CGamePlaygroundUIConfig::EUISequence::Podium : return "Podium";
            case CGamePlaygroundUIConfig::EUISequence::CustomMTClip : return "CustomMTClip";
            case CGamePlaygroundUIConfig::EUISequence::EndRound : return "EndRound";
            case CGamePlaygroundUIConfig::EUISequence::PlayersPresentation : return "PlayersPresentation";
            case CGamePlaygroundUIConfig::EUISequence::UIInteraction : return "UIInteraction";
            case CGamePlaygroundUIConfig::EUISequence::RollingBackgroundIntro : return "RollingBackgroundIntro";
            case CGamePlaygroundUIConfig::EUISequence::CustomMTClip_WithUIInteraction :
                return "CustomMTClip_WithUIInteraction";
            case CGamePlaygroundUIConfig::EUISequence::Finish : return "Finish";
            }
            return "Unknown (" + tostring(int(sequence)) + ")";
        }

        string SpawnStatusName(CSmScriptPlayer::ESpawnStatus status) {
            switch (status) {
            case CSmScriptPlayer::ESpawnStatus::NotSpawned : return "NotSpawned";
            case CSmScriptPlayer::ESpawnStatus::Spawning : return "Spawning";
            case CSmScriptPlayer::ESpawnStatus::Spawned : return "Spawned";
            }
            return "Unknown (" + tostring(int(status)) + ")";
        }

        string FormatMilliseconds(int value) {
            return Text::Format("%.3f s", float(value) / 1000.0f);
        }

        void SetPhase(
            CountdownPhase nextPhase,
            const string &in reason,
            bool refreshTimestamp = false
        ) {
            if (g_Phase == nextPhase) {
                if (refreshTimestamp) {
                    g_LastTransitionReason = reason;
                    g_LastTransitionAtMs = Time::Now;
                }
                return;
            }

            string previousName = PhaseName(g_Phase);
            g_Phase = nextPhase;
            g_TransitionCount++;
            g_LastTransitionReason = reason;
            g_LastTransitionAtMs = Time::Now;
            if (S_LogStateTransitions) {
                logging::Entry entry(
                    "Countdown phase changed",
                    logging::Level::Debug
                );
                entry.Context = "RoundStartsIn321::Countdown::SetPhase";
                entry.Tag = "countdown";
                entry.Add("previous_phase", previousName);
                entry.Add("current_phase", PhaseName(nextPhase));
                entry.Add("reason", reason);
                entry.Add("transition_count", g_TransitionCount);
                entry.Add("map_uid", g_TrackedMapUid);
                entry.Add("start_time", g_TrackedStartTime);
                logging::Write(entry);
            }
        }

        void ResetTracking(const string &in reason, bool recordReset = true) {
            g_SoundTicks.lastStep = 0;
            bool hadTrackedStart = g_TrackedStartTime >= 0 || g_TrackedPlayerLogin.Length > 0;
            string previousMapUid = g_TrackedMapUid;
            int previousStartTime = g_TrackedStartTime;
            g_TrackedMapUid = "";
            g_TrackedPlayerLogin = "";
            g_TrackedStartTime = -1;
            g_ObservedFutureStart = false;
            g_DisplayCountdownSpanMs = 0;
            g_HasPreviousEligibleSample = false;
            g_PreviousRemainingMs = 0;
            g_UnavailableSinceMs = -1;
            g_GoStartedAtMs = -1;
            if (!recordReset) return;
            g_ResetCount++;
            g_LastResetReason = reason;
            if (hadTrackedStart && S_LogStateTransitions) {
                logging::Entry entry(
                    "Countdown tracking reset",
                    logging::Level::Debug
                );
                entry.Context = "RoundStartsIn321::Countdown::ResetTracking";
                entry.Tag = "countdown";
                entry.Add("reason", reason);
                entry.Add("reset_count", g_ResetCount);
                entry.Add("previous_map_uid", previousMapUid);
                entry.Add("previous_start_time", previousStartTime);
                logging::Write(entry);
            }
        }

        void Initialise() {
            @g_Snapshot = CountdownSnapshot();
            g_Phase = CountdownPhase::Unavailable;
            g_TransitionCount = 0;
            g_ResetCount = 0;
            g_StartTimeCorrectionCount = 0;
            g_TransientUnavailableCount = 0;
            g_LastTransitionReason = "Awaiting first game snapshot";
            g_LastResetReason = "Plugin initialization";
            g_LastTransitionAtMs = Time::Now;
            g_HasPreviousClockSample = false;
            g_PreviousGameTime = 0;
            g_PreviousMapUid = "";
            ResetTracking("Plugin initialization", false);
        }

        bool IsSignificantClockRewind(int previousGameTime, int currentGameTime) {
            return previousGameTime > currentGameTime
                && previousGameTime - currentGameTime > kClockRewindToleranceMs;
        }

        bool IsSmallStartTimeCorrection(int previousStartTime, int currentStartTime) {
            return previousStartTime >= 0
                && currentStartTime >= 0
                && previousStartTime != currentStartTime
                && Math::Abs(previousStartTime - currentStartTime) <= kStartTimeCorrectionToleranceMs;
        }

        void TrackStart(CountdownSnapshot@ snapshot) {
            g_SoundTicks.lastStep = 0;
            g_TrackedMapUid = snapshot.mapUid;
            g_TrackedPlayerLogin = snapshot.playerLogin;
            g_TrackedStartTime = snapshot.startTime;
            g_ObservedFutureStart = snapshot.remainingMs > 0;
            g_DisplayCountdownSpanMs = 0;
            g_GoStartedAtMs = -1;
        }

        void BeginDisplayCountdown(int remainingMs) {
            g_DisplayCountdownSpanMs = Math::Max(1, remainingMs);
        }

        void RememberClockSnapshot(CountdownSnapshot@ snapshot) {
            if (snapshot.hasClientApi) {
                g_HasPreviousClockSample = true;
                g_PreviousGameTime = snapshot.gameTime;
                g_PreviousMapUid = snapshot.mapUid;
            } else {
                g_HasPreviousClockSample = false;
                g_PreviousMapUid = "";
            }
        }

        void RememberSnapshot(CountdownSnapshot@ snapshot) {
            RememberClockSnapshot(snapshot);
            if (snapshot.canTrack) {
                g_HasPreviousEligibleSample = true;
                g_PreviousRemainingMs = snapshot.remainingMs;
            } else {
                g_HasPreviousEligibleSample = false;
            }
        }

        void AdvanceState(CountdownSnapshot@ snapshot) {
            bool mapChanged = g_HasPreviousClockSample
                && g_PreviousMapUid.Length > 0
                && snapshot.mapUid.Length > 0
                && snapshot.mapUid != g_PreviousMapUid;
            bool clockRewound = g_HasPreviousClockSample
                && snapshot.hasClientApi
                && IsSignificantClockRewind(g_PreviousGameTime, snapshot.gameTime);

            if (mapChanged) {
                ResetTracking("Map changed from " + g_PreviousMapUid + " to " + snapshot.mapUid);
            } else if (clockRewound) {
                ResetTracking("Game clock rewound from " + tostring(g_PreviousGameTime) + " to " + tostring(snapshot.gameTime));
            }
            if (!snapshot.canTrack) {
                bool canGraceUnavailable = g_TrackedStartTime >= 0
                    && (g_Phase == CountdownPhase::Armed || g_Phase == CountdownPhase::Counting || g_Phase == CountdownPhase::Go);
                if (canGraceUnavailable) {
                    if (g_UnavailableSinceMs < 0) {
                        g_UnavailableSinceMs = Time::Now;
                        g_TransientUnavailableCount++;
                        if (S_LogStateTransitions) {
                            logging::Entry entry(
                                "Temporarily preserving countdown tracking",
                                logging::Level::Debug
                            );
                            entry.Context = "RoundStartsIn321::Countdown::AdvanceState";
                            entry.Tag = "countdown";
                            entry.Add("reason", snapshot.reason);
                            entry.Add("phase", PhaseName(g_Phase));
                            entry.Add("grace_ms", kTransientUnavailableGraceMs);
                            logging::Write(entry);
                        }
                    }
                    if (Time::Now - g_UnavailableSinceMs <= kTransientUnavailableGraceMs) {
                        RememberClockSnapshot(snapshot);
                        return;
                    }
                }
                ResetTracking(snapshot.reason, canGraceUnavailable);
                SetPhase(CountdownPhase::Unavailable, snapshot.reason);
                RememberSnapshot(snapshot);
                return;
            }
            g_UnavailableSinceMs = -1;
            bool sameMap = g_TrackedMapUid == snapshot.mapUid;
            bool samePlayer = g_TrackedPlayerLogin == snapshot.playerLogin;
            bool correctedStartTime = sameMap
                && samePlayer
                && IsSmallStartTimeCorrection(g_TrackedStartTime, snapshot.startTime);
            if (correctedStartTime) {
                int previousStartTime = g_TrackedStartTime;
                g_TrackedStartTime = snapshot.startTime;
                g_StartTimeCorrectionCount++;
                if (S_LogStateTransitions) {
                    logging::Entry entry(
                        "Accepted countdown clock correction",
                        logging::Level::Debug
                    );
                    entry.Context = "RoundStartsIn321::Countdown::AdvanceState";
                    entry.Tag = "countdown";
                    entry.Add("previous_start_time", previousStartTime);
                    entry.Add("current_start_time", snapshot.startTime);
                    entry.Add("correction_count", g_StartTimeCorrectionCount);
                    logging::Write(entry);
                }
            }

            bool newStart = !sameMap
                || !samePlayer
                || (!correctedStartTime && g_TrackedStartTime != snapshot.startTime);

            if (newStart) {
                if (g_TrackedStartTime >= 0) {
                    ResetTracking("Start context changed to " + snapshot.playerLogin + " at " + tostring(snapshot.startTime));
                }
                TrackStart(snapshot);
                if (snapshot.remainingMs > CountdownWindowMs()) {
                    SetPhase(
                        CountdownPhase::Armed,
                        "Future player start detected",
                        true
                    );
                } else if (snapshot.remainingMs > 0) {
                    BeginDisplayCountdown(snapshot.remainingMs);
                    SetPhase(
                        CountdownPhase::Counting,
                        "Entered the countdown window",
                        true
                    );
                } else {
                    SetPhase(
                        CountdownPhase::Hidden,
                        "Start was already reached when first observed",
                        true
                    );
                }
                RememberSnapshot(snapshot);
                return;
            }

            if (snapshot.remainingMs > 0) {
                g_ObservedFutureStart = true;
                g_GoStartedAtMs = -1;
                if (snapshot.remainingMs > CountdownWindowMs()) {
                    g_DisplayCountdownSpanMs = 0;
                    SetPhase(CountdownPhase::Armed, "Waiting for the display window");
                } else {
                    if (g_Phase != CountdownPhase::Counting || g_DisplayCountdownSpanMs <= 0) {
                        BeginDisplayCountdown(snapshot.remainingMs);
                    } else if (snapshot.remainingMs > g_DisplayCountdownSpanMs) {
                        g_DisplayCountdownSpanMs = snapshot.remainingMs;
                    }
                    SetPhase(CountdownPhase::Counting, "Player start is in the future");
                }
            } else {
                bool crossedZero = g_ObservedFutureStart
                    && g_HasPreviousEligibleSample
                    && g_PreviousRemainingMs > 0;

                if (crossedZero) {
                    g_GoStartedAtMs = Time::Now;
                    SetPhase(CountdownPhase::Go, "Player start clock crossed zero");
                } else if (g_Phase == CountdownPhase::Go && g_GoStartedAtMs >= 0 && Time::Now - g_GoStartedAtMs < GoDurationMs()) {
                    SetPhase(CountdownPhase::Go, "Holding the GO state");
                } else {
                    SetPhase(CountdownPhase::Hidden, "Player start has passed");
                }
            }
            RememberSnapshot(snapshot);
        }

        void Update(float dt) {
            CountdownSnapshot@ snapshot = DetectSnapshot();
            AdvanceState(snapshot);
            @g_Snapshot = snapshot;
            UpdateSounds();
        }
    }
}
