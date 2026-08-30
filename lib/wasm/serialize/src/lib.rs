use std::fmt::Write;

use nix_wasm_rust::{panic, Type, Value};

// toKeyValues: Valve KeyValues format, matches lib/format.nix's pure-Nix
// version. get_attrset() is a BTreeMap, matching Nix's sorted iteration.

fn write_keyvalues_leaf(out: &mut String, v: &Value) {
    // Matches Nix's toString: Bool -> "1"/"", Null -> "", others throw.
    match v.get_type() {
        Type::String => out.push_str(&v.get_string()),
        Type::Int => write!(out, "{}", v.get_int()).unwrap(),
        Type::Float => write_float(out, v.get_float()),
        Type::Bool => out.push_str(if v.get_bool() { "1" } else { "" }),
        Type::Null => {}
        Type::Path => write!(out, "{}", v.get_path().to_string_lossy()).unwrap(),
        _ => panic("toKeyValues: leaf value cannot be coerced to a string"),
    }
}

fn write_indent(out: &mut String, depth: usize) {
    for _ in 0..depth {
        out.push('\t');
    }
}

fn write_keyvalues_lines(
    out: &mut String,
    depth: usize,
    attrs: &std::collections::BTreeMap<String, Value>,
) {
    for (index, (name, value)) in attrs.iter().enumerate() {
        if index != 0 {
            out.push('\n');
        }
        write_indent(out, depth);
        match value.get_type() {
            Type::Attrs => {
                writeln!(out, "\"{name}\"").unwrap();
                write_indent(out, depth);
                out.push_str("{\n");
                write_keyvalues_lines(out, depth + 1, &value.get_attrset());
                out.push('\n');
                write_indent(out, depth);
                out.push('}');
            }
            _ => {
                write!(out, "\"{name}\"\t\t\"").unwrap();
                write_keyvalues_leaf(out, value);
                out.push('"');
            }
        }
    }
}

#[no_mangle]
pub extern "C" fn to_keyvalues(arg: Value) -> Value {
    if !matches!(arg.get_type(), Type::Attrs) {
        panic("toKeyValues: top-level value must be an attrset");
    }
    let mut out = String::new();
    write_keyvalues_lines(&mut out, 0, &arg.get_attrset());
    out.push('\n');
    Value::make_string(&out)
}

// toSexpr: matches ihalseide/json-sexpr's sexpr.py `to_s` exactly,
// including no string escaping and Python True/False/None rendering.

fn write_float(out: &mut String, f: f64) {
    // Python str(float) always shows a decimal point; Rust's doesn't.
    if f.fract() == 0.0 && f.is_finite() {
        write!(out, "{f:.1}").unwrap();
    } else {
        write!(out, "{f}").unwrap();
    }
}

fn write_sexpr_atom(out: &mut String, v: &Value) {
    match v.get_type() {
        Type::String => write!(out, "\"{}\"", v.get_string()).unwrap(),
        Type::Path => write!(out, "\"{}\"", v.get_path().to_string_lossy()).unwrap(),
        Type::Int => write!(out, "{}", v.get_int()).unwrap(),
        Type::Float => write_float(out, v.get_float()),
        Type::Bool => out.push_str(if v.get_bool() { "True" } else { "False" }),
        Type::Null => out.push_str("None"),
        Type::List => {
            out.push_str("(list");
            for item in v.get_list() {
                out.push(' ');
                write_sexpr_atom(out, &item);
            }
            out.push(')');
        }
        Type::Attrs => {
            out.push_str("(dict");
            for (key, value) in v.get_attrset() {
                write!(out, " \"{key}\" ").unwrap();
                write_sexpr_atom(out, &value);
            }
            out.push(')');
        }
        Type::Function => panic("toSexpr: cannot serialize a function"),
    }
}

#[no_mangle]
pub extern "C" fn to_sexpr(arg: Value) -> Value {
    let mut out = String::new();
    write_sexpr_atom(&mut out, &arg);
    out.push('\n');
    Value::make_string(&out)
}
