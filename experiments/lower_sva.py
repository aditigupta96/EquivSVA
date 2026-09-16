#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path


PROPERTY_RE = re.compile(
    r"""
    property\s+
    (?P<name>[A-Za-z_][A-Za-z0-9_$]*)
    \s*;
    (?P<body>.*?)
    endproperty
    """,
    re.DOTALL | re.VERBOSE,
)


def clean_expr(expr):
    return re.sub(r"\s+", " ", expr).strip()


def parens_balanced(text):
    depth = 0

    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1

            if depth < 0:
                return False

    return depth == 0


def strip_outer_parens(text):
    text = clean_expr(text)

    while (
        len(text) >= 2
        and text[0] == "("
        and text[-1] == ")"
    ):
        depth = 0
        wraps_all = True

        for i, ch in enumerate(text):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1

                if depth == 0 and i != len(text) - 1:
                    wraps_all = False
                    break

        if not wraps_all or depth != 0:
            break

        text = clean_expr(text[1:-1])

    return text


def expression_supported(expr):
    if not parens_balanced(expr):
        return False, "unbalanced parentheses"

    forbidden = [
        r"\bbegin\b",
        r"\bend\b",
        r"\bthroughout\b",
        r"\bwithin\b",
        r"\bintersect\b",
        r"\buntil\b",
        r"\bs_until\b",
        r"\bfirst_match\b",
        r"\[\*",
        r"\[=",
        r"\[->",
        r"##",
    ]

    for pattern in forbidden:
        if re.search(pattern, expr):
            return False, f"unsupported expression construct: {pattern}"

    return True, None


def parse_property(name, text):
    text = clean_expr(text)

    m = re.match(
        r"""
        @\(\s*posedge\s+
        (?P<clock>[A-Za-z_][A-Za-z0-9_$]*)
        \s*\)
        \s*
        (?:
            disable\s+iff\s*
            \(
                (?P<disable>[^()]*(?:\([^()]*\)[^()]*)*)
            \)
        )?
        \s*
        (?P<body>.*)
        ;
        \s*$
        """,
        text,
        re.VERBOSE,
    )

    if not m:
        return {
            "name": name,
            "supported": False,
            "reason": "unsupported property header/body structure",
        }

    clock = m.group("clock")
    disable = clean_expr(m.group("disable") or "1'b0")
    body = strip_outer_parens(m.group("body"))

    if body.count("|->") + body.count("|=>") > 1:
        return {
            "name": name,
            "supported": False,
            "reason": "multiple implication operators unsupported",
        }

    if "|->" in body:
        antecedent, consequent = body.split("|->", 1)

        antecedent = strip_outer_parens(antecedent)
        consequent = clean_expr(consequent)

        delay = 0

        dm = re.match(
            r"^##\s*(\d+)\s+(.*)$",
            consequent,
        )

        if dm:
            delay = int(dm.group(1))
            consequent = dm.group(2)

        consequent = strip_outer_parens(consequent)

        if delay not in (0, 1):
            return {
                "name": name,
                "supported": False,
                "reason": f"unsupported delay ##{delay}",
            }

        for label, expr in (
            ("antecedent", antecedent),
            ("consequent", consequent),
            ("disable", disable),
        ):
            ok, reason = expression_supported(expr)

            if not ok:
                return {
                    "name": name,
                    "supported": False,
                    "reason": f"{label}: {reason}",
                }

        return {
            "name": name,
            "supported": True,
            "clock": clock,
            "disable": disable,
            "kind": "implication",
            "delay": delay,
            "antecedent": antecedent,
            "consequent": consequent,
        }

    if "|=>" in body:
        antecedent, consequent = body.split("|=>", 1)

        antecedent = strip_outer_parens(antecedent)
        consequent = strip_outer_parens(consequent)

        for label, expr in (
            ("antecedent", antecedent),
            ("consequent", consequent),
            ("disable", disable),
        ):
            ok, reason = expression_supported(expr)

            if not ok:
                return {
                    "name": name,
                    "supported": False,
                    "reason": f"{label}: {reason}",
                }

        return {
            "name": name,
            "supported": True,
            "clock": clock,
            "disable": disable,
            "kind": "implication",
            "delay": 1,
            "antecedent": antecedent,
            "consequent": consequent,
        }

    body = strip_outer_parens(body)

    ok, reason = expression_supported(body)

    if not ok:
        return {
            "name": name,
            "supported": False,
            "reason": reason,
        }

    return {
        "name": name,
        "supported": True,
        "clock": clock,
        "disable": disable,
        "kind": "invariant",
        "expression": body,
    }


def find_matching_paren(text, start):
    depth = 0

    for i in range(start, len(text)):
        ch = text[i]

        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1

            if depth == 0:
                return i

    return None


def extract_assertions(text):
    definitions = {}

    for m in PROPERTY_RE.finditer(text):
        name = m.group("name")
        definitions[name] = parse_property(
            name,
            m.group("body"),
        )

    start_re = re.compile(
        r"""
        (?:
            (?P<label>[A-Za-z_][A-Za-z0-9_$]*)
            \s*:\s*
        )?
        assert\s+property\s*
        \(
        """,
        re.VERBOSE,
    )

    assertions = []

    for index, m in enumerate(start_re.finditer(text), start=1):
        open_pos = m.end() - 1
        close_pos = find_matching_paren(text, open_pos)

        if close_pos is None:
            assertions.append({
                "name": m.group("label") or f"inline_{index}",
                "source_kind": "inline",
                "supported": False,
                "reason": "unterminated assert property parentheses",
            })
            continue

        content = clean_expr(
            text[open_pos + 1:close_pos]
        )

        label = m.group("label")

        if re.fullmatch(
            r"[A-Za-z_][A-Za-z0-9_$]*",
            content,
        ):
            name = content
            prop = definitions.get(name)

            if prop is None:
                prop = {
                    "name": name,
                    "supported": False,
                    "reason": "property definition not found",
                }
            else:
                prop = dict(prop)

            prop["assertion_label"] = label
            prop["source_kind"] = "named"
            assertions.append(prop)
            continue

        name = label or f"inline_{index}"

        prop = parse_property(
            name,
            content + ";",
        )

        prop["assertion_label"] = label
        prop["source_kind"] = "inline"

        assertions.append(prop)

    return definitions, assertions


def lower_property(prop, index=0):
    disable = prop["disable"]

    if prop["kind"] == "invariant":
        return f"""
        if (!({disable})) begin
            assert({prop["expression"]});
        end
"""

    ant = prop["antecedent"]
    cons = prop["consequent"]

    if prop["delay"] == 0:
        return f"""
        if (!({disable}) && ({ant})) begin
            assert({cons});
        end
"""

    return f"""
        if (
            f_past_valid &&
            !({disable}) &&
            !$past({disable}) &&
            $past({ant})
        ) begin
            assert({cons});
        end
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    text = Path(args.input).read_text()

    definitions, assertions = extract_assertions(text)

    report = {
        "properties_defined": len(definitions),
        "properties_asserted": len(assertions),
        "properties": assertions,
    }

    unsupported = [
        p for p in assertions
        if not p.get("supported")
    ]

    if not assertions:
        report["lowering_supported"] = False
        report["reason"] = "no assert property statements found"

        Path(args.report).write_text(
            json.dumps(report, indent=2) + "\n"
        )
        raise SystemExit(2)

    if unsupported:
        report["lowering_supported"] = False

        Path(args.report).write_text(
            json.dumps(report, indent=2) + "\n"
        )

        for p in unsupported:
            print(
                "UNSUPPORTED:",
                p["name"],
                "-",
                p["reason"],
            )

        raise SystemExit(2)

    clocks = {
        p["clock"]
        for p in assertions
    }

    if len(clocks) != 1:
        report["lowering_supported"] = False
        report["reason"] = (
            f"expected one clock, found {sorted(clocks)}"
        )

        Path(args.report).write_text(
            json.dumps(report, indent=2) + "\n"
        )
        raise SystemExit(2)

    clock = next(iter(clocks))

    lowered = [
        lower_property(p, i)
        for i, p in enumerate(assertions)
    ]

    monitor = f"""
reg f_past_valid = 1'b0;

always @(posedge {clock}) begin
    f_past_valid <= 1'b1;

{''.join(lowered)}
end
"""

    Path(args.output).write_text(monitor)

    report["lowering_supported"] = True
    report["clock"] = clock

    Path(args.report).write_text(
        json.dumps(report, indent=2) + "\n"
    )

    print(
        f"LOWERING PASS: {len(assertions)} assertions"
    )


if __name__ == "__main__":
    main()
