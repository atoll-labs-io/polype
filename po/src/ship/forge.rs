//! Which forge holds `origin`, and its three signals of collaboration, read as `/po-ship` read them
//! in prose (ADR-0079, ADR-0083). Only reads: no forge call that sends anything, no git write. A
//! token only reaches the host that issued it, and never an argument, the output or a file.

use std::path::Path;
use std::process::Command;

use serde::Serialize;
use serde_json::Value;

use crate::project::Project;
use crate::trust::forge::{api_included, program, quiet_output, ApiAnswer};

#[derive(Serialize, Default)]
pub struct Signals {
    pub writer: Option<bool>,
    pub codeowners: Option<bool>,
    pub protection: Option<bool>,
}

#[derive(Serialize)]
pub struct Failure {
    /// `None` when the forge itself could not be told, before any signal.
    signal: Option<&'static str>,
    call: String,
    reason: String,
}

pub struct Reading {
    pub forge: Option<&'static str>,
    pub signals: Signals,
    pub failed: Vec<Failure>,
}

impl Reading {
    /// One positive signal → collaborative; all three read and negative → solo; else unreadable.
    pub fn verdict(&self) -> &'static str {
        let all = [self.signals.writer, self.signals.codeowners, self.signals.protection];
        if self.forge.is_none() {
            "unreadable"
        } else if all.contains(&Some(true)) {
            "collaborative"
        } else if all.iter().all(|signal| *signal == Some(false)) {
            "solo"
        } else {
            "unreadable"
        }
    }
}

fn failure(signal: Option<&'static str>, call: impl Into<String>, reason: impl Into<String>) -> Failure {
    Failure { signal, call: call.into(), reason: reason.into() }
}

fn reason(answer: &ApiAnswer) -> String {
    match answer {
        ApiAnswer::Status(code, _) => format!("HTTP {code}"),
        ApiAnswer::Unreachable => "unreachable".to_string(),
    }
}

/// Host and path of a remote URL in its `scheme://` or scp-like form, userinfo and port dropped.
fn host_and_path(url: &str) -> Option<(String, String)> {
    let (authority, path) = match url.split_once("://") {
        Some((_, rest)) => rest.split_once('/').unwrap_or((rest, "")),
        None => {
            let (authority, path) = url.split_once(':')?;
            if authority.contains('/') {
                return None;
            }
            (authority, path)
        }
    };
    let host = authority.rsplit_once('@').map_or(authority, |(_, host)| host);
    let host = host.split_once(':').map_or(host, |(host, _)| host).to_ascii_lowercase();
    let safe = |c: char| c.is_ascii_alphanumeric() || c == '.' || c == '-';
    if host.is_empty() || !host.chars().all(safe) {
        return None;
    }
    let path = path.trim_matches('/');
    let path = path.strip_suffix(".git").unwrap_or(path);
    Some((host, path.to_string()))
}

/// `<owner>/<repo>`: the last two segments of the path.
fn owner_repo(path: &str) -> Option<String> {
    let parts: Vec<&str> = path.split('/').collect();
    let [.., owner, repo] = parts[..] else { return None };
    let valid = |part: &str| {
        !part.is_empty() && part.chars().all(|c| c.is_ascii_alphanumeric() || "._-".contains(c))
    };
    (valid(owner) && valid(repo)).then(|| format!("{owner}/{repo}"))
}

fn is_forgejo(host: &str) -> bool {
    let mut probe = Command::new(program("PO_CURL", "curl"));
    probe.args(["-q", "--globoff", "-sS", "--max-time", "10", &format!("https://{host}/api/v1/version")]);
    quiet_output(probe)
        .and_then(|out| serde_json::from_slice::<Value>(&out).ok())
        .is_some_and(|answer| answer.get("version").is_some())
}

fn env_token(names: &[&str]) -> Option<String> {
    names.iter().find_map(|name| std::env::var(name).ok().filter(|value| !value.is_empty()))
}

enum Access {
    GitHubCli,
    GitHubCurl(String),
    GitLab(String),
    Forgejo(String),
}

const GLAB_TOKENS: [&str; 3] = ["GITLAB_TOKEN", "GITLAB_ACCESS_TOKEN", "OAUTH_TOKEN"];
const TEA_TOKENS: [&str; 3] = ["GITEA_TOKEN", "TEA_HOST", "GITEA_INSTANCE_URL"];

fn glab(root: &Path) -> Command {
    let mut command = Command::new(program("PO_GLAB", "glab"));
    command.current_dir(root);
    for name in GLAB_TOKENS {
        command.env_remove(name);
    }
    command
}

fn tea(root: &Path) -> Command {
    let mut command = Command::new(program("PO_TEA", "tea"));
    command.current_dir(root);
    for name in TEA_TOKENS {
        command.env_remove(name);
    }
    command
}

fn succeeds(command: Command) -> bool {
    quiet_output(command).is_some()
}

/// Why access could not be set up: the call that failed and its fixed reason word.
type Refused = (&'static str, &'static str);

/// A branch name as one path segment of an API call: every byte outside the unreserved set is
/// percent-encoded, `/` kept, so the call names that branch and no other resource.
fn path_segment(branch: &str) -> String {
    branch
        .bytes()
        .map(|byte| match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' | b'/' => (byte as char).to_string(),
            _ => format!("%{byte:02X}"),
        })
        .collect()
}

impl Access {
    fn github() -> Result<Access, Refused> {
        let mut status = Command::new(program("PO_GH", "gh"));
        status.args(["auth", "status", "--hostname", "github.com"]);
        if succeeds(status) {
            return Ok(Access::GitHubCli);
        }
        env_token(&["GH_TOKEN", "GITHUB_TOKEN"]).map(Access::GitHubCurl).ok_or(("gh auth status", "no-cli-no-token"))
    }

    fn gitlab(root: &Path, host: &str) -> Result<Access, Refused> {
        let mut status = glab(root);
        status.args(["auth", "status", "--hostname", host]);
        if succeeds(status) {
            Ok(Access::GitLab(host.to_string()))
        } else {
            Err(("glab auth status", "no-glab-login"))
        }
    }

    /// The `tea` login whose URL is on `host`; `tea logins list` is unverified on a real `tea`
    /// (ADR-0083, Neutral), so any doubt leaves the forge unreadable.
    fn forgejo(root: &Path, host: &str) -> Result<Access, Refused> {
        let mut help = tea(root);
        help.args(["api", "--help"]);
        if !succeeds(help) {
            return Err(("tea api --help", "no-tea-login"));
        }
        let mut list = tea(root);
        list.args(["logins", "list", "--output", "json"]);
        let logins = quiet_output(list).and_then(|out| serde_json::from_slice::<Value>(&out).ok());
        let field = |login: &Value, key: &str| {
            login.as_object()?.iter().find(|(name, _)| name.eq_ignore_ascii_case(key))?.1.as_str().map(str::to_string)
        };
        logins
            .as_ref()
            .and_then(Value::as_array)
            .into_iter()
            .flatten()
            .find(|login| {
                field(login, "url").and_then(|url| host_and_path(&url)).is_some_and(|(found, _)| found == host)
            })
            .and_then(|login| field(login, "name"))
            .filter(|name| !name.is_empty() && !name.starts_with('-'))
            .map(Access::Forgejo)
            .ok_or(("tea logins list", "no-tea-login"))
    }

    fn get(&self, root: &Path, path: &str) -> ApiAnswer {
        match self {
            Access::GitHubCli => {
                let mut command = Command::new(program("PO_GH", "gh"));
                command.args(["api", "-i", "--hostname", "github.com", path]);
                api_included(command, None)
            }
            Access::GitHubCurl(token) => {
                let mut command = Command::new(program("PO_CURL", "curl"));
                command.args(["-q", "--globoff", "-sS", "-i", "--max-time", "20", "-H", "@-", &format!("https://api.github.com/{path}")]);
                let headers = format!("Authorization: Bearer {token}\nAccept: application/vnd.github+json\n");
                api_included(command, Some(headers))
            }
            Access::GitLab(host) => {
                let mut command = glab(root);
                command.args(["api", "-i", "--hostname", host, path]);
                api_included(command, None)
            }
            Access::Forgejo(login) => {
                let mut command = tea(root);
                command.args(["api", "--login", login, "-i", path]);
                api_included(command, None)
            }
        }
    }

    fn login_field(&self) -> &'static str {
        match self {
            Access::GitLab(_) => "username",
            _ => "login",
        }
    }
}

/// An absence ADR-0079 names on a protection call: a 404, or GitHub's 403 asking for another plan.
fn protection_absent(answer: &ApiAnswer) -> bool {
    match answer {
        ApiAnswer::Status(404, _) => true,
        ApiAnswer::Status(403, _) => answer
            .json()
            .and_then(|body| body.get("message")?.as_str().map(|m| m.contains("Upgrade to GitHub Pro")))
            .unwrap_or(false),
        _ => false,
    }
}

fn count_above_zero(value: Option<&Value>) -> bool {
    value.and_then(Value::as_u64).is_some_and(|count| count > 0)
}

struct Reader<'a> {
    root: &'a Path,
    access: Access,
    repo: String,
    target: &'a str,
    failed: Vec<Failure>,
}

impl Reader<'_> {
    /// A list from a 200 answer, with the total its `X-Total-Count` header gives; anything else is
    /// recorded against `signal`.
    fn list(&mut self, signal: &'static str, path: &str) -> Option<(Vec<Value>, Option<u64>)> {
        let answer = self.access.get(self.root, path);
        if let (ApiAnswer::Status(200, _), Some(Value::Array(items))) = (&answer, answer.json()) {
            let total = answer.header("X-Total-Count").and_then(|total| total.parse().ok());
            return Some((items, total));
        }
        self.failed.push(failure(Some(signal), path, reason(&answer)));
        None
    }

    fn own_login(&mut self) -> Result<String, Failure> {
        let answer = self.access.get(self.root, "user");
        let login = match (&answer, answer.json()) {
            (ApiAnswer::Status(200, _), Some(body)) => {
                body.get(self.access.login_field()).and_then(Value::as_str).map(str::to_string)
            }
            _ => None,
        };
        login.filter(|login| !login.is_empty()).ok_or_else(|| {
            let why = if matches!(answer, ApiAnswer::Status(200, _)) { "unknown-login".to_string() } else { reason(&answer) };
            failure(Some("writer"), "user", why)
        })
    }

    fn writer(&mut self, own: &str) -> Option<bool> {
        let other = |login: Option<&str>| login.is_some_and(|login| !login.eq_ignore_ascii_case(own));
        let (path, page, found) = match self.access {
            Access::GitHubCli | Access::GitHubCurl(_) => {
                let path = format!("repos/{}/collaborators?per_page=100", self.repo);
                let (items, _) = self.list("writer", &path)?;
                let found = items.iter().any(|item| {
                    item.pointer("/permissions/push").and_then(Value::as_bool) == Some(true)
                        && other(item.get("login").and_then(Value::as_str))
                });
                (path, items.len() >= 100, found)
            }
            Access::GitLab(_) => {
                let path = "projects/:id/members/all?per_page=100".to_string();
                let (items, _) = self.list("writer", &path)?;
                let found = items.iter().any(|item| {
                    item.get("access_level").and_then(Value::as_u64).is_some_and(|level| level >= 30)
                        && other(item.get("username").and_then(Value::as_str))
                });
                (path, items.len() >= 100, found)
            }
            Access::Forgejo(_) => {
                // Gitea and Forgejo cut a page at the server's own maximum, whatever `limit` asks, so
                // only the announced total proves a non-empty page holds every collaborator.
                let path = format!("repos/{}/collaborators?limit=50", self.repo);
                let (items, total) = self.list("writer", &path)?;
                let full = !items.is_empty() && total != Some(items.len() as u64);
                let logins: Vec<String> = items
                    .iter()
                    .filter_map(|item| item.get("login").and_then(Value::as_str))
                    .filter(|login| other(Some(login)))
                    .map(str::to_string)
                    .collect();
                let mut unread = false;
                for login in logins {
                    if !login.chars().all(|c| c.is_ascii_alphanumeric() || "._-".contains(c)) {
                        unread = true;
                        continue;
                    }
                    let path = format!("repos/{}/collaborators/{login}/permission", self.repo);
                    let answer = self.access.get(self.root, &path);
                    match (&answer, answer.json()) {
                        (ApiAnswer::Status(200, _), Some(body)) => {
                            if matches!(body.get("permission").and_then(Value::as_str), Some("write" | "admin")) {
                                return Some(true);
                            }
                        }
                        _ => {
                            self.failed.push(failure(Some("writer"), path, reason(&answer)));
                            unread = true;
                        }
                    }
                }
                if unread {
                    return None;
                }
                (path, full, false)
            }
        };
        if found {
            Some(true)
        } else if page {
            self.failed.push(failure(Some("writer"), path, "list-truncated"));
            None
        } else {
            Some(false)
        }
    }

    /// `Some(true)` when the answer requires an approval, `Some(false)` on an absence.
    fn protection_call(&mut self, path: &str, requires: impl Fn(&Value) -> bool) -> Option<bool> {
        let answer = self.access.get(self.root, path);
        if protection_absent(&answer) {
            return Some(false);
        }
        match (&answer, answer.json()) {
            (ApiAnswer::Status(200, _), Some(body)) => Some(requires(&body)),
            _ => {
                self.failed.push(failure(Some("protection"), path, reason(&answer)));
                None
            }
        }
    }

    fn protection(&mut self) -> Option<bool> {
        let (repo, target, segment) = (self.repo.clone(), self.target, path_segment(self.target));
        let any = |body: &Value, rule: &dyn Fn(&Value) -> bool| body.as_array().is_some_and(|items| items.iter().any(rule));
        match self.access {
            Access::GitHubCli | Access::GitHubCurl(_) => {
                let branch = self.protection_call(&format!("repos/{repo}/branches/{segment}/protection"), |body| {
                    count_above_zero(body.pointer("/required_pull_request_reviews/required_approving_review_count"))
                });
                let rules = self.protection_call(&format!("repos/{repo}/rules/branches/{segment}"), |body| {
                    any(body, &|rule| {
                        rule.get("type").and_then(Value::as_str) == Some("pull_request")
                            && count_above_zero(rule.pointer("/parameters/required_approving_review_count"))
                    })
                });
                match (branch, rules) {
                    (Some(true), _) | (_, Some(true)) => Some(true),
                    (Some(false), Some(false)) => Some(false),
                    _ => None,
                }
            }
            Access::GitLab(_) => self.protection_call("projects/:id/approval_rules", |body| {
                any(body, &|rule| count_above_zero(rule.get("approvals_required")))
            }),
            Access::Forgejo(_) => self.protection_call(&format!("repos/{repo}/branch_protections"), |body| {
                any(body, &|rule| {
                    let named = ["rule_name", "branch_name"]
                        .iter()
                        .any(|key| rule.get(*key).and_then(Value::as_str) == Some(target));
                    named && count_above_zero(rule.get("required_approvals"))
                })
            }),
        }
    }
}

const CODEOWNERS: [&str; 6] =
    ["CODEOWNERS", "docs/CODEOWNERS", ".github/CODEOWNERS", ".gitlab/CODEOWNERS", ".gitea/CODEOWNERS", ".forgejo/CODEOWNERS"];

/// A `CODEOWNERS` on `origin/<target>` naming anyone but `@<own login>`, a team or an e-mail included.
fn codeowners(project: &Project, target: &str, own: Option<&str>, failed: &mut Vec<Failure>) -> Option<bool> {
    let reference = format!("origin/{target}");
    let call = format!("git show {reference}:CODEOWNERS");
    if project.git(&["rev-parse", "--verify", "-q", &format!("{reference}^{{commit}}")]).is_none() {
        failed.push(failure(Some("codeowners"), call, "no-origin-target"));
        return None;
    }
    let mut undecided = false;
    for path in CODEOWNERS {
        let Some(text) = project.on_target(&reference, path) else { continue };
        for line in text.lines() {
            let owners = line.split_whitespace().take_while(|word| !word.starts_with('#')).skip(1);
            for owner in owners {
                match own {
                    Some(own) if owner.strip_prefix('@').is_some_and(|name| name.eq_ignore_ascii_case(own)) => {}
                    Some(_) => return Some(true),
                    None if owner.starts_with('@') && !owner.contains('/') => undecided = true,
                    None => return Some(true),
                }
            }
        }
    }
    if undecided {
        failed.push(failure(Some("codeowners"), "user", "unknown-login"));
        return None;
    }
    Some(false)
}

/// The URL `origin` is configured with, before any `insteadOf` rewrite: the forge it names is the
/// one a token may reach, whatever mirror git is told to fetch from (as `trust::forge::Forge::of`).
fn origin_url(project: &Project) -> Option<String> {
    project.git(&["config", "--get", "remote.origin.url"]).map(|url| url.trim().to_string())
}

/// `<owner>/<repo>` when `origin` is configured on github.com.
pub(super) fn github_repo(project: &Project) -> Option<String> {
    let (host, path) = host_and_path(&origin_url(project)?)?;
    (host == "github.com").then(|| owner_repo(&path)).flatten()
}

pub fn read(project: &Project, target: &str) -> Reading {
    let mut reading = Reading { forge: None, signals: Signals::default(), failed: Vec::new() };
    let origin = "git remote get-url origin";
    let Some(url) = origin_url(project) else {
        reading.failed.push(failure(None, origin, "no-origin"));
        return reading;
    };
    let parsed = host_and_path(url.trim()).and_then(|(host, path)| Some((owner_repo(&path)?, host)));
    let Some((repo, host)) = parsed else {
        reading.failed.push(failure(None, origin, "unrecognised-host"));
        return reading;
    };
    let root = project.root.as_path();
    let (forge, access) = if host == "github.com" {
        ("github", Access::github())
    } else if host.contains("gitlab") {
        ("gitlab", Access::gitlab(root, &host))
    } else if is_forgejo(&host) {
        ("forgejo", Access::forgejo(root, &host))
    } else {
        reading.failed.push(failure(None, origin, "unrecognised-host"));
        return reading;
    };
    reading.forge = Some(forge);

    let access = match access {
        Ok(access) => access,
        Err((call, why)) => {
            reading.failed.push(failure(Some("writer"), call, why));
            reading.failed.push(failure(Some("protection"), call, why));
            reading.signals.codeowners = codeowners(project, target, None, &mut reading.failed);
            return reading;
        }
    };
    let mut reader = Reader { root, access, repo, target, failed: Vec::new() };
    let own = reader.own_login();
    let own = match own {
        Ok(login) => {
            reading.signals.writer = reader.writer(&login);
            Some(login)
        }
        Err(failed) => {
            reader.failed.push(failed);
            None
        }
    };
    reading.signals.protection = reader.protection();
    reading.failed.append(&mut reader.failed);
    reading.signals.codeowners = codeowners(project, target, own.as_deref(), &mut reading.failed);
    reading
}
