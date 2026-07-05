use std::{
    collections::{HashMap, HashSet},
    fs::{self, File},
    io::Read,
    path::PathBuf,
};

use anyhow::{anyhow, bail, Context, Result};
use chrono::{Local, NaiveDate};
use clap::{Parser, Subcommand};
use rusqlite::{params, Connection};

const EV_KEY: u16 = 1;
const KEY_LEFTCTRL: u16 = 29;
const KEY_LEFTALT: u16 = 56;
const KEY_RIGHTALT: u16 = 100;
const KEY_RIGHTCTRL: u16 = 97;
const KEY_LEFTMETA: u16 = 125;
const KEY_RIGHTMETA: u16 = 126;
const KEY_LEFTSHIFT: u16 = 42;
const KEY_RIGHTSHIFT: u16 = 54;

#[derive(Parser)]
#[command(name = "shortcut-history")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Record {
        #[arg(long)]
        db: Option<PathBuf>,
        device: PathBuf,
        #[arg(long, default_value_t = 3)]
        min_count: u64,
    },
    Devices {
        #[arg(long, default_value = "/dev/input/by-id")]
        dir: PathBuf,
    },
    Report {
        #[arg(long)]
        db: Option<PathBuf>,
        #[arg(long, default_value_t = 25)]
        limit: u32,
    },
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct DayCombo {
    day: NaiveDate,
    combo: String,
}

struct Aggregates {
    min_count: u64,
    pending: HashMap<DayCombo, u64>,
}

impl Aggregates {
    fn new(min_count: u64) -> Result<Self> {
        if min_count < 2 {
            bail!("--min-count must be at least 2");
        }

        Ok(Self {
            min_count,
            pending: HashMap::new(),
        })
    }

    fn record(&mut self, day: NaiveDate, held: &HashSet<u16>) -> Option<(DayCombo, u64)> {
        let combo = shortcut_combo_label(held)?;
        let key = DayCombo { day, combo };
        let count = self.pending.entry(key.clone()).or_default();
        *count += 1;

        if *count < self.min_count {
            return None;
        }

        let flushed = *count;
        *count = 0;
        Some((key, flushed))
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Command::Record {
            db,
            device,
            min_count,
        } => record(db_path(db)?, &device, min_count),
        Command::Devices { dir } => list_devices(&dir),
        Command::Report { db, limit } => report(db_path(db)?, limit),
    }
}

fn record(db_path: PathBuf, device: &PathBuf, min_count: u64) -> Result<()> {
    let conn = Connection::open(&db_path)
        .with_context(|| format!("opening database {}", db_path.display()))?;
    init_db(&conn)?;

    let mut file =
        File::open(device).with_context(|| format!("opening input device {}", device.display()))?;

    let mut held = HashSet::new();
    let mut aggregates = Aggregates::new(min_count)?;

    loop {
        let event = match read_input_event(&mut file) {
            Ok(event) => event,
            Err(error) if error.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(error) => return Err(error).context("reading input event"),
        };

        if event.kind != EV_KEY {
            continue;
        }

        match event.value {
            0 => {
                held.remove(&event.code);
            }
            1 => {
                held.insert(event.code);
                if let Some((key, count)) = aggregates.record(Local::now().date_naive(), &held) {
                    upsert_count(&conn, &key, count)?;
                }
            }
            2 => {}
            value => return Err(anyhow!("unexpected EV_KEY value {value}")),
        }
    }
}

fn report(db_path: PathBuf, limit: u32) -> Result<()> {
    let conn = Connection::open(&db_path)
        .with_context(|| format!("opening database {}", db_path.display()))?;
    init_db(&conn)?;

    let mut stmt = conn.prepare(
        "select day, combo, count from shortcut_counts order by count desc, day desc, combo asc limit ?1",
    )?;
    let rows = stmt.query_map([limit], |row| {
        Ok((
            row.get::<_, String>(0)?,
            row.get::<_, String>(1)?,
            row.get::<_, u64>(2)?,
        ))
    })?;

    for row in rows {
        let (day, combo, count) = row?;
        println!("{count}	{day}	{combo}");
    }

    Ok(())
}

fn list_devices(dir: &PathBuf) -> Result<()> {
    let mut found = 0_u32;
    for entry in fs::read_dir(dir).with_context(|| format!("reading {}", dir.display()))? {
        let entry = entry?;
        let name = entry.file_name().to_string_lossy().to_lowercase();
        if !name.contains("kbd") && !name.contains("keyboard") {
            continue;
        }

        let path = entry.path();
        let target = fs::canonicalize(&path).unwrap_or_else(|_| path.clone());
        println!("{}	{}", path.display(), target.display());
        found += 1;
    }

    if found == 0 {
        bail!("no keyboard-like devices found in {}", dir.display());
    }

    Ok(())
}

fn db_path(path: Option<PathBuf>) -> Result<PathBuf> {
    if let Some(path) = path {
        return Ok(path);
    }

    let base = dirs::data_local_dir().ok_or_else(|| anyhow!("could not find local data directory"))?;
    let dir = base.join("shortcut-history");
    fs::create_dir_all(&dir).with_context(|| format!("creating {}", dir.display()))?;
    Ok(dir.join("shortcut-history.sqlite"))
}

fn init_db(conn: &Connection) -> Result<()> {
    conn.execute_batch(
        "create table if not exists shortcut_counts (
            day text not null,
            combo text not null,
            count integer not null,
            primary key (day, combo)
        );",
    )?;
    Ok(())
}

fn upsert_count(conn: &Connection, key: &DayCombo, count: u64) -> Result<()> {
    conn.execute(
        "insert into shortcut_counts (day, combo, count)
         values (?1, ?2, ?3)
         on conflict(day, combo) do update set count = count + excluded.count",
        params![key.day.to_string(), key.combo, count],
    )?;
    Ok(())
}

struct InputEvent {
    kind: u16,
    code: u16,
    value: i32,
}

fn read_input_event(file: &mut File) -> std::io::Result<InputEvent> {
    let mut buf = [0_u8; 24];
    file.read_exact(&mut buf)?;

    Ok(InputEvent {
        kind: u16::from_ne_bytes([buf[16], buf[17]]),
        code: u16::from_ne_bytes([buf[18], buf[19]]),
        value: i32::from_ne_bytes([buf[20], buf[21], buf[22], buf[23]]),
    })
}

fn shortcut_combo_label(held: &HashSet<u16>) -> Option<String> {
    if held.len() < 2 || held.contains(&KEY_RIGHTALT) {
        return None;
    }

    let has_shortcut_modifier = held.contains(&KEY_LEFTCTRL)
        || held.contains(&KEY_RIGHTCTRL)
        || held.contains(&KEY_LEFTALT)
        || held.contains(&KEY_LEFTMETA)
        || held.contains(&KEY_RIGHTMETA);

    if !has_shortcut_modifier || !held.iter().any(|code| !is_modifier(*code)) {
        return None;
    }

    let mut labels = held.iter().map(|code| key_label(*code)).collect::<Vec<_>>();
    labels.sort_unstable();
    Some(labels.join("+"))
}

fn is_modifier(code: u16) -> bool {
    matches!(
        code,
        KEY_LEFTCTRL
            | KEY_RIGHTCTRL
            | KEY_LEFTALT
            | KEY_RIGHTALT
            | KEY_LEFTMETA
            | KEY_RIGHTMETA
            | KEY_LEFTSHIFT
            | KEY_RIGHTSHIFT
    )
}

fn key_label(code: u16) -> String {
    let label = match code {
        1 => "Esc",
        2 => "1",
        3 => "2",
        4 => "3",
        5 => "4",
        6 => "5",
        7 => "6",
        8 => "7",
        9 => "8",
        10 => "9",
        11 => "0",
        12 => "Minus",
        13 => "Equal",
        14 => "Backspace",
        15 => "Tab",
        16 => "Q",
        17 => "W",
        18 => "E",
        19 => "R",
        20 => "T",
        21 => "Y",
        22 => "U",
        23 => "I",
        24 => "O",
        25 => "P",
        26 => "LeftBrace",
        27 => "RightBrace",
        28 => "Enter",
        KEY_LEFTCTRL => "LeftCtrl",
        30 => "A",
        31 => "S",
        32 => "D",
        33 => "F",
        34 => "G",
        35 => "H",
        36 => "J",
        37 => "K",
        38 => "L",
        39 => "Semicolon",
        40 => "Apostrophe",
        41 => "Grave",
        KEY_LEFTSHIFT => "LeftShift",
        43 => "Backslash",
        44 => "Z",
        45 => "X",
        46 => "C",
        47 => "V",
        48 => "B",
        49 => "N",
        50 => "M",
        51 => "Comma",
        52 => "Dot",
        53 => "Slash",
        KEY_RIGHTSHIFT => "RightShift",
        55 => "KpAsterisk",
        KEY_LEFTALT => "LeftAlt",
        57 => "Space",
        58 => "CapsLock",
        59 => "F1",
        60 => "F2",
        61 => "F3",
        62 => "F4",
        63 => "F5",
        64 => "F6",
        65 => "F7",
        66 => "F8",
        67 => "F9",
        68 => "F10",
        87 => "F11",
        88 => "F12",
        KEY_RIGHTCTRL => "RightCtrl",
        KEY_RIGHTALT => "RightAlt",
        102 => "Home",
        103 => "Up",
        104 => "PageUp",
        105 => "Left",
        106 => "Right",
        107 => "End",
        108 => "Down",
        109 => "PageDown",
        110 => "Insert",
        111 => "Delete",
        KEY_LEFTMETA => "LeftSuper",
        KEY_RIGHTMETA => "RightSuper",
        _ => return format!("Key{code}"),
    };

    label.to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn held(keys: &[u16]) -> HashSet<u16> {
        keys.iter().copied().collect()
    }

    #[test]
    fn drops_single_keys() {
        assert_eq!(shortcut_combo_label(&held(&[30])), None);
    }

    #[test]
    fn drops_shift_only_typing() {
        assert_eq!(shortcut_combo_label(&held(&[KEY_LEFTSHIFT, 30])), None);
    }

    #[test]
    fn drops_altgr_text_entry() {
        assert_eq!(shortcut_combo_label(&held(&[KEY_RIGHTALT, 18])), None);
    }

    #[test]
    fn keeps_ctrl_shortcut() {
        assert_eq!(shortcut_combo_label(&held(&[KEY_LEFTCTRL, 31])), Some("LeftCtrl+S".to_owned()));
    }

    #[test]
    fn keeps_super_shortcut() {
        assert_eq!(shortcut_combo_label(&held(&[KEY_LEFTMETA, 36])), Some("J+LeftSuper".to_owned()));
    }

    #[test]
    fn waits_for_threshold() {
        let day = NaiveDate::from_ymd_opt(2026, 7, 5).unwrap();
        let mut aggregates = Aggregates::new(3).unwrap();
        let keys = held(&[KEY_LEFTCTRL, 31]);

        assert!(aggregates.record(day, &keys).is_none());
        assert!(aggregates.record(day, &keys).is_none());
        let (_, count) = aggregates.record(day, &keys).unwrap();
        assert_eq!(count, 3);
    }
}
