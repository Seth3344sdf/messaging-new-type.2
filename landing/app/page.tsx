export default function Home() {
  return (
    <>
      <nav className="top container">
        <div className="brand">Messaging</div>
        <a className="signin" href="https://app.example.com">Sign in</a>
      </nav>

      <section className="hero container">
        <h1 className="serif">A quieter place to talk.</h1>
        <p>
          Team chat built around the way your team actually thinks.
          Fast like Linear. Encrypted in transit. A quiet AI turns your
          conversations into shared knowledge as they happen — no chatbots,
          no formality.
        </p>
        <div className="cta-row">
          <a className="cta-primary" href="https://app.example.com">
            Try it free →
          </a>
          <a className="cta-secondary" href="#why">
            See what's inside
          </a>
        </div>
        <div style={{ marginTop: 24 }}>
          <span className="lock">🔒 end-to-end encrypted in transit</span>
        </div>
      </section>

      <section className="pillars container" id="why">
        <div className="pillar">
          <span className="tag">⌘K</span>
          <h3 className="serif">Search that thinks.</h3>
          <p>
            One keyboard shortcut, every chat, every decision, every file.
            Type what you mean, not what you remember.
          </p>
        </div>
        <div className="pillar">
          <span className="tag">Pulse</span>
          <h3 className="serif">An AI that quietly catches you up.</h3>
          <p>
            Open a thread with 30 unread messages — Pulse summarizes them
            before you finish scrolling. No bot to talk to, just a helper
            already at the top of the screen.
          </p>
        </div>
        <div className="pillar">
          <span className="tag">Memory</span>
          <h3 className="serif">Conversations become decisions.</h3>
          <p>
            Long-press any message → "pin as decision." Every chat has a
            Memory sheet — your team's institutional knowledge, captured
            in the moments it actually happens.
          </p>
        </div>
      </section>

      <section className="editorial">
        <div className="container">
          <blockquote className="serif">
            "Built for fast, direct talk. No fluff."
          </blockquote>
        </div>
      </section>

      <section className="pillars container">
        <div className="pillar">
          <span className="tag">Privacy</span>
          <h3 className="serif">Your data stays yours.</h3>
          <p>
            We don't train on your messages. Privacy isn't a footer link —
            it's the architecture.
          </p>
        </div>
        <div className="pillar">
          <span className="tag">Briefing</span>
          <h3 className="serif">News, in context.</h3>
          <p>
            Market movers and headlines that your team is already talking
            about — share to a channel with one tap.
          </p>
        </div>
        <div className="pillar">
          <span className="tag">Anywhere</span>
          <h3 className="serif">iOS, web, macOS.</h3>
          <p>
            One account. Pick up the conversation wherever your hands are.
          </p>
        </div>
      </section>

      <footer className="container footer">
        <div>© Messaging</div>
        <div style={{ display: 'flex', gap: 18 }}>
          <a href="/privacy">Privacy</a>
          <a href="/terms">Terms</a>
          <a href="mailto:hello@example.com">Contact</a>
        </div>
      </footer>
    </>
  );
}
