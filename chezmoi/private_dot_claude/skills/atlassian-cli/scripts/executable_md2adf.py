#!/usr/bin/env python3
"""Convert a Markdown subset to Atlassian Document Format (ADF) JSON.

WHY THIS EXISTS
---------------
`acli jira workitem create/edit --description-file FILE` accepts either plain
text *or* ADF JSON. Plain text is stored as ONE paragraph node full of
`hardBreak`s: no headings, no lists, no inline code. The result is an
unreadable wall of text no matter how carefully the source was laid out.
Only ADF produces real structure. So: draft in Markdown, convert with this,
upload the JSON.

USAGE
-----
    md2adf.py description.md > description.json
    acli jira workitem edit --key PROJ-123 --description-file description.json --yes

    # sanity-check what the structure will be, without writing a file
    md2adf.py description.md --summary

    # self-test
    md2adf.py --selftest

SUPPORTED MARKDOWN
------------------
    # ..... ####        headings (level 1-4)
    - item / * item     bullet list (one level)
    1. item             ordered list (one level)
    ```lang ... ```     fenced code block
    > [!WARNING] text   panel (WARNING/NOTE/INFO/SUCCESS/ERROR), one paragraph
    `code`              inline code mark
    **bold**            strong mark
    [text](url)         link mark
    blank line          block separator

Anything else is emitted as paragraph text verbatim. Nested lists, tables and
images are NOT supported — keep the Markdown flat. If you need a table, build
the ADF node by hand and splice it in.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter

PANEL_KINDS = {
    "WARNING": "warning",
    "NOTE": "note",
    "INFO": "info",
    "SUCCESS": "success",
    "ERROR": "error",
}

# Inline: `code` wins over **bold** so `**x**` stays literal inside code.
_INLINE = re.compile(
    r"(?P<code>`[^`]+`)"
    r"|(?P<bold>\*\*[^*]+\*\*)"
    r"|(?P<link>\[[^\]]+\]\([^)]+\))"
)


def inline(s: str) -> list[dict]:
    """Parse inline marks into ADF text nodes."""
    out: list[dict] = []
    pos = 0
    for m in _INLINE.finditer(s):
        if m.start() > pos:
            out.append({"type": "text", "text": s[pos : m.start()]})
        if m.group("code"):
            out.append(
                {
                    "type": "text",
                    "text": m.group("code")[1:-1],
                    "marks": [{"type": "code"}],
                }
            )
        elif m.group("bold"):
            # Recurse so `code` inside **bold** loses its backticks rather than
            # rendering them literally. ADF forbids combining `code` with
            # `strong` (the server rejects the whole document with
            # INVALID_INPUT), so a code span inside bold keeps only its code
            # mark -- it renders as inline code, just not also bolded.
            for node in inline(m.group("bold")[2:-2]):
                marks = node.setdefault("marks", [])
                if not any(mk["type"] == "code" for mk in marks):
                    marks.append({"type": "strong"})
                if not marks:
                    del node["marks"]
                out.append(node)
        else:
            label, href = re.match(r"\[([^\]]+)\]\(([^)]+)\)", m.group("link")).groups()
            out.append(
                {
                    "type": "text",
                    "text": label,
                    "marks": [{"type": "link", "attrs": {"href": href}}],
                }
            )
        pos = m.end()
    if pos < len(s):
        out.append({"type": "text", "text": s[pos:]})
    # ADF rejects a paragraph whose content is an empty array.
    return out or [{"type": "text", "text": ""}]


def _para(s: str) -> dict:
    return {"type": "paragraph", "content": inline(s)}


def _list(items: list[str], ordered: bool) -> dict:
    node = {
        "type": "orderedList" if ordered else "bulletList",
        "content": [
            {"type": "listItem", "content": [_para(i)]} for i in items
        ],
    }
    if ordered:
        node["attrs"] = {"order": 1}
    return node


def convert(md: str) -> dict:
    """Convert Markdown text to an ADF doc node."""
    content: list[dict] = []
    lines = md.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        # Fenced code block
        if stripped.startswith("```"):
            lang = stripped[3:].strip()
            body: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                body.append(lines[i])
                i += 1
            i += 1  # closing fence
            node = {
                "type": "codeBlock",
                "content": [{"type": "text", "text": "\n".join(body)}],
            }
            if lang:
                node["attrs"] = {"language": lang}
            content.append(node)
            continue

        # Heading
        m = re.match(r"(#{1,4})\s+(.*)", stripped)
        if m:
            content.append(
                {
                    "type": "heading",
                    "attrs": {"level": len(m.group(1))},
                    "content": inline(m.group(2)),
                }
            )
            i += 1
            continue

        # Panel: > [!WARNING] text  (continuation lines while still quoted)
        m = re.match(r">\s*\[!(\w+)\]\s*(.*)", stripped)
        if m and m.group(1).upper() in PANEL_KINDS:
            kind = PANEL_KINDS[m.group(1).upper()]
            parts = [m.group(2)] if m.group(2) else []
            i += 1
            while i < len(lines) and lines[i].strip().startswith(">"):
                parts.append(lines[i].strip().lstrip(">").strip())
                i += 1
            content.append(
                {
                    "type": "panel",
                    "attrs": {"panelType": kind},
                    "content": [_para(" ".join(p for p in parts if p))],
                }
            )
            continue

        # Bullet list
        if re.match(r"[-*]\s+", stripped):
            items = []
            while i < len(lines) and re.match(r"[-*]\s+", lines[i].strip()):
                items.append(re.sub(r"^[-*]\s+", "", lines[i].strip()))
                i += 1
            content.append(_list(items, ordered=False))
            continue

        # Ordered list
        if re.match(r"\d+[.)]\s+", stripped):
            items = []
            while i < len(lines) and re.match(r"\d+[.)]\s+", lines[i].strip()):
                items.append(re.sub(r"^\d+[.)]\s+", "", lines[i].strip()))
                i += 1
            content.append(_list(items, ordered=True))
            continue

        # Paragraph: join until blank line or the start of another block
        para: list[str] = []
        while i < len(lines) and lines[i].strip():
            nxt = lines[i].strip()
            if para and (
                re.match(r"#{1,4}\s+", nxt)
                or re.match(r"[-*]\s+", nxt)
                or re.match(r"\d+[.)]\s+", nxt)
                or nxt.startswith("```")
                or nxt.startswith(">")
            ):
                break
            para.append(nxt)
            i += 1
        content.append(_para(" ".join(para)))

    return {"type": "doc", "version": 1, "content": content}


def summary(doc: dict) -> str:
    """Human-readable outline, for eyeballing before upload."""
    lines = [f"node types: {dict(Counter(n['type'] for n in doc['content']))}", ""]
    for n in doc["content"]:
        t = n["type"]
        if t == "heading":
            txt = "".join(x.get("text", "") for x in n["content"])
            lines.append(f"H{n['attrs']['level']}: {txt}")
        elif t == "panel":
            lines.append(f"PANEL[{n['attrs']['panelType']}]")
        elif t in ("bulletList", "orderedList"):
            lines.append(f"{t}: {len(n['content'])} items")
        elif t == "codeBlock":
            lines.append(f"codeBlock[{n.get('attrs', {}).get('language', 'none')}]")
        else:
            txt = "".join(x.get("text", "") for x in n.get("content", []))
            lines.append(f"para: {txt[:70]}")
    blob = json.dumps(doc)
    lines += ["", f"code marks: {blob.count(chr(34) + 'code' + chr(34))}"]
    lines.append(f"hardBreaks: {blob.count('hardBreak')}  (must be 0)")
    return "\n".join(lines)


def selftest() -> int:
    md = """# Title

Intro with `code`, **bold** and a [link](https://example.com).

> [!WARNING] Careful now.

## Section

- first `x`
- second

1. one
2. two

```rust
let x = 1;
```
"""
    doc = convert(md)
    types = [n["type"] for n in doc["content"]]
    checks = [
        ("doc wrapper", doc["type"] == "doc" and doc["version"] == 1),
        ("heading level 1", doc["content"][0]["attrs"]["level"] == 1),
        ("panel present", "panel" in types),
        ("bulletList present", "bulletList" in types),
        ("orderedList present", "orderedList" in types),
        ("codeBlock present", "codeBlock" in types),
        ("codeBlock language", doc["content"][types.index("codeBlock")]
            .get("attrs", {}).get("language") == "rust"),
        ("no hardBreak", "hardBreak" not in json.dumps(doc)),
        ("inline code mark", '"code"' in json.dumps(doc["content"][1])),
        ("inline strong mark", '"strong"' in json.dumps(doc["content"][1])),
        ("inline link mark", '"link"' in json.dumps(doc["content"][1])),
        ("ordered attrs", doc["content"][types.index("orderedList")]["attrs"]
            == {"order": 1}),
        ("no empty content", all(
            n.get("content") for n in doc["content"] if n["type"] != "rule")),
    ]
    # Nesting: `code` inside **bold** must produce one node carrying BOTH
    # marks, with no literal backticks left in the text.
    nested = convert("**bold with `code` inside**")["content"][0]["content"]
    code_nodes = [
        n for n in nested
        if any(m["type"] == "code" for m in n.get("marks", []))
    ]
    illegal = [
        n for n in nested
        if {"code", "strong"} <= {m["type"] for m in n.get("marks", [])}
    ]
    checks += [
        ("code span inside bold survives",
            len(code_nodes) == 1 and code_nodes[0]["text"] == "code"),
        ("no literal backticks", "`" not in json.dumps(nested)),
        # ADF rejects the whole document if code and strong are combined.
        ("code never combined with strong", not illegal),
        ("bold text around it is strong", any(
            n["text"].startswith("bold with")
            and any(m["type"] == "strong" for m in n.get("marks", []))
            for n in nested)),
    ]
    failed = [name for name, ok in checks if not ok]
    for name, ok in checks:
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")
    print()
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        return 1
    print(f"All {len(checks)} checks passed.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("input", nargs="?", help="Markdown file (default: stdin)")
    ap.add_argument("--summary", action="store_true", help="print an outline, not JSON")
    ap.add_argument("--selftest", action="store_true", help="run built-in checks")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    md = open(args.input).read() if args.input else sys.stdin.read()
    doc = convert(md)
    print(summary(doc) if args.summary else json.dumps(doc, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
