namespace RoundStartsIn321 {
    namespace App {
        void Main() {
            log(
                "Loaded " + RoundStartsIn321::PluginMeta.Name + " v" + RoundStartsIn321::PluginMeta.Version,
                LogLevel::Debug,
                4,
                "RoundStartsIn321::App::Main"
            );
        }

        bool ShouldRenderWindow() {
            if (!S_WindowOpen) return false;
            if (S_HideWithGame && !UI::IsGameUIVisible()) return false;
            if (S_HideWithOP && !UI::IsOverlayShown()) return false;
            return true;
        }

        void RenderInterface() {
            if (!ShouldRenderWindow()) return;

            if (UI::Begin(MenuTitle() + "###main-" + RoundStartsIn321::PluginMeta.ID, S_WindowOpen, UI::WindowFlags::None)) {
                RenderWindow();
            }
            UI::End();
        }

        void RenderMenu() {
            if (UI::MenuItem(MenuTitle(), "", S_WindowOpen)) {
                S_WindowOpen = !S_WindowOpen;
            }
        }

        void RenderWindow() {
            UI::Text(RoundStartsIn321::PluginMeta.Name + " " + RoundStartsIn321::PluginMeta.Version);
            UI::Separator();
            RoundStartsIn321::Status::RenderPanel();
        }
    }
}
