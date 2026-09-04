namespace RoundStartsIn321 {
    namespace Countdown {
        string PlayerLogin(CSmPlayer@ player) {
            if (player is null || player.User is null) return "";
            return player.User.Login;
        }

        bool IsLocalPlayer(CSmPlayer@ player, CGamePlayerInfo@ localUser) {
            if (player is null || player.User is null || localUser is null) return false;
            return player.User.Login == localUser.Login;
        }

        CSmPlayer@ FindLocalPlayer(
            CSmArenaClient@ playground,
            CGameTerminal@ terminal,
            CGamePlayerInfo@ localUser,
            string &out source
        ) {
            source = "None";
            if (terminal !is null) {
                CSmPlayer@ controlled = cast<CSmPlayer@>(terminal.ControlledPlayer);
                if (IsLocalPlayer(controlled, localUser)) {
                    source = "ControlledPlayer";
                    return controlled;
                }

                CSmPlayer@ gui = cast<CSmPlayer@>(terminal.GUIPlayer);
                if (IsLocalPlayer(gui, localUser)) {
                    source = "GUIPlayer";
                    return gui;
                }
            }

            for (uint i = 0; i < playground.Players.Length; i++) {
                CSmPlayer@ candidate = cast<CSmPlayer@>(playground.Players[i]);
                if (!IsLocalPlayer(candidate, localUser)) continue;

                source = "Playground.Players[" + tostring(i) + "]";
                return candidate;
            }

            return null;
        }

        CountdownSnapshot@ DetectSnapshot() {
            CountdownSnapshot@ snapshot = CountdownSnapshot();
            CTrackMania@ app = cast<CTrackMania@>(GetApp());
            if (app is null) {
                snapshot.reason = "Trackmania application is unavailable";
                return snapshot;
            }

            if (app.RootMap is null) {
                snapshot.reason = "No map is loaded";
                return snapshot;
            }
            snapshot.hasMap = true;
            if (app.RootMap.MapInfo !is null) {
                snapshot.mapUid = app.RootMap.MapInfo.MapUid;
            }
            CTrackManiaNetwork@ network = cast<CTrackManiaNetwork@>(app.Network);
            if (network is null || network.PlaygroundClientScriptAPI is null) {
                snapshot.reason = "Playground client clock is unavailable";
                return snapshot;
            }

            CGamePlaygroundClientScriptAPI@ clientApi = network.PlaygroundClientScriptAPI;
            snapshot.hasClientApi = true;
            snapshot.gameTime = clientApi.GameTime;
            snapshot.isSpectator = clientApi.IsSpectator || clientApi.IsSpectatorClient;
            if (clientApi.Map !is null && clientApi.Map.MapInfo !is null) {
                snapshot.mapUid = clientApi.Map.MapInfo.MapUid;
            }
            CSmArenaClient@ playground = cast<CSmArenaClient@>(app.CurrentPlayground);
            if (playground is null) {
                snapshot.reason = "Current playground is unavailable";
                return snapshot;
            }
            snapshot.hasPlayground = true;
            CGamePlaygroundUIConfig@ uiConfig = clientApi.UI;
            if (uiConfig is null && playground.UIConfigs.Length > 0) {
                @uiConfig = playground.UIConfigs[0];
            }
            if (uiConfig !is null) {
                snapshot.hasUiConfig = true;
                snapshot.uiSequence = uiConfig.UISequence;
                snapshot.countdownEndTime = uiConfig.CountdownEndTime;
            }
            CGameTerminal@ terminal = null;
            if (playground.GameTerminals.Length > 0) {
                @terminal = playground.GameTerminals[0];
            }
            if (terminal !is null) {
                snapshot.hasTerminal = true;
                CSmPlayer@ controlled = cast<CSmPlayer@>(terminal.ControlledPlayer);
                CSmPlayer@ gui = cast<CSmPlayer@>(terminal.GUIPlayer);
                snapshot.controlledPlayerLogin = PlayerLogin(controlled);
                snapshot.guiPlayerLogin = PlayerLogin(gui);
                snapshot.guiIsControlled = terminal.GUIPlayer !is null
                    && terminal.GUIPlayer is terminal.ControlledPlayer;
            }
            CGamePlayerInfo@ localUser = clientApi.LocalUser;
            if (localUser is null) {
                snapshot.reason = "Local user is unavailable";
                return snapshot;
            }
            snapshot.hasLocalUser = true;
            snapshot.localLogin = localUser.Login;
            if (snapshot.localLogin.Length == 0) {
                snapshot.reason = "Local user login is unavailable";
                return snapshot;
            }
            string playerSource;
            CSmPlayer@ player = FindLocalPlayer(playground, terminal, localUser, playerSource);
            snapshot.playerSource = playerSource;
            if (player is null) {
                snapshot.reason = snapshot.isSpectator ?
                    "Local user is spectating" : "Local player is not present in the playground";
                return snapshot;
            }
            snapshot.hasLocalPlayer = true;
            snapshot.playerLogin = PlayerLogin(player);
            snapshot.nativePlayerStartTime = player.StartTime;
            CSmScriptPlayer@ scriptPlayer = cast<CSmScriptPlayer@>(player.ScriptAPI);
            if (scriptPlayer is null) {
                snapshot.reason = "Local player ScriptAPI is unavailable";
                return snapshot;
            }
            snapshot.hasScriptPlayer = true;
            snapshot.startTime = scriptPlayer.StartTime;
            snapshot.currentRaceTime = scriptPlayer.CurrentRaceTime;
            snapshot.spawnStatus = scriptPlayer.SpawnStatus;
            snapshot.remainingMs = snapshot.startTime - snapshot.gameTime;
            snapshot.rawRaceTime = snapshot.gameTime - snapshot.startTime;
            snapshot.raceTimeDeltaMs = snapshot.rawRaceTime - snapshot.currentRaceTime;

            if (snapshot.isSpectator) {
                snapshot.reason = "Local user is spectating";
                return snapshot;
            }
            if (!snapshot.hasUiConfig) {
                snapshot.reason = "Local UI configuration is unavailable";
                return snapshot;
            }
            if (snapshot.uiSequence != CGamePlaygroundUIConfig::EUISequence::Playing) {
                snapshot.reason = "UI sequence is " + SequenceName(snapshot.uiSequence);
                return snapshot;
            }
            if (snapshot.startTime < 0) {
                snapshot.reason = "Player start time is not initialized";
                return snapshot;
            }

            snapshot.canTrack = true;
            snapshot.reason = "Local player start clock is ready";
            return snapshot;
        }
    }
}
