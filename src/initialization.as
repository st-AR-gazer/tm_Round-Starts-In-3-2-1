void Main() {
    RoundStartsIn321::App::Main();
}

void Update(float dt) {
    RoundStartsIn321::Countdown::Update(dt);
}

void Render() {
    RoundStartsIn321::Countdown::RenderOverlay();
}
