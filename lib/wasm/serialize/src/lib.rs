use nix_wasm_rust::{panic, Type, Value};

// toKeyValues: Valve KeyValues format, matches lib/format.nix's pure-Nix
// version. get_attrset() is a BTreeMap, matching Nix's sorted iteration.

fn keyvalues_leaf_string(v: &Value) -> String {
    // Matches Nix's toString: Bool -> "1"/"", Null -> "", others throw.
    match v.get_type() {
        Type::String => v.get_string(),
        Type::Int => v.get_int().to_string(),
        Type::Float => format_float(v.get_float()),
        Type::Bool => if v.get_bool() { "1" } else { "" }.to_string(),
        Type::Null => String::new(),
        Type::Path => v.get_path().to_string_lossy().into_owned(),
        _ => panic("toKeyValues: leaf value cannot be coerced to a string"),
    }
}

fn keyvalues_lines(depth: usize, attrs: &std::collections::BTreeMap<String, Value>) -> String {
    let indent = "\t".repeat(depth);
    let lines: Vec<String> = attrs
        .iter()
        .map(|(name, value)| match value.get_type() {
            Type::Attrs => format!(
                "{indent}\"{name}\"\n{indent}{{\n{}\n{indent}}}",
                keyvalues_lines(depth + 1, &value.get_attrset())
            ),
            _ => format!("{indent}\"{name}\"\t\t\"{}\"", keyvalues_leaf_string(value)),
        })
        .collect();
    lines.join("\n")
}

#[no_mangle]
pub extern "C" fn to_keyvalues(arg: Value) -> Value {
    if !matches!(arg.get_type(), Type::Attrs) {
        panic("toKeyValues: top-level value must be an attrset");
    }
    let out = keyvalues_lines(0, &arg.get_attrset()) + "\n";
    Value::make_string(&out)
}

// toSexpr: matches ihalseide/json-sexpr's sexpr.py `to_s` exactly,
// including no string escaping and Python True/False/None rendering.

fn format_float(f: f64) -> String {
    // Python str(float) always shows a decimal point; Rust's doesn't.
    if f.fract() == 0.0 && f.is_finite() {
        format!("{f:.1}")
    } else {
        f.to_string()
    }
}

fn sexpr_atom(v: &Value) -> String {
    match v.get_type() {
        Type::String => format!("\"{}\"", v.get_string()),
        Type::Path => format!("\"{}\"", v.get_path().to_string_lossy()),
        Type::Int => v.get_int().to_string(),
        Type::Float => format_float(v.get_float()),
        Type::Bool => if v.get_bool() { "True" } else { "False" }.to_string(),
        Type::Null => "None".to_string(),
        Type::List => {
            let items: Vec<String> = v.get_list().iter().map(sexpr_atom).collect();
            format!("(list {})", items.join(" "))
        }
        Type::Attrs => {
            let pairs: Vec<String> = v
                .get_attrset()
                .iter()
                .map(|(k, val)| format!("\"{k}\" {}", sexpr_atom(val)))
                .collect();
            format!("(dict {})", pairs.join(" "))
        }
        Type::Function => panic("toSexpr: cannot serialize a function"),
    }
}

#[no_mangle]
pub extern "C" fn to_sexpr(arg: Value) -> Value {
    let out = sexpr_atom(&arg) + "\n";
    Value::make_string(&out)
}
