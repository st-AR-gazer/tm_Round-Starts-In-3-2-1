namespace RoundStartsIn321 {
    namespace Countdown {
        Import::Library@ g_FocusUser32;
        Import::Library@ g_FocusKernel32;

        bool InitialiseWindowFocus() {
            if (g_FocusUser32 !is null && g_FocusKernel32 !is null) return true;
            @g_FocusUser32 = Import::GetLibrary("user32.dll");
            @g_FocusKernel32 = Import::GetLibrary("kernel32.dll");
            return g_FocusUser32 !is null && g_FocusKernel32 !is null;
        }

        uint64 FindGameWindow() {
            uint64 processIdBuffer = Dev::Allocate(4);
            if (processIdBuffer == 0) return 0;
            uint64 result = 0;
            try {
                uint processId = g_FocusKernel32.GetFunction("GetCurrentProcessId").CallUInt32();
                auto getWindow = g_FocusUser32.GetFunction("GetWindow");
                auto getThread = g_FocusUser32.GetFunction("GetWindowThreadProcessId");
                auto isVisible = g_FocusUser32.GetFunction("IsWindowVisible");
                uint64 window = g_FocusUser32.GetFunction("GetTopWindow").CallUInt64(uint64(0));
                for (uint i = 0; window != 0 && i < 4096; i++) {
                    Dev::Write(processIdBuffer, uint(0));
                    getThread.CallUInt32(window, processIdBuffer);
                    if (Dev::ReadUInt32(processIdBuffer) == processId && isVisible.CallBool(window) && getWindow.CallUInt64(window, uint(4)) == 0) {
                        // GW_OWNER
                        result = window;
                        break;
                    }
                    window = getWindow.CallUInt64(window, uint(2));  // GW_HWNDNEXT
                }
            } catch {
                logging::Warning(
                    "Could not find the Trackmania window: " + getExceptionInfo(),
                    "RoundStartsIn321::Countdown::FindGameWindow"
                );
            }
            Dev::Free(processIdBuffer);

            return result;
        }

        bool FocusGameWindow() {
            uint currentThread = 0;
            uint foregroundThread = 0;
            uint gameThread = 0;
            bool attachedForeground = false;
            bool attachedGame = false;
            bool focused = false;
            Import::Function@ attachInput;
            try {
                if (!InitialiseWindowFocus()) return false;
                uint64 window = FindGameWindow();
                if (window == 0) return false;
                auto getForeground = g_FocusUser32.GetFunction("GetForegroundWindow");
                if (getForeground.CallUInt64() == window) return true;
                auto getThread = g_FocusUser32.GetFunction("GetWindowThreadProcessId");
                @attachInput = g_FocusUser32.GetFunction("AttachThreadInput");
                currentThread = g_FocusKernel32.GetFunction("GetCurrentThreadId").CallUInt32();
                gameThread = getThread.CallUInt32(window, uint64(0));
                foregroundThread = getThread.CallUInt32(getForeground.CallUInt64(), uint64(0));
                if (foregroundThread != 0 && foregroundThread != currentThread) {
                    attachedForeground = attachInput.CallBool(currentThread, foregroundThread, int(1));
                }
                if (gameThread != 0 && gameThread != currentThread && gameThread != foregroundThread) {
                    attachedGame = attachInput.CallBool(currentThread, gameThread, int(1));
                }
                if (g_FocusUser32.GetFunction("IsIconic").CallBool(window)) {
                    g_FocusUser32.GetFunction("ShowWindowAsync").CallBool(window, int(9));  // SW_RESTORE
                }
                g_FocusUser32.GetFunction("SwitchToThisWindow").Call(window, int(1));
                g_FocusUser32.GetFunction("SetForegroundWindow").CallBool(window);
                focused = getForeground.CallUInt64() == window;
            } catch {
                logging::Warning(
                    "Could not focus Trackmania: " + getExceptionInfo(),
                    "RoundStartsIn321::Countdown::FocusGameWindow"
                );
            }
            if (attachedGame) attachInput.CallBool(currentThread, gameThread, int(0));
            if (attachedForeground) attachInput.CallBool(currentThread, foregroundThread, int(0));
            return focused;
        }
    }
}
