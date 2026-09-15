#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser(
    description="Generate an EquivSVA register-rule family."
)
parser.add_argument(
    "--spec",
    required=True,
    help="Path to the family's spec.json",
)
args = parser.parse_args()

SPEC_PATH = Path(args.spec).resolve()

if not SPEC_PATH.exists():
    raise SystemExit(f"Spec not found: {SPEC_PATH}")

DATA = SPEC_PATH.parent
spec = json.loads(SPEC_PATH.read_text())

if spec.get("model_type") != "register_rules":
    raise SystemExit(
        "generate_register_family.py requires "
        'model_type == "register_rules"'
    )

design_id = spec["design_id"]
module_prefix = design_id

clock = spec["clock"]["name"]
reset = spec["reset"]["name"]

inputs = spec["inputs"]
outputs = spec["outputs"]

registers = spec["registers"]

if len(registers) != 1:
    raise SystemExit(
        "Initial register_rules generator supports exactly "
        "one state register."
    )

register = registers[0]

reg_name = register["name"]
reg_width = int(register["width"])
reg_reset = register["reset_value"]

if reg_width < 1:
    raise SystemExit("Register width must be >= 1.")

if reg_name not in outputs:
    raise SystemExit(
        f"State register {reg_name} must be interface-visible."
    )

signal_widths = dict(spec.get("signal_widths", {}))
signal_widths[reg_name] = reg_width

derived_outputs = spec.get("derived_outputs", {})
update_rules = spec["update_rules"]
properties = spec["properties"]
mutants = spec.get("mutants", [])

GENERATED = ROOT / "build" / "generated" / design_id

for directory in [
    DATA / "rtl",
    DATA / "properties",
    DATA / "mutants",
    GENERATED,
]:
    directory.mkdir(parents=True, exist_ok=True)

# Generated artifacts should exactly reflect the current spec.
for stale in (DATA / "rtl").glob("*.sv"):
    stale.unlink()

for stale in (DATA / "mutants").glob("*.sv"):
    stale.unlink()


def signal_range(signal):
    width = int(signal_widths.get(signal, 1))

    if width < 1:
        raise ValueError(
            f"Invalid signal width for {signal}: {width}"
        )

    if width == 1:
        return ""

    return f"[{width - 1}:0] "


def register_range():
    if reg_width == 1:
        return ""

    return f"[{reg_width - 1}:0] "


def replace_register(expression, replacement):
    return re.sub(
        rf"\b{re.escape(reg_name)}\b",
        replacement,
        expression,
    )


def port_lines():
    ports = [
        ("input", "wire", clock),
        ("input", "wire", reset),
    ]

    for signal in inputs:
        ports.append(("input", "wire", signal))

    for signal in outputs:
        kind = "reg" if signal == reg_name else "wire"
        ports.append(("output", kind, signal))

    lines = []

    for index, (direction, kind, signal) in enumerate(ports):
        comma = "," if index < len(ports) - 1 else ""
        width = signal_range(signal)

        lines.append(
            f"    {direction:<6} {kind:<4} "
            f"{width}{signal}{comma}"
        )

    return "\n".join(lines)


def render_derived_outputs():
    lines = []

    for signal, expression in derived_outputs.items():
        lines.append(
            f"    assign {signal} = {expression};"
        )

    return lines


def effective_rules(mutation=None):
    result = [
        dict(rule)
        for rule in update_rules
    ]

    if mutation is None:
        return result

    kind = mutation["kind"]

    if kind == "replace_update_guard":
        found = False

        for rule in result:
            if rule["when"] == mutation["old"]:
                rule["when"] = mutation["new"]
                found = True
                break

        if not found:
            raise ValueError(
                f"Mutation {mutation['name']} could not find "
                f"guard {mutation['old']!r}"
            )

    elif kind == "replace_update_value":
        found = False

        for rule in result:
            if (
                rule["when"] == mutation["when"]
                and rule["value"] == mutation["old"]
            ):
                rule["value"] = mutation["new"]
                found = True
                break

        if not found:
            raise ValueError(
                f"Mutation {mutation['name']} could not find "
                "matching update value."
            )

    elif kind == "insert_update_rule":
        inserted = False

        new_rule = {
            "when": mutation["when"],
            "value": mutation["value"],
        }

        for index, rule in enumerate(result):
            if rule["when"] == mutation["before"]:
                result.insert(index, new_rule)
                inserted = True
                break

        if not inserted:
            raise ValueError(
                f"Mutation {mutation['name']} could not find "
                f"insertion point {mutation['before']!r}"
            )

    else:
        raise ValueError(
            f"Unsupported mutation kind: {kind}"
        )

    return result


def emit_priority_assignments(
    target,
    rules,
    operator,
    indent,
    register_replacement=None,
):
    lines = []
    emitted_condition = False

    for rule in rules:
        condition = rule["when"].strip()
        value = rule["value"].strip()

        if register_replacement is not None:
            condition = replace_register(
                condition,
                register_replacement,
            )
            value = replace_register(
                value,
                register_replacement,
            )

        if condition == "false":
            continue

        if condition == "true":
            if emitted_condition:
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

        keyword = "if" if not emitted_condition else "else if"

        lines.append(
            f"{indent}{keyword} ({condition}) "
            f"{target} {operator} {value};"
        )

        emitted_condition = True

    # Defensive fallback when a spec omits a true rule.
    fallback = (
        register_replacement
        if register_replacement is not None
        else reg_name
    )

    if emitted_condition:
        lines.append(
            f"{indent}else "
            f"{target} {operator} {fallback};"
        )
    else:
        lines.append(
            f"{indent}{target} {operator} {fallback};"
        )

    return lines


def priority_expression(rules):
    expression = reg_name

    for rule in reversed(rules):
        condition = rule["when"].strip()
        value = rule["value"].strip()

        if condition == "false":
            continue

        if condition == "true":
            expression = value
        else:
            expression = (
                f"({condition}) ? ({value}) : "
                f"({expression})"
            )

    return expression


def render_canonical(rules=None, module_name=None):
    if rules is None:
        rules = update_rules

    if module_name is None:
        module_name = (
            f"{module_prefix}_canonical_next"
        )

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
        f"    reg {register_range()}next_{reg_name};",
        "",
        "    always @* begin",
    ]

    lines.extend(
        emit_priority_assignments(
            f"next_{reg_name}",
            rules,
            "=",
            "        ",
        )
    )

    lines.extend([
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            {reg_name} <= {reg_reset};",
        "        else",
        f"            {reg_name} <= next_{reg_name};",
        "    end",
        "",
    ])

    lines.extend(render_derived_outputs())

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_sequential(
    rules=None,
    module_name=None,
):
    if rules is None:
        rules = update_rules

    if module_name is None:
        module_name = (
            f"{module_prefix}_sequential_priority"
        )

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
        f"            {reg_name} <= {reg_reset};",
        "        end",
        "        else begin",
    ]

    lines.extend(
        emit_priority_assignments(
            reg_name,
            rules,
            "<=",
            "            ",
        )
    )

    lines.extend([
        "        end",
        "    end",
        "",
    ])

    lines.extend(render_derived_outputs())

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_ternary():
    expression = priority_expression(
        update_rules
    )

    module_name = (
        f"{module_prefix}_ternary_next"
    )

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
        f"    wire {register_range()}next_{reg_name};",
        "",
        f"    assign next_{reg_name} = {expression};",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            {reg_name} <= {reg_reset};",
        "        else",
        f"            {reg_name} <= next_{reg_name};",
        "    end",
        "",
    ]

    lines.extend(render_derived_outputs())

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_function():
    module_name = (
        f"{module_prefix}_function_update"
    )

    function_name = f"compute_next_{reg_name}"

    lines = [
        f"module {module_name} (",
        port_lines(),
        ");",
        "",
        f"    function automatic "
        f"{register_range()}{function_name};",
        f"        input {register_range()}current;",
    ]

    for signal in inputs:
        lines.append(
            f"        input {signal_range(signal)}{signal};"
        )

    lines.append("        begin")

    lines.extend(
        emit_priority_assignments(
            function_name,
            update_rules,
            "=",
            "            ",
            register_replacement="current",
        )
    )

    lines.extend([
        "        end",
        "    endfunction",
        "",
        f"    wire {register_range()}next_{reg_name};",
        "",
        f"    assign next_{reg_name} = "
        f"{function_name}("
        + ", ".join([reg_name] + inputs)
        + ");",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            {reg_name} <= {reg_reset};",
        "        else",
        f"            {reg_name} <= next_{reg_name};",
        "    end",
        "",
    ])

    lines.extend(render_derived_outputs())

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def pastify(expression):
    result = expression

    signals = [
        reset,
        *inputs,
        *outputs,
    ]

    for signal in sorted(
        signals,
        key=len,
        reverse=True,
    ):
        result = re.sub(
            rf"\b{re.escape(signal)}\b",
            f"$past({signal})",
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
        "",
        "    always @(posedge formal_clock)",
        f"        {clock} <= !{clock};",
        "",
    ]

    for signal in formal_inputs:
        lines.append(
            f"    (* anyseq *) reg "
            f"{signal_range(signal)}{signal};"
        )

    lines.append("")

    for signal in outputs:
        lines.append(
            f"    wire {signal_range(signal)}{signal};"
        )

    lines.extend([
        "",
        "    `DUT_MODULE dut (",
    ])

    ports = [
        clock,
        *formal_inputs,
        *outputs,
    ]

    lines.append(
        "        "
        + ", ".join(
            f".{signal}({signal})"
            for signal in ports
        )
    )

    lines.extend([
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
        prop_type = prop["type"]

        if prop_type == "invariant":
            expression = prop["expression"]

            if prop.get("disable"):
                lines.append(
                    f"            if (!{prop['disable']}) "
                    f"assert({expression}); "
                    f"// {prop['id']}"
                )
            else:
                lines.append(
                    f"            assert({expression}); "
                    f"// {prop['id']}"
                )

        elif prop_type == "next_cycle_implication":
            if prop.get("delay", 1) != 1:
                raise ValueError(
                    "register_rules currently supports "
                    "delay == 1 only."
                )

            antecedent = pastify(
                prop["antecedent"]
            )
            consequent = prop["consequent"]

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
                f"assert({consequent}); "
                f"// {prop['id']}"
            )

        else:
            raise ValueError(
                f"Unsupported property type: {prop_type}"
            )

    lines.extend([
        "        end",
        "",
        "        f_past_valid <= 1'b1;",
        "    end",
        "",
        "    // Reachability/non-vacuity witnesses.",
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
    lines = [
        f"// Gold interface properties for {design_id}",
        "",
    ]

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
        elif prop["type"] == "next_cycle_implication":
            body = (
                f"({prop['antecedent']}) "
                f"|=> ({prop['consequent']});"
            )
        else:
            raise ValueError(
                f"Unsupported property type: "
                f"{prop['type']}"
            )

        lines.append(prefix + body)
        lines.append("endproperty")
        lines.append(
            f"assert property "
            f"({prop['sva_name']});"
        )
        lines.append("")

    return "\n".join(lines)


# Four equivalent RTL structures.
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

# Controlled mutants.
for mutation in mutants:
    mutant_rules = effective_rules(mutation)

    module_name = (
        f"{module_prefix}_mutant_"
        f"{mutation['name']}"
    )

    path = (
        DATA
        / "mutants"
        / f"{mutation['name']}.sv"
    )

    path.write_text(
        render_sequential(
            rules=mutant_rules,
            module_name=module_name,
        )
    )

# Benchmark-facing properties.
(DATA / "properties" / "properties.json").write_text(
    json.dumps(properties, indent=2) + "\n"
)

(DATA / "properties" / "properties.sva").write_text(
    render_sva()
)

# OSS formal harness.
(GENERATED / "property_harness.sv").write_text(
    render_property_harness()
)

print(
    f"Generated register-rule family {design_id} "
    f"from {SPEC_PATH}"
)
