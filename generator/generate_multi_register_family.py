#!/usr/bin/env python3

import argparse
import copy
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser()
parser.add_argument("--spec", required=True)
args = parser.parse_args()

SPEC_PATH = Path(args.spec).resolve()
DATA = SPEC_PATH.parent
spec = json.loads(SPEC_PATH.read_text())

if spec.get("model_type") != "multi_register_rules":
    raise SystemExit("Expected model_type=multi_register_rules")

design_id = spec["design_id"]
clock = spec["clock"]["name"]
reset = spec["reset"]["name"]
inputs = spec["inputs"]
outputs = spec["outputs"]
signal_widths = spec.get("signal_widths", {})
registers = spec["registers"]
update_rules = spec["update_rules"]
derived_outputs = spec["derived_outputs"]
properties = spec["properties"]
mutants = spec.get("mutants", [])

reg_info = {
    r["name"]: r
    for r in registers
}

GENERATED = ROOT / "build" / "generated" / design_id

for directory in [
    DATA / "rtl",
    DATA / "properties",
    DATA / "mutants",
    GENERATED,
]:
    directory.mkdir(parents=True, exist_ok=True)

for stale in (DATA / "rtl").glob("*.sv"):
    stale.unlink()

for stale in (DATA / "mutants").glob("*.sv"):
    stale.unlink()


def width_range(width):
    width = int(width)
    return "" if width == 1 else f"[{width - 1}:0] "


def signal_range(name):
    return width_range(signal_widths.get(name, 1))


def replace_names(text, mapping):
    result = str(text)

    for old in sorted(mapping, key=len, reverse=True):
        result = re.sub(
            rf"\b{re.escape(old)}\b",
            mapping[old],
            result,
        )

    return result


def port_lines():
    ports = [
        ("input", "wire", clock),
        ("input", "wire", reset),
    ]

    for name in inputs:
        ports.append(("input", "wire", name))

    for name in outputs:
        ports.append(("output", "wire", name))

    lines = []

    for i, (direction, kind, name) in enumerate(ports):
        comma = "," if i < len(ports) - 1 else ""
        lines.append(
            f"    {direction:<6} {kind:<4} "
            f"{signal_range(name)}{name}{comma}"
        )

    return "\n".join(lines)


def reg_declarations():
    lines = []

    for reg in registers:
        lines.append(
            f"    reg {width_range(reg['width'])}"
            f"{reg['name']};"
        )

    return lines


def next_declarations(kind="reg"):
    lines = []

    for reg in registers:
        lines.append(
            f"    {kind} {width_range(reg['width'])}"
            f"next_{reg['name']};"
        )

    return lines


def derived_lines():
    return [
        f"    assign {name} = {expr};"
        for name, expr in derived_outputs.items()
    ]


def effective_rules(mutation=None):
    result = copy.deepcopy(update_rules)

    if mutation is None:
        return result

    target = mutation["register"]

    if target not in result:
        raise ValueError(
            f"Unknown mutation register: {target}"
        )

    rules = result[target]
    kind = mutation["kind"]

    if kind == "replace_update_guard":
        for rule in rules:
            if rule["when"] == mutation["old"]:
                rule["when"] = mutation["new"]
                return result

        raise ValueError(
            f"{mutation['name']}: guard not found"
        )

    if kind == "replace_update_value":
        for rule in rules:
            if (
                rule["when"] == mutation["when"]
                and rule["value"] == mutation["old"]
            ):
                rule["value"] = mutation["new"]
                return result

        raise ValueError(
            f"{mutation['name']}: update value not found"
        )

    if kind == "insert_update_rule":
        new_rule = {
            "when": mutation["when"],
            "value": mutation["value"],
        }

        for i, rule in enumerate(rules):
            if rule["when"] == mutation["before"]:
                rules.insert(i, new_rule)
                return result

        raise ValueError(
            f"{mutation['name']}: insertion point not found"
        )

    raise ValueError(
        f"Unsupported mutation kind: {kind}"
    )


def emit_priority(
    target,
    rules,
    operator,
    indent,
    replacements=None,
):
    replacements = replacements or {}
    lines = []
    emitted = False

    for rule in rules:
        condition = replace_names(
            rule["when"],
            replacements,
        )
        value = replace_names(
            rule["value"],
            replacements,
        )

        if condition == "false":
            continue

        if condition == "true":
            if emitted:
                lines.append(
                    f"{indent}else "
                    f"{target} {operator} {value};"
                )
            else:
                lines.append(
                    f"{indent}{target} "
                    f"{operator} {value};"
                )
            return lines

        keyword = "if" if not emitted else "else if"

        lines.append(
            f"{indent}{keyword} ({condition}) "
            f"{target} {operator} {value};"
        )

        emitted = True

    raise ValueError(
        "Every register update list must end in "
        "an effective true rule."
    )


def priority_expression(rules):
    expression = None

    for rule in reversed(rules):
        condition = rule["when"]
        value = rule["value"]

        if condition == "false":
            continue

        if condition == "true":
            expression = value
        else:
            if expression is None:
                raise ValueError(
                    "Update rules need a true fallback."
                )

            expression = (
                f"({condition}) ? ({value}) : "
                f"({expression})"
            )

    if expression is None:
        raise ValueError("Empty update rule list.")

    return expression


def reset_block(indent):
    lines = []

    for reg in registers:
        lines.append(
            f"{indent}{reg['name']} <= "
            f"{reg['reset_value']};"
        )

    return lines


def render_canonical(rules=None, module_name=None):
    rules = rules or update_rules
    module_name = (
        module_name
        or f"{design_id}_canonical_next"
    )

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
    ]

    lines += reg_declarations()
    lines.append("")
    lines += next_declarations("reg")
    lines.extend([
        "",
        "    always @* begin",
    ])

    for reg in registers:
        lines += emit_priority(
            f"next_{reg['name']}",
            rules[reg["name"]],
            "=",
            "        ",
        )

    lines.extend([
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
    ])

    lines += reset_block("            ")

    lines.extend([
        "        end",
        "        else begin",
    ])

    for reg in registers:
        lines.append(
            f"            {reg['name']} <= "
            f"next_{reg['name']};"
        )

    lines.extend([
        "        end",
        "    end",
        "",
    ])

    lines += derived_lines()
    lines.extend(["endmodule", ""])

    return "\n".join(lines)


def render_sequential(rules=None, module_name=None):
    rules = rules or update_rules
    module_name = (
        module_name
        or f"{design_id}_sequential_priority"
    )

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
    ]

    lines += reg_declarations()

    lines.extend([
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
    ])

    lines += reset_block("            ")

    lines.extend([
        "        end",
        "        else begin",
    ])

    for reg in registers:
        lines += emit_priority(
            reg["name"],
            rules[reg["name"]],
            "<=",
            "            ",
        )

    lines.extend([
        "        end",
        "    end",
        "",
    ])

    lines += derived_lines()
    lines.extend(["endmodule", ""])

    return "\n".join(lines)


def render_ternary():
    module_name = f"{design_id}_ternary_next"

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
    ]

    lines += reg_declarations()
    lines.append("")
    lines += next_declarations("wire")
    lines.append("")

    for reg in registers:
        expr = priority_expression(
            update_rules[reg["name"]]
        )

        lines.append(
            f"    assign next_{reg['name']} = {expr};"
        )

    lines.extend([
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
    ])

    lines += reset_block("            ")

    lines.extend([
        "        end",
        "        else begin",
    ])

    for reg in registers:
        lines.append(
            f"            {reg['name']} <= "
            f"next_{reg['name']};"
        )

    lines.extend([
        "        end",
        "    end",
        "",
    ])

    lines += derived_lines()
    lines.extend(["endmodule", ""])

    return "\n".join(lines)


def render_function():
    module_name = f"{design_id}_function_update"

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
    ]

    lines += reg_declarations()
    lines.append("")

    replacement = {
        reg["name"]: f"current_{reg['name']}"
        for reg in registers
    }

    for target_reg in registers:
        function_name = (
            f"compute_next_{target_reg['name']}"
        )

        lines.append(
            f"    function automatic "
            f"{width_range(target_reg['width'])}"
            f"{function_name};"
        )

        for reg in registers:
            lines.append(
                f"        input "
                f"{width_range(reg['width'])}"
                f"current_{reg['name']};"
            )

        for name in inputs:
            lines.append(
                f"        input "
                f"{signal_range(name)}{name};"
            )

        lines.append("        begin")

        lines += emit_priority(
            function_name,
            update_rules[target_reg["name"]],
            "=",
            "            ",
            replacement,
        )

        lines.extend([
            "        end",
            "    endfunction",
            "",
        ])

    lines += next_declarations("wire")
    lines.append("")

    arguments = (
        [reg["name"] for reg in registers]
        + inputs
    )

    for reg in registers:
        lines.append(
            f"    assign next_{reg['name']} = "
            f"compute_next_{reg['name']}("
            + ", ".join(arguments)
            + ");"
        )

    lines.extend([
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
    ])

    lines += reset_block("            ")

    lines.extend([
        "        end",
        "        else begin",
    ])

    for reg in registers:
        lines.append(
            f"            {reg['name']} <= "
            f"next_{reg['name']};"
        )

    lines.extend([
        "        end",
        "    end",
        "",
    ])

    lines += derived_lines()
    lines.extend(["endmodule", ""])

    return "\n".join(lines)


def pastify(expression):
    result = expression

    signals = [
        reset,
        *inputs,
        *outputs,
    ]

    for name in sorted(
        signals,
        key=len,
        reverse=True,
    ):
        result = re.sub(
            rf"\b{re.escape(name)}\b",
            f"$past({name})",
            result,
        )

    return result


def render_property_harness():
    formal_inputs = [reset] + inputs

    lines = [
        "`ifndef DUT_MODULE",
        "`define DUT_MODULE missing_dut_module",
        "`endif",
        "",
        "module property_harness;",
        "    (* gclk *) reg formal_clock;",
        f"    reg {clock} = 1'b0;",
        f"    always @(posedge formal_clock)",
        f"        {clock} <= !{clock};",
        "",
    ]

    for name in formal_inputs:
        lines.append(
            f"    (* anyseq *) reg "
            f"{signal_range(name)}{name};"
        )

    lines.append("")

    for name in outputs:
        lines.append(
            f"    wire {signal_range(name)}{name};"
        )

    ports = [
        clock,
        *formal_inputs,
        *outputs,
    ]

    lines.extend([
        "",
        "    `DUT_MODULE dut (",
        "        "
        + ", ".join(
            f".{name}({name})"
            for name in ports
        ),
        "    );",
        "",
        "    reg f_past_valid = 1'b0;",
        "",
        f"    always @(posedge {clock}) begin",
        "        if (!f_past_valid)",
        f"            assume({reset});",
        "",
        "        if (f_past_valid) begin",
    ])

    for prop in properties:
        if prop["type"] == "invariant":
            if prop.get("disable"):
                lines.append(
                    f"            if (!{prop['disable']}) "
                    f"assert({prop['expression']}); "
                    f"// {prop['id']}"
                )
            else:
                lines.append(
                    f"            assert("
                    f"{prop['expression']}); "
                    f"// {prop['id']}"
                )

        elif prop["type"] == "next_cycle_implication":
            antecedent = pastify(
                prop["antecedent"]
            )

            guard = ""

            if prop.get("disable"):
                disable = prop["disable"]
                guard = (
                    f"!$past({disable}) && "
                    f"!{disable} && "
                )

            lines.append(
                f"            if ({guard}"
                f"({antecedent})) "
                f"assert({prop['consequent']}); "
                f"// {prop['id']}"
            )
        else:
            raise ValueError(
                f"Unsupported property type: "
                f"{prop['type']}"
            )

    lines.extend([
        "        end",
        "",
        "        f_past_valid <= 1'b1;",
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        "        if (f_past_valid) begin",
    ])

    seen = set()

    for prop in properties:
        if prop["type"] != "next_cycle_implication":
            continue

        antecedent = prop["antecedent"]

        if prop.get("disable"):
            condition = (
                f"!{prop['disable']} && "
                f"({antecedent})"
            )
        else:
            condition = antecedent

        if condition in seen:
            continue

        seen.add(condition)

        lines.append(
            f"            cover({condition}); "
            f"// {prop['id']}"
        )

    lines.extend([
        "        end",
        "    end",
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_sva():
    lines = []

    for prop in properties:
        lines.append(
            f"// {prop['id']}: "
            f"{prop['natural_language']}"
        )
        lines.append(
            f"property {prop['sva_name']};"
        )

        prefix = f"    @(posedge {clock}) "

        if prop.get("disable"):
            prefix += (
                f"disable iff ({prop['disable']}) "
            )

        if prop["type"] == "invariant":
            body = f"({prop['expression']});"
        else:
            body = (
                f"({prop['antecedent']}) "
                f"|=> ({prop['consequent']});"
            )

        lines.append(prefix + body)
        lines.append("endproperty")
        lines.append(
            f"assert property "
            f"({prop['sva_name']});"
        )
        lines.append("")

    return "\n".join(lines)


(DATA / "rtl" / "canonical_next.sv").write_text(
    render_canonical()
)

(DATA / "rtl" / "sequential_priority.sv").write_text(
    render_sequential()
)

(DATA / "rtl" / "ternary_next.sv").write_text(
    render_ternary()
)

(DATA / "rtl" / "function_update.sv").write_text(
    render_function()
)

for mutation in mutants:
    rules = effective_rules(mutation)

    module_name = (
        f"{design_id}_mutant_{mutation['name']}"
    )

    (
        DATA
        / "mutants"
        / f"{mutation['name']}.sv"
    ).write_text(
        render_sequential(
            rules=rules,
            module_name=module_name,
        )
    )

(DATA / "properties" / "properties.json").write_text(
    json.dumps(properties, indent=2) + "\n"
)

(DATA / "properties" / "properties.sva").write_text(
    render_sva()
)

(GENERATED / "property_harness.sv").write_text(
    render_property_harness()
)

print(f"Generated multi-register family {design_id}")
