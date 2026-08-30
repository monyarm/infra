use nix_wasm_rust::{panic, Type, Value};
use std::collections::HashMap;

// Batched port of lib/misc.nix's sortDispatchKeys + resolveExtSorted: one
// call resolves every file in an archive, instead of ~1000 Nix-level calls
// per file. Must stay byte-for-byte faithful to the Nix version's
// semantics (a mismatch silently misroutes a file to the wrong
// optimizer) -- works on raw bytes throughout since Nix's
// stringLength/substring are byte-indexed and lib.toLower is ASCII-only;
// str::to_ascii_lowercase matches that exactly.
//
// Input: { entries = [ { rawLen; kind = "exact"|"suffix"|"prefix";
// compareStr (lowercased); key (original extMap key) } ... ];
// files = [ <basename> ... ]; }
// Output: attrset keyed by each file's original-case name -> matched key
// or null (Nix side applies the "_" fallback itself). Duplicate basenames
// collapse to one cached lookup, same answer either way.
type LengthBucket = (
    HashMap<Vec<u8>, String>,
    HashMap<Vec<u8>, String>,
    HashMap<Vec<u8>, String>,
);

fn ends_with_ascii_case_insensitive(name: &str, suffix: &str) -> bool {
    let name = name.as_bytes();
    let suffix = suffix.as_bytes();
    name.len() >= suffix.len()
        && name[name.len() - suffix.len()..]
            .iter()
            .zip(suffix)
            .all(|(left, right)| left.eq_ignore_ascii_case(right))
}

#[no_mangle]
pub extern "C" fn detect_optimizer_tools(arg: Value) -> Value {
    if !matches!(arg.get_type(), Type::List) {
        panic("detect_optimizer_tools: argument must be a list");
    }

    let mut has_rpa = false;
    let mut has_json = false;
    for file in arg.get_list() {
        let name = file.get_string();
        has_rpa |= ends_with_ascii_case_insensitive(&name, ".rpa");
        has_json |= ends_with_ascii_case_insensitive(&name, ".json")
            || ends_with_ascii_case_insensitive(&name, ".jsonc");
        if has_rpa && has_json {
            break;
        }
    }
    let mut flags = String::new();
    if has_rpa {
        flags.push_str("rpa,");
    }
    if has_json {
        flags.push_str("json,");
    }
    Value::make_string(&flags)
}

#[no_mangle]
pub extern "C" fn resolve_dispatch_batch(arg: Value) -> Value {
    if !matches!(arg.get_type(), Type::Attrs) {
        panic("resolveDispatchBatch: top-level value must be an attrset");
    }
    let input = arg.get_attrset();
    let entries = input
        .get("entries")
        .unwrap_or_else(|| panic("resolveDispatchBatch: missing 'entries'"));
    let files = input
        .get("files")
        .unwrap_or_else(|| panic("resolveDispatchBatch: missing 'files'"));

    let mut by_len: HashMap<i64, LengthBucket> = HashMap::new();

    for e in entries.get_list() {
        let attrs = e.get_attrset();
        let raw_len = attrs
            .get("rawLen")
            .unwrap_or_else(|| panic("resolveDispatchBatch: entry missing 'rawLen'"))
            .get_int();
        let kind = attrs
            .get("kind")
            .unwrap_or_else(|| panic("resolveDispatchBatch: entry missing 'kind'"))
            .get_string();
        let compare_str = attrs
            .get("compareStr")
            .unwrap_or_else(|| panic("resolveDispatchBatch: entry missing 'compareStr'"))
            .get_string();
        let key = attrs
            .get("key")
            .unwrap_or_else(|| panic("resolveDispatchBatch: entry missing 'key'"))
            .get_string();

        let bucket = by_len.entry(raw_len).or_default();
        match kind.as_str() {
            "exact" => {
                bucket.0.insert(compare_str.into_bytes(), key);
            }
            "suffix" => {
                bucket.1.insert(compare_str.into_bytes(), key);
            }
            "prefix" => {
                bucket.2.insert(compare_str.into_bytes(), key);
            }
            other => panic(&format!("resolveDispatchBatch: unknown kind '{other}'")),
        }
    }

    let mut sorted_lengths: Vec<i64> = by_len.keys().copied().collect();
    sorted_lengths.sort_unstable_by(|a, b| b.cmp(a));

    // Real archives repeat basenames a lot -- cache skips the scan on a repeat.
    // A raw-name cache experiment was only 3.1% faster for exact repeats but
    // 21.4% slower for unique names; revisit with a reusable ASCII-folded
    // scratch buffer if dispatch allocation becomes measurable again.
    let mut cache: HashMap<Vec<u8>, Option<String>> = HashMap::new();
    let mut names: Vec<String> = Vec::with_capacity(files.get_list().len());
    let mut values: Vec<Value> = Vec::with_capacity(files.get_list().len());

    for f in files.get_list().iter() {
        let raw_name = f.get_string();
        let file_bytes = raw_name.to_ascii_lowercase().into_bytes();

        let found = if let Some(cached) = cache.get(&file_bytes) {
            cached.clone()
        } else {
            let file_len = file_bytes.len() as i64;
            let mut found: Option<String> = None;

            'lengths: for &l in &sorted_lengths {
                let marked_len = l - 1;
                let bucket = &by_len[&l];

                if marked_len == file_len {
                    if let Some(key) = bucket.0.get(&file_bytes[..]) {
                        found = Some(key.clone());
                        break 'lengths;
                    }
                }
                if l <= file_len {
                    let start = (file_len - l) as usize;
                    if let Some(key) = bucket.1.get(&file_bytes[start..]) {
                        found = Some(key.clone());
                        break 'lengths;
                    }
                }
                if marked_len >= 0 && marked_len <= file_len {
                    if let Some(key) = bucket.2.get(&file_bytes[..marked_len as usize]) {
                        found = Some(key.clone());
                        break 'lengths;
                    }
                }
            }

            cache.insert(file_bytes, found.clone());
            found
        };

        values.push(match &found {
            Some(key) => Value::make_string(key),
            None => Value::make_null(),
        });
        names.push(raw_name);
    }

    let attrs: Vec<(&str, Value)> = names
        .iter()
        .map(|s| s.as_str())
        .zip(values.into_iter())
        .collect();
    Value::make_attrset(&attrs)
}
