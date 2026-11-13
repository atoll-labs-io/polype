use serde::Serialize;

pub const CONTRACT: u32 = 1;

pub const OK: i32 = 0;
#[allow(dead_code)]
pub const REFUSED: i32 = 1;
pub const UNREADABLE: i32 = 2;

/// Every object `po` prints: the body's fields with `"contract": 1` beside them.
#[derive(Serialize)]
pub struct Reply<T: Serialize> {
    pub contract: u32,
    #[serde(flatten)]
    pub body: T,
}

#[derive(Serialize)]
pub struct ErrorReply {
    pub contract: u32,
    pub error: String,
    pub message: String,
}

fn print_line<T: Serialize>(value: &T) {
    // Serialising derived types cannot fail; a failure is a bug the panic hook reports.
    let text = serde_json::to_string(value).expect("serialise the reply");
    println!("{text}");
}

/// Prints one reply and gives back the exit code it goes with.
pub fn reply<T: Serialize>(body: T, code: i32) -> i32 {
    print_line(&Reply { contract: CONTRACT, body });
    code
}

pub fn error(code: i32, error: &str, message: impl Into<String>) -> i32 {
    print_line(&ErrorReply {
        contract: CONTRACT,
        error: error.to_string(),
        message: message.into(),
    });
    code
}

pub fn not_built(verb: &str) -> i32 {
    error(
        UNREADABLE,
        "not-built",
        format!("po {verb} is not built yet; a later story of M21 brings it"),
    )
}

/// A panic still prints one object on stdout, and nothing else, then exits 2.
pub fn install_panic_hook() {
    std::panic::set_hook(Box::new(|info| {
        let message = match info.payload().downcast_ref::<&str>() {
            Some(text) => text.to_string(),
            None => match info.payload().downcast_ref::<String>() {
                Some(text) => text.clone(),
                None => "po stopped on an internal error".to_string(),
            },
        };
        let text = serde_json::to_string(&ErrorReply {
            contract: CONTRACT,
            error: "internal".to_string(),
            message,
        })
        .unwrap_or_else(|_| r#"{"contract":1,"error":"internal","message":"po stopped on an internal error"}"#.to_string());
        println!("{text}");
        std::process::exit(UNREADABLE);
    }));
}
