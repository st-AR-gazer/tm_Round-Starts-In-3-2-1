namespace RoundStartsIn321 {
    namespace Countdown {
        const int kBuiltinSoundCount = 5;
        array<string> g_CustomSoundFiles;
        string g_CustomSoundError = "";
        bool g_CustomSoundCatalogReady = false;

        string CustomSoundFolder() {
            return IO::FromStorageFolder("sounds/");
        }

        string CustomSoundCatalogPath() {
            return IO::FromStorageFolder("sounds/catalog.json");
        }

        bool IsCustomSoundFilename(const string &in name) {
            return name.Length > 0 && name != "." && name != ".."
                && name.IndexOf("/") < 0 && name.IndexOf("\\") < 0
                && name.IndexOf(":") < 0 && name != "catalog.json";
        }

        Audio::Sample@ LoadCustomSample(const string &in path) {
            if (!IO::FileExists(path)) return null;
            Audio::Sample@ sample = Audio::LoadSampleFromAbsolutePath(path);
            if (sample is null) return null;
            Audio::Voice@ probe = Audio::Play(sample, 0.0f);
            if (probe is null || probe.GetLength() <= 0.0) return null;
            return sample;
        }

        void LoadCustomSounds() {
            g_CustomSoundFiles.Resize(0);
            g_TickSamples.Resize(kBuiltinSoundCount);
            g_CustomSoundError = "";
            g_CustomSoundCatalogReady = false;
            try {
                if (IO::FileExists(CustomSoundCatalogPath())) {
                    Json::Value@ catalog = Json::FromFile(CustomSoundCatalogPath());
                    if (catalog is null || catalog.GetType() != Json::Type::Array) {
                        throw("Invalid custom sound catalog");
                    }
                    for (uint i = 0; i < catalog.Length; i++) {
                        if (catalog[i].GetType() != Json::Type::String || !IsCustomSoundFilename(string(catalog[i]))) {
                            throw("Invalid custom sound filename in catalog");
                        }
                    }
                    for (uint i = 0; i < catalog.Length; i++) {
                        string name = string(catalog[i]);
                        g_CustomSoundFiles.InsertLast(name);
                        Audio::Sample@ sample = null;
                        try {
                            @sample = LoadCustomSample(CustomSoundFolder() + name);
                        } catch {
                            logging::Warning(
                                "Could not load custom countdown sound: " + name + ": " + getExceptionInfo(),
                                "RoundStartsIn321::Countdown::LoadCustomSounds"
                            );
                        }
                        g_TickSamples.InsertLast(sample);
                    }
                }
                g_CustomSoundCatalogReady = true;
            } catch {
                g_CustomSoundError = "Could not load custom sounds: " + getExceptionInfo();
                logging::Warning(
                    g_CustomSoundError,
                    "RoundStartsIn321::Countdown::LoadCustomSounds"
                );
            }
        }

        int ImportCustomSound(const string &in sourcePath) {
            g_CustomSoundError = "";
            if (!g_CustomSoundCatalogReady) {
                g_CustomSoundError = "Custom sound catalog is unavailable. Reload the plugin to retry.";
                return -1;
            }
            try {
                if (sourcePath.Length == 0 || !IO::FileExists(sourcePath)) {
                    throw("The selected audio file does not exist");
                }
                Audio::Sample@ source = LoadCustomSample(sourcePath);
                if (source is null) throw("The selected file could not be decoded as audio");
                string name = Path::SanitizeFileName(Path::GetFileName(sourcePath));
                if (!IsCustomSoundFilename(name)) throw("Invalid audio filename");
                IO::CreateFolder(CustomSoundFolder());
                string stem = Path::GetFileNameWithoutExtension(name);
                string extension = Path::GetExtension(name);
                int suffix = 2;
                while (IO::FileExists(CustomSoundFolder() + name) || g_CustomSoundFiles.Find(name) >= 0) {
                    name = stem + " (" + tostring(suffix++) + ")" + extension;
                }
                string destination = CustomSoundFolder() + name;
                IO::Copy(sourcePath, destination);
                Audio::Sample@ stored = LoadCustomSample(destination);
                if (stored is null) throw("The stored audio file could not be loaded");

                Json::Value@ catalog = Json::Array();
                for (uint i = 0; i < g_CustomSoundFiles.Length; i++) catalog.Add(g_CustomSoundFiles[i]);
                catalog.Add(name);
                Json::ToFile(CustomSoundCatalogPath(), catalog, true);
                g_CustomSoundFiles.InsertLast(name);
                g_TickSamples.InsertLast(stored);
                return int(g_TickSamples.Length) - 1;
            } catch {
                g_CustomSoundError = "Could not import audio: " + getExceptionInfo();
                logging::Warning(
                    g_CustomSoundError,
                    "RoundStartsIn321::Countdown::ImportCustomSound"
                );
                return -1;
            }
        }
    }
}
