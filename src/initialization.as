void Main() {
    RoundStartsIn321::App::Main();
}

void OnEnabled() {
    logging::Start();
}

void OnDisabled() {
    logging::Shutdown();
}

void OnDestroyed() {
    logging::Shutdown();
}

void Update(float dt) {
    RoundStartsIn321::Countdown::Update(dt);
}

void Render() {
    RoundStartsIn321::Countdown::RenderOverlay();
}
