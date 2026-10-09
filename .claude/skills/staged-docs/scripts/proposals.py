"""Check, lint, serve and apply the proposals of a staged-docs review round.

A round folder (reviews/<round-id>/ in the working folder) holds proposals.json,
written by the agent, and decisions.json, written by the review page or the agent.
Run the script by its path inside the skill folder:

    python3 scripts/proposals.py check ROUND_DIR [--notes PATH]
        Validate proposals.json, then run the NOTES.md checks over every new text.
    python3 scripts/proposals.py lint --notes PATH FILE_OR_DIR...
        Run the NOTES.md checks over Markdown files.
    python3 scripts/proposals.py serve [ROUND_DIR] [--doc PATH ...] [--host H] [--port N]
        Serve the review page and save each choice to decisions.json; with only
        --doc, preview Markdown files read-only.
    python3 scripts/proposals.py page ROUND_DIR [--out PATH]
        Write a standalone review page that keeps choices in the browser.
    python3 scripts/proposals.py apply ROUND_DIR [--defaults] [--dry-run]
        Apply the accepted proposals to the document.
    python3 scripts/proposals.py snapshot ROUND_DIR --doc PATH...
        Copy the document's Markdown files into ROUND_DIR/base/.
    python3 scripts/proposals.py changes ROUND_DIR --doc PATH... [--out PATH]
        Write a read-only page of the changes since the snapshot.

Exit codes: 0 success, 1 problems found, 2 usage error.

The page template is assets/review.html in the skill folder. When the environment
variable STAGED_DOCS_TEMPLATE is set, it names the template file to use instead; the
tests use it for a stand-in template.
"""

import argparse
import difflib
import json
import os
import re
import shutil
import sys
import tempfile
import threading
from collections import Counter
from collections.abc import Callable
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, cast

Proposal = dict[str, Any]
Block = dict[str, Any]
Checks = list[tuple[re.Pattern[str], str]]

TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "review.html"
MARKER = "/*SD-DATA*/null"
LENSES = ("reader", "accuracy", "consistency", "completeness", "stakeholder")
STATUSES = ("open", "accepted", "rejected", "discuss")  # apply alone writes "default"
NOTE_LIMIT = 4000
BODY_LIMIT = 64 * 1024
LOCK = threading.Lock()  # one writer of decisions.json at a time

# The opening line of a fenced code block (a backtick fence has no backtick after it).
FENCE = re.compile(r"^\s*(`{3,}(?!.*`)|~{3,})")
# Text that a word diff would break: a code fence, an HTML block, a table rule, or a
# blank line, which means several blocks.
MARKUP = re.compile(
    r"(?m)^\s*(?:```|~~~)|^ {0,3}<[A-Za-z!/]|^ {0,3}\|?\s*:?-+:?\s*\||\n[ \t]*\n"
)
# A word with the white space before it. A link or image, a code span, emphasis and an
# HTML tag each count as one word, so a mark never cuts through their syntax.
WORD = re.compile(
    r"(\s*)(!?\[[^\]\n]*\]\([^)\n]*\)|`[^`\n]+`|\*\*[^*\n]+\*\*|\*[^*\n]+\*"
    r"|__[^_\n]+__|_[^_\n]+_|<[^>\n]+>|\w[\w'’-]*|\S)"
)
# Indentation, list bullets, heading hashes and quote marks stay outside a mark, so a
# marked line keeps its Markdown structure.
LINE_START = re.compile(r"\s*(?:(?:[-*+]|\d+[.)]|#{1,6})\s+|>\s*)*")
# A NOTES.md check: "- `<regex>` <reason>".
CHECK_ITEM = re.compile(r"^\s*[-*+]\s+(`+)(.+?)\1(?!`)\s*(.*)$")
# An inline code span: a run of backticks, then text, then a run of the same length.
CODE_SPAN = re.compile(r"(?<!`)(`+)(?!`).+?(?<!`)\1(?!`)")
# What may follow the anchor of an addition that starts a paragraph: spaces, then the
# end of the file or a blank line.
PARAGRAPH_END = re.compile(r"[ \t]*(?:\Z|\r?\n[ \t]*(?:\r?\n|\Z))")


class Fail(Exception):
    """Stops a command: main prints the message on one line and exits with code."""

    def __init__(self, message: str, code: int = 1) -> None:
        super().__init__(message)
        self.code = code


def read(path: Path) -> str:
    try:
        with path.open(encoding="utf-8", newline="") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise Fail(f"cannot read {path}: {e}") from e


def load_json(path: Path) -> Any:
    try:
        return json.loads(read(path))
    except ValueError as e:
        raise Fail(f"{path}: {e}") from e


def now() -> str:
    return datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%dT%H:%M:%S")


def is_text(value: object) -> bool:
    return isinstance(value, str) and value != ""


def target(p: Proposal) -> str | None:
    """The text a proposal sits on: the anchor of an addition, otherwise old."""
    text: str | None = p.get("anchor") if p.get("action") == "add" else p.get("old")
    return text


def find_notes(start: Path) -> Path:
    for folder in [start.resolve(), *start.resolve().parents]:
        if (folder / "NOTES.md").is_file():
            return folder / "NOTES.md"
    raise Fail(f"no NOTES.md in {start} or above it; pass --notes", 2)


def load_checks(notes: Path) -> Checks:
    """The patterns and reasons listed under the heading "## Checks" in NOTES.md (a
    heading that starts with it, such as "## Checks (regex)", counts too)."""
    if not notes.is_file():
        raise Fail(f"{notes}: not found", 2)
    checks: Checks = []
    inside = False
    for line in read(notes).splitlines():
        if re.match(r"#{1,2}\s", line):
            inside = line.startswith("## Checks")
        elif inside and (item := CHECK_ITEM.match(line)):
            try:
                checks.append((re.compile(item[2]), item[3] or item[2]))
            except re.error as e:
                raise Fail(f"{notes}: bad check `{item[2]}`: {e}") from e
    if not checks:
        print(f"warning: no checks found under '## Checks' in {notes}", file=sys.stderr)
    return checks


def notes_topic(notes: Path) -> str:
    front = read(notes).split("\n---", 1)[0]
    found = re.search(r"(?m)^topic:[ \t]*(.*?)[ \t]*$", front)
    return found[1].strip("\"'") if found else ""


def proposal_problems(p: Proposal) -> list[str]:
    """What is wrong with the fields of one proposal."""
    wrong: list[str] = []
    if not re.fullmatch(r"P-\d{3,}", str(p.get("id"))):
        wrong.append("id must be P- and at least three digits")
    for name in ("file", "why"):
        if not is_text(p.get(name)):
            wrong.append(f"{name} is required")
    sources = p.get("sources")
    if not (isinstance(sources, list) and sources and all(map(is_text, sources))):
        wrong.append("sources needs at least one entry")
    if p.get("priority") not in ("high", "medium", "low"):
        wrong.append("priority must be high, medium or low")
    if p.get("lens") not in LENSES:
        wrong.append(f"lens must be one of {', '.join(LENSES)}")
    if p.get("verdict", "real") not in ("real", "unsure"):
        wrong.append("verdict must be real or unsure")
    for name in ("group", "challenges", "quote"):
        if name in p and not isinstance(p[name], str):
            wrong.append(f"{name} must be text")
    if not isinstance(p.get("manual", False), bool):
        wrong.append("manual must be true or false")
    if p.get("type") == "fix":
        needs = {
            "add": ("anchor", "new", "reader_question"),
            "change": ("old", "new"),
            "remove": ("old",),
        }.get(str(p.get("action")))
        if needs is None:
            wrong.append("action must be add, change or remove")
        for name in needs or ():
            if not is_text(p.get(name)):
                wrong.append(f"{name} is required for {p['action']}")
        if "options" in p:
            wrong.append("options are only for decisions")
    elif p.get("type") == "decision":
        options = p.get("options")
        if not (
            isinstance(options, list)
            and len(options) >= 2
            and all(isinstance(o, dict) for o in options)
        ):
            return [*wrong, "a decision needs at least two options"]
        ids = [o.get("id") for o in options]
        if not all(isinstance(i, str) and re.fullmatch("[A-Za-z]", i) for i in ids):
            wrong.append("each option id must be a letter")
        elif len(set(ids)) < len(ids):
            wrong.append("option ids must be distinct")
        for o in options:
            if not is_text(o.get("label")) or "new" not in o:
                wrong.append(f"option {o.get('id')} needs a label and new")
            elif o["new"] is not None and not is_text(o["new"]):
                wrong.append(f"option {o.get('id')}: new must be text or null")
        if p.get("recommended") not in ids:
            wrong.append(f"recommended option {p.get('recommended')} does not exist")
        has_text = any(o.get("new") is not None for o in options)
        if (has_text or "old" in p) and not is_text(p.get("old")):
            wrong.append("old is required when an option has new text")
    else:
        wrong.append("type must be fix or decision")
    return wrong


def file_problems(data: Any) -> list[str]:
    """What is wrong with the fields of proposals.json; the text is not looked at."""
    if not (isinstance(data, dict) and isinstance(data.get("proposals"), list)):
        raise Fail("proposals.json needs an object with a proposals list")
    problems = []
    if not is_text(data.get("round")):
        problems.append("proposals.json: round is required")
    if data.get("kind") not in ("review", "stakeholder"):
        problems.append("proposals.json: kind must be review or stakeholder")
    if not isinstance(data.get("root"), str):
        problems.append("proposals.json: root is required")
    seen: set[str] = set()
    for n, p in enumerate(data["proposals"], 1):
        if not isinstance(p, dict):
            problems.append(f"proposal {n}: not an object")
            continue
        pid = str(p.get("id", f"proposal {n}"))
        if pid in seen:
            problems.append(f"{pid}: duplicate id")
        seen.add(pid)
        problems += [f"{pid}: {wrong}" for wrong in proposal_problems(p)]
    return problems


def text_problems(root: Path, proposals: list[Proposal], checks: Checks) -> list[str]:
    """Text not found exactly once, overlaps, additions that would split a paragraph,
    and new text with more matches of a check than the text it replaces."""
    problems = []
    texts: dict[str, str | None] = {}
    spans: dict[str, list[tuple[int, int, str]]] = {}
    for p in proposals:
        pid, file = p["id"], p["file"]
        if file not in texts:
            texts[file] = read(root / file) if (root / file).is_file() else None
        text, old = texts[file], target(p)
        if text is None:
            problems.append(f"{pid}: file {file} not found")
        elif old is not None:
            count = text.count(old)
            if count == 1:
                start = text.index(old)
                spans.setdefault(file, []).append((start, start + len(old), pid))
                if (
                    p.get("action") == "add"
                    and p["new"].startswith("\n\n")
                    and not PARAGRAPH_END.match(text, start + len(old))
                ):
                    problems.append(f"{pid}: anchor does not end its paragraph")
            else:
                field = "anchor" if p.get("action") == "add" else "old"
                problems.append(f"{pid}: {field} text found {count} times in {file}")
        # A match the replaced text already has is not this proposal's doing.
        replaced = "" if p.get("action") == "add" else p.get("old") or ""
        news = [("new text", p.get("new"))]
        if p["type"] == "decision":
            news += [(f"option {o['id']}", o["new"]) for o in p["options"]]
        for where, new in news:
            for pattern, reason in checks:
                found = [m[0] for m in pattern.finditer(new or "")]
                before = [m[0] for m in pattern.finditer(replaced)]
                if len(found) > len(before):
                    match = next((f for f in found if f not in before), found[0])
                    problems.append(f"{pid}: {where}: {reason}: {match}")
    for file, found_spans in spans.items():
        end, last = -1, ""
        for start, stop, pid in sorted(found_spans):
            if start < end:
                problems.append(f"{pid}: overlaps {last} in {file}")
            if stop > end:
                end, last = stop, pid
    return problems


def load_round(round_dir: Path) -> dict[str, Any]:
    path = round_dir / "proposals.json"
    if not path.is_file():
        raise Fail(f"{path}: not found", 2)
    data: dict[str, Any] = load_json(path)
    if file_problems(data):
        raise Fail(f"{path} has problems; run check")
    return data


def load_decisions(round_dir: Path) -> dict[str, Any]:
    path = round_dir / "decisions.json"
    if not path.exists():
        return {}
    data = load_json(path)
    if not (isinstance(data, dict) and all(isinstance(r, dict) for r in data.values())):
        raise Fail(f"{path}: needs an object of records keyed by proposal ID")
    return data


def save_json(path: Path, data: dict[str, Any]) -> None:
    """Write data to path through a temporary file, so a crash leaves no half file."""
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, suffix=".tmp", delete=False
    ) as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(f.name, path)


def record(old: dict[str, Any] | None, changes: dict[str, Any]) -> dict[str, Any]:
    new = {"status": "open", "option": None, "note": "", "at": "", "applied": False}
    new.update(old or {})
    new.update(changes)
    new["at"] = now()
    return new


def next_fence(fence: str, line: str) -> str:
    """The fence that is open after line, given the one open before it ("" for none)."""
    if fence:
        stripped = line.strip()
        closes = set(stripped) == {fence[0]} and len(stripped) >= len(fence)
        return "" if closes else fence
    opening = FENCE.match(line)
    return opening[1] if opening else ""


def split_blocks(text: str) -> list[tuple[int, int]]:
    """The start and end offset of each block: a run of lines between blank lines.
    A fenced code block stays whole, and indented lines after a blank line stay with
    the block before them, as the body of a list item does."""
    blocks: list[list[int]] = []
    fence = ""
    blank = True
    start = 0
    for line in text.split("\n"):
        end = start + len(line.rstrip("\r"))
        stripped = line.strip()
        if fence:
            blocks[-1][1] = end
        elif stripped:
            if blocks and (not blank or line[0] in " \t"):
                blocks[-1][1] = end
            else:
                blocks.append([start, end])
        fence = next_fence(fence, line)
        blank = not stripped
        start += len(line) + 1
    return [(s, e) for s, e in blocks]


def without_code(text: str) -> str:
    """text with its fenced code blocks and code spans blanked out. Every character
    keeps its place, so a match in the result has the same line as in text."""
    lines = []
    fence = ""
    for line in text.split("\n"):
        after = next_fence(fence, line)
        if fence or after:
            lines.append(" " * len(line))
        else:
            lines.append(CODE_SPAN.sub(lambda m: " " * len(m[0]), line))
        fence = after
    return "\n".join(lines)


def wrap(tag: str, cls: str, pid: str, text: str) -> str:
    """text in <tag>, one tag per line, so a mark never spans a line break."""
    lines = []
    for line in text.split("\n"):
        lead = start.end() if (start := LINE_START.match(line)) else 0
        body = line[lead:]
        if body.strip():
            body = f'<{tag} class="{cls}" data-id="{pid}">{body}</{tag}>'
        lines.append(line[:lead] + body)
    return "\n".join(lines)


def joined(words: list[tuple[str, str]]) -> str:
    return words[0][1] + "".join(space + word for space, word in words[1:])


def word_diff(old: str, new: str, pid: str) -> str:
    """new, with the words gone from old in <del> and the added words in <ins>."""
    a: list[tuple[str, str]] = WORD.findall(old)
    b: list[tuple[str, str]] = WORD.findall(new)
    matcher = difflib.SequenceMatcher(
        None, [w for _, w in a], [w for _, w in b], autojunk=False
    )
    parts: list[str] = []
    for op, i1, i2, j1, j2 in matcher.get_opcodes():
        if op == "equal":
            parts += [space + word for space, word in b[j1:j2]]
            continue
        parts.append((b[j1:j2] or a[i1:i2])[0][0])  # the space before stays outside
        if i1 < i2:
            parts.append(wrap("del", "sd-old", pid, joined(a[i1:i2])))
        if j1 < j2:
            parts.append(wrap("ins", "sd-new", pid, joined(b[j1:j2])))
    return "".join(parts) + new[len(new.rstrip()) :]


def marked(before: str, edits: list[tuple[Proposal, int, int]]) -> str:
    """before, with each fix shown as a word diff and each decision's text marked."""
    words = [m.span(2) for m in WORD.finditer(before)]
    parts: list[str] = []
    pos = 0
    for p, s, e in sorted(edits, key=lambda edit: edit[1]):
        # Widen the text to whole words, so a mark never cuts a link or a code span.
        cut = [w for w in words if w[0] < e and w[1] > s]
        start = max(pos, min([s] + [w[0] for w in cut]))
        end = max([e] + [w[1] for w in cut])
        parts.append(before[pos:start])
        if p["type"] == "decision":
            parts.append(wrap("mark", "sd-target", p["id"], before[start:end]))
        else:
            new = before[start:s] + p.get("new", "") + before[e:end]
            parts.append(word_diff(before[start:end], new, p["id"]))
        pos = end
    return "".join(parts) + before[pos:]


def render(before: str, items: list[tuple[Proposal, int, int]]) -> list[Block]:
    """The block for the text before, with its proposals shown, and then a block for
    each addition. items holds each proposal with the offsets of its text in before."""
    edits = [item for item in items if item[0].get("action") != "add"]
    added: list[Block] = [
        {"md": p["new"].strip("\n"), "ids": [p["id"]], "kind": "added"}
        for p, _, _ in items
        if p.get("action") == "add"
    ]
    if not edits:
        return [{"md": before.strip("\n"), "ids": []}, *added]
    after = before
    for p, s, e in sorted(edits, key=lambda edit: -edit[1]):
        if p["type"] == "fix":
            after = after[:s] + p.get("new", "") + after[e:]
    ids = [p["id"] for p, _, _ in edits]
    kind = "diff"
    if not after.strip():
        kind = "removed"
    elif all(p["type"] == "decision" for p, _, _ in edits):
        kind = "decision"
    block: Block
    if not (MARKUP.search(before.strip("\n")) or MARKUP.search(after.strip("\n"))):
        block = {"md": marked(before, edits), "ids": ids, "kind": kind}
    elif kind == "diff":
        block = {"md": after, "before": before.strip("\n"), "ids": ids}
        block["kind"] = "replaced"
    else:
        # A removed or decided code block, table or HTML block shows as it is.
        block = {"md": before, "ids": ids, "kind": kind}
    block["md"] = block["md"].strip("\n")
    return [block, *added]


def file_blocks(text: str, proposals: list[Proposal]) -> list[Block]:
    """The page blocks of one file, each proposal shown in the block of its text."""
    blocks = split_blocks(text)
    found: list[tuple[int, int, Proposal]] = []
    lost: list[Proposal] = []
    for p in proposals:
        old = target(p)
        if old and text.count(old) == 1:
            found.append((text.index(old), text.index(old) + len(old), p))
        else:
            lost.append(p)
    placed: list[tuple[Proposal, int, int, int]] = []  # with the first block it is in
    joins = [False] * len(blocks)  # joins[k]: block k + 1 goes with block k
    end = -1
    for s, e, p in sorted(found, key=lambda f: f[0]):
        hit = [k for k, (bs, be) in enumerate(blocks) if bs < e and be > s]
        if s < end or not hit:  # overlaps the one before, or is only blank lines
            lost.append(p)
            continue
        end = e
        placed.append((p, s, e, hit[0]))
        for k in hit[:-1]:
            joins[k] = True
    out: list[Block] = []
    first = 0
    for last in range(len(blocks)):
        if joins[last]:
            continue
        items = [(p, s, e) for p, s, e, k in placed if first <= k <= last]
        start = min([blocks[first][0]] + [s for _, s, _ in items])
        stop = max([blocks[last][1]] + [e for _, _, e in items])
        out += render(
            text[start:stop], [(p, s - start, e - start) for p, s, e in items]
        )
        first = last + 1
    # A proposal whose text is not found exactly once goes at the end, shown on its
    # own text, so the author still sees it and can decide.
    for p in lost:
        old = target(p) or ""
        if old:
            out += render(old, [(p, 0, len(old))])
        else:
            out.append({"md": "", "ids": [p["id"]], "kind": "decision"})
    return out


def words_delta(p: Proposal) -> int:
    """Words in the new text minus words in the old; for a decision, the new text of
    the recommended option, and 0 when that option keeps the text."""
    new = p.get("new", "")
    if p["type"] == "decision":
        new = next(o["new"] for o in p["options"] if o["id"] == p["recommended"])
        if new is None:
            return 0
    old = "" if p.get("action") == "add" else p.get("old", "")
    return len(new.split()) - len(old.split())


def page_data(round_dir: Path, api: str | None) -> dict[str, Any]:
    data = load_round(round_dir)
    root = round_dir / data["root"]
    decisions = load_decisions(round_dir)
    try:
        topic = notes_topic(find_notes(round_dir))
    except Fail:
        topic = ""
    by_file: dict[str, list[Proposal]] = {}
    for p in data["proposals"]:
        by_file.setdefault(p["file"], []).append(p)
    files = []
    for file, proposals in by_file.items():
        text = read(root / file) if (root / file).is_file() else ""
        files.append({"path": file, "blocks": file_blocks(text, proposals)})
    return {
        "mode": "review",
        "title": f"{data['round']}: {topic}" if topic else data["round"],
        "api": api,
        "storage_key": f"staged-docs:{round_dir.resolve()}",
        "files": files,
        "proposals": {
            p["id"]: {"group": p["lens"], "verdict": "real", **p}
            | {"words_delta": words_delta(p)}
            for p in data["proposals"]
        },
        "decisions": {
            p["id"]: decisions.get(p["id"], {"status": "open"})
            for p in data["proposals"]
        },
    }


def preview_data(docs: list[Path]) -> dict[str, Any]:
    files = []
    for doc in docs:
        if not doc.exists():
            raise Fail(f"{doc}: not found", 2)
        for path in sorted(doc.rglob("*.md")) if doc.is_dir() else [doc]:
            text = read(path)
            blocks = [{"md": text[s:e], "ids": []} for s, e in split_blocks(text)]
            files.append({"path": path.as_posix(), "blocks": blocks})
    return {
        "mode": "preview",
        "title": "Preview: " + ", ".join(doc.as_posix() for doc in docs),
        "api": None,
        "storage_key": "staged-docs:preview",
        "files": files,
        "proposals": {},
        "decisions": {},
    }


def relative(path: Path) -> Path:
    """path relative to the working folder, which is the current directory."""
    try:
        return path.resolve().relative_to(Path.cwd().resolve())
    except ValueError:
        raise Fail(f"{path}: not inside the working folder {Path.cwd()}", 2) from None


def markdown_files(folder: Path, path: Path) -> list[Path]:
    """The Markdown files at folder / path (a file, or a folder searched for *.md),
    relative to folder; none when it does not exist."""
    full = folder / path
    if full.is_dir():
        return [p.relative_to(folder) for p in sorted(full.rglob("*.md"))]
    return [path] if full.is_file() else []


def similar(old: str, new: str) -> bool:
    """More than half the words of each text are also in the other."""
    a, b = Counter(old.split()), Counter(new.split())
    return 2 * (a & b).total() > max(a.total(), b.total())


def change_blocks(
    file: str, old: str, new: str, changes: dict[str, Any], ids: dict[str, str]
) -> list[Block]:
    """The page blocks of the new text of one file, with each block changed since
    the old text shown in place, and recorded in changes under its C- ID. ids maps
    the key of each change seen so far to its ID; a new change gets the next number."""
    a = [old[s:e] for s, e in split_blocks(old)]
    b = [new[s:e] for s, e in split_blocks(new)]
    out: list[Block] = []
    seen: Counter[tuple[str, ...]] = Counter()

    def change(before: str, after: str) -> None:
        def show(cid: str) -> Block:
            if not before:
                return {"md": after, "ids": [cid], "kind": "added"}
            # A change is shown the way the review page shows a fix of the whole block.
            fix: Proposal = {"id": cid, "type": "fix", "new": after}
            return render(before, [(fix, 0, len(before))])[0]

        # The key: file, kind, and both texts with white space evened out, counted so
        # that the same change twice in a file gets two IDs.
        texts = [" ".join(text.split()) for text in (before, after)]
        parts = (file, show("")["kind"], *texts)
        seen[parts] += 1
        key = json.dumps([*parts, seen[parts]], ensure_ascii=False)
        if key not in ids:
            last = max((int(cid[2:]) for cid in ids.values()), default=0)
            ids[key] = f"C-{last + 1}"
        cid = ids[key]
        block = show(cid)
        out.append(block)
        changes[cid] = {
            "file": file,
            "kind": block["kind"],
            "summary": " ".join((after or before).split())[:80],
            "words_delta": len(after.split()) - len(before.split()),
        }

    matcher = difflib.SequenceMatcher(None, a, b, autojunk=False)
    for op, i1, i2, j1, j2 in matcher.get_opcodes():
        if op == "equal":
            out += [{"md": block, "ids": []} for block in b[j1:j2]]
            continue
        # Pair each new block with the next similar old block. The old blocks passed
        # over are removed, and the new blocks with no pair are added.
        i, added = i1, []
        for j in range(j1, j2):
            k = next((k for k in range(i, i2) if similar(a[k], b[j])), None)
            if k is None:
                added.append(b[j])
                continue
            for before in a[i:k]:
                change(before, "")
            for after in added:
                change("", after)
            change(a[k], b[j])
            i, added = k + 1, []
        for before in a[i:i2]:
            change(before, "")
        for after in added:
            change("", after)
    return out


def changes_data(round_dir: Path, docs: list[Path]) -> dict[str, Any]:
    base = round_dir / "base"
    if not base.is_dir():
        raise Fail(f"{base}: not found; run snapshot first")
    names: dict[Path, None] = {}  # the files to compare, in --doc order
    for doc in docs:
        key = relative(doc)
        found = markdown_files(Path.cwd(), key) + markdown_files(base, key)
        if not found:
            raise Fail(f"{doc}: no Markdown files found, now or in {base}", 2)
        names.update(dict.fromkeys(sorted(set(found))))
    # The IDs of earlier runs, so a change keeps its ID while the author asks for redos.
    ids_file = round_dir / "changes-ids.json"
    ids: dict[str, str] = load_json(ids_file) if ids_file.is_file() else {}
    if not (
        isinstance(ids, dict)
        and all(isinstance(v, str) and re.fullmatch(r"C-\d+", v) for v in ids.values())
    ):
        raise Fail(f"{ids_file}: needs an object of C- IDs keyed by change")
    files = []
    changes: dict[str, Any] = {}
    for name in names:
        old = read(base / name) if (base / name).is_file() else None
        new = read(name) if name.is_file() else None
        if old == new:
            continue
        status = "added" if old is None else "removed" if new is None else "changed"
        path = name.as_posix()
        blocks = change_blocks(path, old or "", new or "", changes, ids)
        files.append({"path": path, "status": status, "blocks": blocks})
    save_json(ids_file, ids)
    return {
        "mode": "changes",
        "title": f"{round_dir.resolve().name}: changes since the snapshot",
        "api": None,
        "storage_key": f"staged-docs:{round_dir.resolve()}:changes",
        "files": files,
        "changes": changes,
        "proposals": {},
        "decisions": {},
    }


def render_page(data: dict[str, Any]) -> str:
    path = Path(os.environ.get("STAGED_DOCS_TEMPLATE") or TEMPLATE)
    template = read(path)
    if MARKER not in template:
        raise Fail(f"{path} has no {MARKER} marker")
    # Every "<" is escaped, so no text in the JSON can close or confuse the script tag.
    payload = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")
    return template.replace(MARKER, payload, 1)


def post_decision(round_dir: Path, pid: str, raw: bytes) -> dict[str, Any]:
    """Validate a choice sent by the page and store it in decisions.json.
    Raises Fail with code 400 when the request is not valid."""
    proposals = {p["id"]: p for p in load_round(round_dir)["proposals"]}
    if pid not in proposals:
        raise Fail(f"unknown proposal {pid}", 400)
    try:
        body = json.loads(raw)
    except ValueError:
        raise Fail("the body is not JSON", 400) from None
    if not isinstance(body, dict):
        raise Fail("the body must be a JSON object", 400)
    if unknown := sorted(set(body) - {"status", "option", "note"}):
        raise Fail(f"unknown field: {', '.join(unknown)}", 400)
    if "status" in body and body["status"] not in STATUSES:
        raise Fail(f"status must be one of {', '.join(STATUSES)}", 400)
    options = [o["id"] for o in proposals[pid].get("options", [])]
    if body.get("option") is not None and body["option"] not in options:
        raise Fail(f"{pid} has no option {body['option']}", 400)
    note = body.get("note", "")
    if not isinstance(note, str) or len(note) > NOTE_LIMIT:
        raise Fail(f"note must be text of at most {NOTE_LIMIT} characters", 400)
    with LOCK:
        decisions = load_decisions(round_dir)
        if decisions.get(pid, {}).get("applied"):
            raise Fail("already applied", 409)
        saved = decisions[pid] = record(decisions.get(pid), body)
        save_json(round_dir / "decisions.json", decisions)
    return saved


def make_server(
    round_dir: Path | None, docs: list[Path], host: str, port: int
) -> ThreadingHTTPServer:
    """A server for the review page of round_dir, or for a preview of docs, on the
    first free port from port to port + 10."""

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args: Any) -> None:
            pass  # keeps the terminal quiet

        def send(self, code: int, body: str, kind: str = "application/json") -> None:
            data = body.encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", f"{kind}; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def send_fail(self, e: Fail) -> None:
            self.send(e.code if e.code >= 400 else 500, json.dumps({"error": str(e)}))

        def check_host(self) -> None:
            # A page on another site that rebinds its name to 127.0.0.1 sends its own
            # name as Host, so only the local names are served.
            port = cast(ThreadingHTTPServer, self.server).server_port
            host = self.headers.get("Host")
            if host not in (f"127.0.0.1:{port}", f"localhost:{port}"):
                raise Fail(f"host {host} is refused", 403)

        def do_GET(self) -> None:
            path = self.path.partition("?")[0]
            try:
                self.check_host()
                if path == "/":
                    data = (
                        page_data(round_dir, "/decisions")
                        if round_dir
                        else preview_data(docs)
                    )
                    self.send(200, render_page(data), "text/html")
                elif path == "/decisions" and round_dir:
                    decisions = load_decisions(round_dir)
                    self.send(200, json.dumps(decisions, ensure_ascii=False))
                else:
                    raise Fail("not found", 404)
            except Fail as e:
                self.send_fail(e)

        def do_POST(self) -> None:
            found = re.fullmatch(r"/decisions/([^/?]+)", self.path)
            origin = self.headers.get("Origin")
            size = self.headers.get("Content-Length", "")
            try:
                self.check_host()
                if round_dir is None or found is None:
                    raise Fail("not found", 404)
                # Same origin only: refuse a choice sent from another site's page.
                if origin and origin.partition("://")[2] != self.headers.get("Host"):
                    raise Fail("requests from other sites are refused", 403)
                if not size.isdecimal() or int(size) > BODY_LIMIT:
                    self.close_connection = True
                    raise Fail(f"the body must be at most {BODY_LIMIT} bytes", 400)
                saved = post_decision(round_dir, found[1], self.rfile.read(int(size)))
                self.send(200, json.dumps(saved, ensure_ascii=False))
            except Fail as e:
                self.send_fail(e)

    error = ""
    for candidate in range(port, port + 11):
        try:
            return ThreadingHTTPServer((host, candidate), Handler)
        except OSError as e:
            error = e.strerror or str(e)
        except OverflowError as e:  # a port above 65535
            error = str(e)
    raise Fail(f"cannot serve on {host}, ports {port} to {port + 10}: {error}")


def cmd_check(args: argparse.Namespace) -> int:
    round_dir = Path(args.round_dir)
    path = round_dir / "proposals.json"
    if not path.is_file():
        raise Fail(f"{path}: not found", 2)
    checks = load_checks(Path(args.notes) if args.notes else find_notes(round_dir))
    data = load_json(path)
    problems = file_problems(data)
    if isinstance(data.get("root"), str):
        valid = [
            p
            for p in data["proposals"]
            if isinstance(p, dict) and not proposal_problems(p)
        ]
        problems += text_problems(round_dir / data["root"], valid, checks)
    for line in problems:
        print(line)
    print(f"{len(problems)} problems" if problems else f"OK: {len(valid)} proposals")
    return 1 if problems else 0


def cmd_lint(args: argparse.Namespace) -> int:
    checks = load_checks(Path(args.notes))
    files: list[Path] = []
    for name in args.paths:
        path = Path(name)
        if path.is_dir():
            files += sorted(path.rglob("*.md"))
        elif path.is_file():
            files.append(path)
        else:
            raise Fail(f"{name}: not found", 2)
    count = 0
    for path in files:
        text = without_code(read(path))
        hits = sorted(
            (text.count("\n", 0, found.start()) + 1, reason, found[0])
            for pattern, reason in checks
            for found in pattern.finditer(text)
        )
        for line, reason, match in hits:
            print(f"{path.as_posix()}:{line}: {reason}: {match}")
        count += len(hits)
    print(f"{count} matches" if count else f"OK: {len(files)} files")
    return 1 if count else 0


def cmd_serve(args: argparse.Namespace) -> int:
    if bool(args.round_dir) == bool(args.doc):
        raise Fail("give either ROUND_DIR or --doc", 2)
    round_dir = Path(args.round_dir) if args.round_dir else None
    docs = [Path(doc) for doc in args.doc or []]
    # Build the page once, so a broken round or template stops the command here.
    render_page(page_data(round_dir, None) if round_dir else preview_data(docs))
    server = make_server(round_dir, docs, args.host, args.port)
    print(f"Serving http://{args.host}:{server.server_port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


def cmd_page(args: argparse.Namespace) -> int:
    round_dir = Path(args.round_dir)
    out = Path(args.out) if args.out else round_dir / "review.html"
    out.write_text(render_page(page_data(round_dir, None)), encoding="utf-8")
    print(f"Wrote {out}")
    return 0


def cmd_snapshot(args: argparse.Namespace) -> int:
    base = Path(args.round_dir) / "base"
    if base.exists():
        raise Fail(f"{base} already exists; a snapshot is never overwritten")
    names: dict[Path, None] = {}
    for doc in args.doc:
        found = markdown_files(Path.cwd(), relative(Path(doc)))
        if not found:
            raise Fail(f"{doc}: no Markdown files found", 2)
        names.update(dict.fromkeys(found))
    base.mkdir(parents=True)
    for name in names:
        (base / name).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(name, base / name)
    print(f"Snapshot: {len(names)} files in {base}/")
    return 0


def cmd_changes(args: argparse.Namespace) -> int:
    round_dir = Path(args.round_dir)
    out = Path(args.out) if args.out else round_dir / "changes.html"
    data = changes_data(round_dir, [Path(doc) for doc in args.doc])
    out.write_text(render_page(data), encoding="utf-8")
    print(
        f"Changes: {len(data['changes'])} changes in {len(data['files'])} files -> {out}"
    )
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    round_dir = Path(args.round_dir)
    data = load_round(round_dir)
    root = round_dir / data["root"]
    decisions = load_decisions(round_dir)
    defaults = 0
    if args.defaults:
        for p in data["proposals"]:
            old_record = decisions.get(p["id"])
            if p.get("action") != "add" and (
                old_record is None or old_record.get("status") == "open"
            ):
                change = {"status": "default", "option": p.get("recommended")}
                decisions[p["id"]] = record(old_record, change)
                defaults += 1
    decisions_file = round_dir / "decisions.json"
    if defaults and not args.dry_run:
        save_json(decisions_file, decisions)
    before: dict[str, str] = {}
    after: dict[str, str] = {}
    left: list[str] = []
    applied = kept = already = skipped = other = 0
    for p in data["proposals"]:
        pid, rec = p["id"], decisions.get(p["id"], {})
        if rec.get("status") not in ("accepted", "default"):
            other += 1
            continue
        if rec.get("applied"):
            already += 1
            continue
        if p.get("manual"):
            left.append(f"{pid}: manual")
            continue
        new = p.get("new", "")
        if p["type"] == "decision":
            option = next(
                (o for o in p["options"] if o["id"] == rec.get("option")), None
            )
            if option is None:
                left.append(f"{pid}: no option chosen")
                continue
            new = option["new"]
        file, old, add = p["file"], target(p) or "", p.get("action") == "add"
        if new is None:  # the chosen option keeps the text as it is
            kept += 1
        else:
            if file not in after:
                path = root / file
                before[file] = after[file] = read(path) if path.is_file() else ""
            text = after[file]
            count = text.count(old)
            if count != 1:
                field = "anchor" if add else "old"
                left.append(
                    f"{pid}: skipped, {field} text found {count} times in {file}"
                )
                skipped += 1
                continue
            if add and text.startswith(new, text.index(old) + len(old)):
                already += 1  # inserted by a run that stopped before it saved
            else:
                after[file] = text.replace(old, old + new if add else new, 1)
                applied += 1
                if not args.dry_run:
                    (root / file).write_text(after[file], encoding="utf-8", newline="")
        rec["applied"] = True
        if not args.dry_run:
            # Saved with each edit, so a run that stops halfway never repeats one.
            save_json(decisions_file, decisions)
    for file, text in after.items():
        if args.dry_run and text != before[file]:
            lines = difflib.unified_diff(
                before[file].splitlines(),
                text.splitlines(),
                f"a/{file}",
                f"b/{file}",
                lineterm="",
            )
            print("\n".join(lines))
    counts = [
        f"{'Would apply' if args.dry_run else 'Applied'}: {applied}.",
        f"Already applied: {already}.",
        f"Not accepted: {other}.",
    ]
    if kept:
        counts.insert(1, f"Kept: {kept}.")
    if args.defaults:
        counts.insert(0, f"Set to default: {defaults}.")
    print(" ".join(counts))
    if left:
        print("Left for the agent:")
        print("\n".join(f"- {line}" for line in left))
    return 1 if skipped else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="proposals.py",
        description="Check, lint, serve and apply the proposals of a review round.",
    )
    sub = parser.add_subparsers(required=True, metavar="COMMAND")

    def command(
        name: str, run: Callable[[argparse.Namespace], int], text: str
    ) -> argparse.ArgumentParser:
        command_parser = sub.add_parser(name, help=text, description=text)
        command_parser.set_defaults(run=run)
        return command_parser

    round_help = "round folder that holds proposals.json"
    check = command(
        "check",
        cmd_check,
        "Validate proposals.json and run the NOTES.md checks over every new text.",
    )
    check.add_argument("round_dir", metavar="ROUND_DIR", help=round_help)
    check.add_argument(
        "--notes",
        help="NOTES.md with the checks (default: the nearest above ROUND_DIR)",
    )

    lint = command("lint", cmd_lint, "Run the NOTES.md checks over Markdown files.")
    lint.add_argument("--notes", required=True, help="NOTES.md with the checks")
    lint.add_argument(
        "paths",
        nargs="+",
        metavar="FILE_OR_DIR",
        help="Markdown file, or folder to search for *.md",
    )

    serve = command(
        "serve",
        cmd_serve,
        "Serve the review page of a round, or a read-only preview with --doc.",
    )
    serve.add_argument("round_dir", nargs="?", metavar="ROUND_DIR", help=round_help)
    serve.add_argument(
        "--doc",
        nargs="+",
        action="extend",
        metavar="PATH",
        help="Markdown file or folder to preview, instead of ROUND_DIR",
    )
    serve.add_argument("--host", default="127.0.0.1", help="default: 127.0.0.1")
    serve.add_argument(
        "--port", type=int, default=8770, help="default: 8770; the next 10 if taken"
    )

    page = command(
        "page",
        cmd_page,
        "Write a standalone review page that keeps choices in the browser.",
    )
    page.add_argument("round_dir", metavar="ROUND_DIR", help=round_help)
    page.add_argument("--out", help="file to write (default: ROUND_DIR/review.html)")

    apply = command(
        "apply", cmd_apply, "Apply the accepted proposals to the document files."
    )
    apply.add_argument("round_dir", metavar="ROUND_DIR", help=round_help)
    apply.add_argument(
        "--defaults",
        action="store_true",
        help="first take the recommended answer for every open proposal but additions",
    )
    apply.add_argument(
        "--dry-run", action="store_true", help="print a diff and write nothing"
    )

    snapshot = command(
        "snapshot",
        cmd_snapshot,
        "Copy the document's Markdown files into ROUND_DIR/base/.",
    )
    changes = command(
        "changes",
        cmd_changes,
        "Write a read-only page of the changes since the snapshot in ROUND_DIR/base/.",
    )
    for snapshot_command in (snapshot, changes):
        snapshot_command.add_argument(
            "round_dir", metavar="ROUND_DIR", help="round folder with the snapshot"
        )
        snapshot_command.add_argument(
            "--doc",
            nargs="+",
            action="extend",
            required=True,
            metavar="PATH",
            help="Markdown file, or folder to search for *.md",
        )
    changes.add_argument(
        "--out", help="file to write (default: ROUND_DIR/changes.html)"
    )

    args = parser.parse_args(argv)
    try:
        return int(args.run(args))
    except Fail as e:
        print(f"error: {e}", file=sys.stderr)
        return e.code


if __name__ == "__main__":
    sys.exit(main())
