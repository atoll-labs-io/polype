mod inbox;
mod next;
mod output;
mod project;
mod record;
mod run;
mod state;
mod trust;

fn main() {
    output::install_panic_hook();
    let mut args = std::env::args().skip(1);
    let verb = args.next();
    let rest: Vec<String> = args.collect();
    let code = match verb.as_deref() {
        None => output::error(
            output::UNREADABLE,
            "usage",
            "usage: po <state|next|inbox|answer|record|run|continue> [arguments]",
        ),
        Some("state") => state::main(&rest),
        Some("next") => next::main(&rest),
        Some("inbox") => inbox::main(&rest),
        Some("answer") => inbox::answer(&rest),
        Some("record") => record::main(&rest),
        Some("run") => run::main(&rest),
        Some("continue") => run::resume(&rest),
        Some(other) => output::error(
            output::UNREADABLE,
            "unknown-verb",
            format!("po has no verb {other}"),
        ),
    };
    std::process::exit(code);
}
