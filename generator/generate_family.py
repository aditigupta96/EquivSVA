#!/usr/bin/env python3

import argparse
import json
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser(
    description="Generate an EquivSVA family from a BehaviorSpec."
)
parser.add_argument(
    "--spec",
    required=True,
    help="Path to the family's spec.json"
)
args = parser.parse_args()

SPEC_PATH = Path(args.spec).resolve()
if not SPEC_PATH.exists():
    raise SystemExit(f"Spec not found: {SPEC_PATH}")

DATA = SPEC_PATH.parent

spec = json.loads(SPEC_PATH.read_text())

design_id = spec["design_id"]
GENERATED = ROOT / "build" / "generated" / design_id
module_prefix = design_id

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
    GENERATED,
]:
    directory.mkdir(parents=True, exist_ok=True)


def transitions_from(state):
    return [t for t in transitions if t["from"] == state]


def effective_transitions(state, mutation=None):
    """
    Return ordered transitions for a state after applying an
    optional controlled mutation.
    """
    if (
        mutation
        and mutation["kind"] == "force_transition"
        and mutation["from"] == state
    ):
        return [{
            "from": state,
            "when": "true",
            "to": mutation["to"],
        }]

    result = []

    for transition in transitions_from(state):
        transition = dict(transition)

        if (
            mutation
            and mutation["kind"] == "replace_transition_guard"
            and mutation["from"] == state
            and transition["when"] == mutation["old"]
        ):
            transition["when"] = mutation["new"]

        result.append(transition)

    return result


def transition_expression(
    state_transitions,
    fallback_state,
    names,
):
    """
    Convert ordered transitions into a priority expression.

    For:
        req0 -> G0
        req1 -> G1
        true -> IDLE

    this produces:
        (req0) ? G0 : ((req1) ? G1 : IDLE)
    """
    expression = names[fallback_state]

    for transition in reversed(state_transitions):
        condition = transition["when"].strip()
        destination = names[transition["to"]]

        if condition == "true":
            expression = destination
        elif condition == "false":
            continue
        else:
            expression = (
                f"({condition}) ? "
                f"{destination} : ({expression})"
            )

    return expression


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
    module=None,
    mutation=None
):
    if module is None:
        module = f"{module_prefix}_canonical_case"

    width, codes = binary_codes()
    names = {state: state for state in states}

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
        state_transitions = effective_transitions(
            state,
            mutation=mutation,
        )

        expression = transition_expression(
            state_transitions,
            state,
            names,
        )

        lines.append(
            f"            {state}: "
            f"next_state = {expression};"
        )

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

    lines.append(
        render_output_logic("state", names)
    )

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_onehot():
    n = len(states)

    names = {
        state: state
        for state in states
    }

    lines = [
        f"module {module_prefix}_onehot_case (",
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
        expression = transition_expression(
            transitions_from(state),
            state,
            names,
        )

        lines.append(
            f"            {state}: "
            f"next_state = {expression};"
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

        expression = (
            " || ".join(terms)
            if terms
            else "1'b0"
        )

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
        f"module {module_prefix}_nested_if (",
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
        keyword = (
            "if"
            if index == 0
            else "else if"
        )

        expression = transition_expression(
            transitions_from(state),
            state,
            names,
        )

        lines.append(
            f"            {keyword} "
            f"(state == {names[state]}) begin"
        )

        lines.append(
            f"                state <= {expression};"
        )

        lines.append(
            "            end"
        )

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

        expression = (
            " || ".join(terms)
            if terms
            else "1'b0"
        )

        lines.append(
            f"    assign {output} = {expression};"
        )

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


def render_factored():
    """
    Generic factored FSM representation.

    The behavior is identical to the canonical FSM, but transition
    predicates are pulled into separate wires. This creates a
    structurally different RTL implementation without changing
    observable behavior.
    """
    width, codes = binary_codes()

    names = {
        state: f"F_{state}"
        for state in states
    }

    lines = [
        f"module {module_prefix}_factored_flags (",
        port_lines("reg"),
        ");",
    ]

    for state in states:
        lines.append(
            f"    localparam [{width-1}:0] "
            f"{names[state]:<14} = {width}'d{codes[state]};"
        )

    lines.extend([
        "",
        f"    reg [{width-1}:0] state, next_state;",
        "",
    ])

    guard_names = {}

    for state in states:
        ts = transitions_from(state)

        for index, transition in enumerate(ts):

            if transition["when"] == "true":
                continue

            guard = (
                f"guard_{state.lower()}_{index}"
            )

            guard_names[(state, index)] = guard

            lines.append(
                f"    wire {guard} = "
                f"({transition['when']});"
            )

    lines.extend([
        "",
        "    always @* begin",
        "        next_state = state;",
        "        case (state)",
    ])

    for state in states:

        lines.append(
            f"            {names[state]}: begin"
        )

        ts = transitions_from(state)
        first = True

        for index, transition in enumerate(ts):

            destination = names[transition["to"]]
            condition = transition["when"]

            if condition == "true":

                if first:
                    lines.append(
                        f"                "
                        f"next_state = {destination};"
                    )
                else:
                    lines.append(
                        "                else"
                    )
                    lines.append(
                        f"                    "
                        f"next_state = {destination};"
                    )

                break

            guard = guard_names[(state, index)]
            keyword = "if" if first else "else if"

            lines.append(
                f"                {keyword} "
                f"({guard})"
            )

            lines.append(
                f"                    "
                f"next_state = {destination};"
            )

            first = False

        lines.append(
            "            end"
        )

    lines.extend([
        f"            default: "
        f"next_state = {names[spec['reset']['state']]};",
        "        endcase",
        "    end",
        "",
        f"    always @(posedge {clock}) begin",
        f"        if ({reset})",
        f"            state <= "
        f"{names[spec['reset']['state']]};",
        "        else",
        "            state <= next_state;",
        "    end",
        "",
    ])

    lines.append(
        render_output_logic(
            "state",
            names
        )
    )

    lines.extend([
        "endmodule",
        "",
    ])

    return "\n".join(lines)


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

GENERATED.joinpath("property_harness.sv").write_text(
    render_property_harness()
)


# ------------------------------------------------------------
# Generate controlled mutants.
# ------------------------------------------------------------

# Mutants are generated entirely from spec.json. Remove stale
# generated mutant files so this directory always matches the spec.
for stale_mutant in (DATA / "mutants").glob("*.sv"):
    stale_mutant.unlink()

module_names = {
    mutant["name"]:
        f"{module_prefix}_mutant_{mutant['name']}"
    for mutant in spec["mutants"]
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
