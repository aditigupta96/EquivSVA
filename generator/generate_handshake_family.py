#!/usr/bin/env python3

import json
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "dataset" / "handshake_0001"
SPEC_PATH = DATA / "spec.json"
FORMAL = ROOT / "formal"

spec = json.loads(SPEC_PATH.read_text())

states = spec["states"]
inputs = spec["inputs"]
outputs = spec["outputs"]
reset = spec["reset"]["name"]
clock = spec["clock"]["name"]
state_outputs = spec["state_outputs"]
transitions = spec["transitions"]
properties = spec["properties"]

for directory in [
    DATA / "rtl",
    DATA / "properties",
    DATA / "mutants",
    FORMAL,
]:
    directory.mkdir(parents=True, exist_ok=True)


def transitions_from(state):
    return [t for t in transitions if t["from"] == state]


def bit_width(n):
    return max(1, math.ceil(math.log2(n)))


def port_lines(output_kind="reg"):
    lines = [
        f"    input  wire {clock},",
        f"    input  wire {reset},",
    ]

    for signal in inputs:
        lines.append(f"    input  wire {signal},")

    for i, signal in enumerate(outputs):
        comma = "," if i < len(outputs) - 1 else ""
        lines.append(
            f"    output {output_kind:<4} {signal}{comma}"
        )

    return "\n".join(lines)


def binary_codes():
    width = bit_width(len(states))
    codes = {state: i for i, state in enumerate(states)}
    return width, codes


def render_output_logic(state_var, names):
    lines = [
        "    always @* begin"
    ]

    for output in outputs:
        lines.append(f"        {output} = 1'b0;")

    lines.append(f"        case ({state_var})")

    for state in states:
        lines.append(f"            {names[state]}: begin")

        for output, value in state_outputs[state].items():
            lines.append(
                f"                {output} = 1'b{int(value)};"
            )

        lines.append("            end")

    lines.extend([
        "            default: begin end",
        "        endcase",
        "    end",
    ])

    return "\n".join(lines)


def render_canonical(
    module="handshake_canonical_case",
    mutation=None
):
    width, codes = binary_codes()

    lines = [
        f"module {module} (",
        port_lines("reg"),
        ");",
    ]

    for state in states:
        lines.append(
            f"    localparam [{width-1}:0] "
            f"{state:<5} = {width}'d{codes[state]};"
        )

    lines.extend([
        "",
        f"    reg [{width-1}:0] state, next_state;",
        "",
        "    always @* begin",
        "        next_state = state;",
        "        case (state)",
    ])

    for state in states:
        lines.append(f"            {state}: begin")

        state_transitions = transitions_from(state)

        if (
            mutation
            and mutation["kind"] == "force_transition"
            and mutation["from"] == state
        ):
            lines.append(
                f"                next_state = {mutation['to']};"
            )

        else:
            changed = []

            for transition in state_transitions:
                transition = dict(transition)

                if (
                    mutation
                    and mutation["kind"]
                    == "replace_transition_guard"
                    and mutation["from"] == state
                    and transition["when"] == mutation["old"]
                ):
                    transition["when"] = mutation["new"]

                changed.append(transition)

            if (
                len(changed) == 1
                and changed[0]["when"] == "true"
            ):
                lines.append(
                    f"                next_state = "
                    f"{changed[0]['to']};"
                )

            elif changed:
                lines.append(
                    f"                if ({changed[0]['when']})"
                )
                lines.append(
                    f"                    next_state = "
                    f"{changed[0]['to']};"
                )

                if len(changed) > 1:
                    lines.append("                else")
                    lines.append(
                        f"                    next_state = "
                        f"{changed[1]['to']};"
                    )

        lines.append("            end")

    reset_state = spec["reset"]["state"]

    lines.extend([
        f"            default: next_state = {reset_state};",
        "        endcase",
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            state <= {reset_state};",
        "        else",
        "            state <= next_state;",
        "    end",
        "",
    ])

    names = {state: state for state in states}

    lines.append(render_output_logic("state", names))

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_onehot():
    n = len(states)

    lines = [
        "module handshake_onehot_case (",
        port_lines("reg"),
        ");",
    ]

    for index, state in enumerate(states):
        bits = ["0"] * n
        bits[index] = "1"
        encoding = "".join(reversed(bits))

        lines.append(
            f"    localparam [{n-1}:0] "
            f"{state:<5} = {n}'b{encoding};"
        )

    lines.extend([
        "",
        f"    reg [{n-1}:0] state, next_state;",
        "",
        "    always @* begin",
        f"        next_state = {spec['reset']['state']};",
        "        case (state)",
    ])

    for state in states:
        ts = transitions_from(state)

        if len(ts) == 1 and ts[0]["when"] == "true":
            expression = ts[0]["to"]

        elif len(ts) >= 2:
            expression = (
                f"({ts[0]['when']}) ? "
                f"{ts[0]['to']} : {ts[1]['to']}"
            )

        else:
            expression = spec["reset"]["state"]

        lines.append(
            f"            {state}: next_state = {expression};"
        )

    lines.extend([
        f"            default: "
        f"next_state = {spec['reset']['state']};",
        "        endcase",
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            state <= {spec['reset']['state']};",
        "        else",
        "            state <= next_state;",
        "    end",
        "",
        "    always @* begin",
    ])

    for output in outputs:
        terms = [
            f"(state == {state})"
            for state in states
            if state_outputs[state].get(output, 0)
        ]

        expression = " || ".join(terms) if terms else "1'b0"

        lines.append(
            f"        {output} = {expression};"
        )

    lines.extend([
        "    end",
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_nested_if():
    width, codes = binary_codes()
    names = {
        state: f"S_{state}"
        for state in states
    }

    lines = [
        "module handshake_nested_if (",
        port_lines("wire"),
        ");",
    ]

    for state in states:
        lines.append(
            f"    localparam [{width-1}:0] "
            f"{names[state]:<8} = {width}'d{codes[state]};"
        )

    lines.extend([
        "",
        f"    reg [{width-1}:0] state;",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset}) begin",
        f"            state <= "
        f"{names[spec['reset']['state']]};",
        "        end else begin",
    ])

    for index, state in enumerate(states):
        keyword = "if" if index == 0 else "else if"

        lines.append(
            f"            {keyword} "
            f"(state == {names[state]}) begin"
        )

        ts = transitions_from(state)

        if len(ts) == 1 and ts[0]["when"] == "true":
            lines.append(
                f"                state <= "
                f"{names[ts[0]['to']]};"
            )

        elif len(ts) >= 2:
            lines.append(
                f"                if ({ts[0]['when']})"
            )
            lines.append(
                f"                    state <= "
                f"{names[ts[0]['to']]};"
            )
            lines.append(
                "                else"
            )
            lines.append(
                f"                    state <= "
                f"{names[ts[1]['to']]};"
            )

        lines.append("            end")

    lines.extend([
        "            else begin",
        f"                state <= "
        f"{names[spec['reset']['state']]};",
        "            end",
        "        end",
        "    end",
        "",
    ])

    for output in outputs:
        terms = [
            f"(state == {names[state]})"
            for state in states
            if state_outputs[state].get(output, 0)
        ]

        expression = " || ".join(terms) if terms else "1'b0"

        lines.append(
            f"    assign {output} = {expression};"
        )

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_factored():
    accept_condition = transitions_from("IDLE")[0]["when"]
    cancel_condition = transitions_from("WAIT")[0]["when"]

    return f"""module handshake_factored_flags (
{port_lines("wire")}
);
    reg active;
    reg acknowledge;

    wire accept = {accept_condition};
    wire idle   = !active && !acknowledge;

    always @(posedge {clock}) begin
        if ({reset}) begin
            active      <= 1'b0;
            acknowledge <= 1'b0;
        end else if (idle) begin
            active      <= accept;
            acknowledge <= 1'b0;
        end else if (active) begin
            active      <= 1'b0;
            acknowledge <= !({cancel_condition});
        end else begin
            active      <= 1'b0;
            acknowledge <= 1'b0;
        end
    end

    assign busy = active;
    assign ack  = acknowledge;
endmodule
"""


def render_properties_json():
    cleaned = []

    for prop in properties:
        cleaned.append({
            key: value
            for key, value in prop.items()
            if key != "sva_name"
        })

    return json.dumps(cleaned, indent=2) + "\n"


def render_sva():
    lines = [
        "// Generated from spec.json.",
        f"// Design: {spec['design_id']}",
        "",
    ]

    for prop in properties:
        lines.append(
            f"// {prop['id']}: "
            f"{prop['natural_language']}."
        )

        if prop["type"] == "invariant":
            disable = (
                f" disable iff ({prop['disable']})"
                if prop.get("disable")
                else ""
            )

            lines.extend([
                f"{prop['sva_name']}: assert property "
                f"(@(posedge {clock}){disable}",
                f"    {prop['expression']});",
                "",
            ])

        elif prop["type"] == "next_cycle_implication":
            disable = (
                f" disable iff ({prop['disable']})"
                if prop.get("disable")
                else ""
            )

            lines.extend([
                f"{prop['sva_name']}: assert property "
                f"(@(posedge {clock}){disable}",
                f"    ({prop['antecedent']}) "
                f"|=> ({prop['consequent']}));",
                "",
            ])

    return "\n".join(lines)


def pastify(expression):
    signals = [reset] + inputs + outputs
    result = expression

    for signal in sorted(
        set(signals),
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
        "    always @(posedge formal_clock)",
        f"        {clock} <= !{clock};",
    ]

    for signal in formal_inputs:
        lines.append(
            f"    (* anyseq *) reg {signal};"
        )

    lines.append("")

    for signal in outputs:
        lines.append(f"    wire {signal};")

    lines.extend([
        "",
        "    `DUT_MODULE dut (",
    ])

    ports = [clock] + formal_inputs + outputs

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

        if prop["type"] == "invariant":

            if prop.get("disable"):
                lines.append(
                    f"            if (!{prop['disable']}) "
                    f"assert({prop['expression']}); "
                    f"// {prop['id']}"
                )
            else:
                lines.append(
                    f"            assert({prop['expression']}); "
                    f"// {prop['id']}"
                )

        elif prop["type"] == "next_cycle_implication":

            antecedent = pastify(prop["antecedent"])
            consequent = prop["consequent"]

            guard = ""

            if prop.get("disable"):
                disable = prop["disable"]
                guard = (
                    f"!$past({disable}) && "
                    f"!{disable} && "
                )

            lines.append(
                f"            if ({guard}({antecedent})) "
                f"assert({consequent}); "
                f"// {prop['id']}"
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
                f"!{prop['disable']} && ({antecedent})"
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


# ------------------------------------------------------------
# Generate equivalent RTL implementations.
# ------------------------------------------------------------

(DATA / "rtl" / "canonical_case.sv").write_text(
    render_canonical()
)

(DATA / "rtl" / "onehot_case.sv").write_text(
    render_onehot()
)

(DATA / "rtl" / "nested_if.sv").write_text(
    render_nested_if()
)

(DATA / "rtl" / "factored_flags.sv").write_text(
    render_factored()
)


# ------------------------------------------------------------
# Generate properties.
# ------------------------------------------------------------

(DATA / "properties" / "properties.json").write_text(
    render_properties_json()
)

(DATA / "properties" / "properties.sva").write_text(
    render_sva()
)

FORMAL.joinpath("property_harness.sv").write_text(
    render_property_harness()
)


# ------------------------------------------------------------
# Generate controlled mutants.
# ------------------------------------------------------------

module_names = {
    "ignore_ready":
        "handshake_mutant_ignore_ready",

    "cancel_to_ack":
        "handshake_mutant_cancel_to_ack",

    "ack_stuck":
        "handshake_mutant_ack_stuck",
}

for mutant in spec["mutants"]:

    path = (
        DATA
        / "mutants"
        / f"{mutant['name']}.sv"
    )

    path.write_text(
        render_canonical(
            module=module_names[mutant["name"]],
            mutation=mutant,
        )
    )


print(
    f"Generated {spec['design_id']} from "
    f"{SPEC_PATH}"
)
