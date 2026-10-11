namespace RoundStartsIn321 {
    namespace Countdown {
        void FocusGameWindow() {
            try {
                Display::Restore();
                Display::Foreground();
            } catch {
                logging::Warning(
                    "Could not focus Trackmania: " + getExceptionInfo(),
                    "RoundStartsIn321::Countdown::FocusGameWindow"
                );
            }
        }
    }
}
