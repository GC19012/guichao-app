#!/usr/bin/env python3
"""
Post-processes slang-generated translations_zh_CN.g.dart:
  - Base64-encodes every simple String getter literal
  - Wraps each with _gchD('...')
  - Injects dart:convert import + _gchD() helper into translations.g.dart

Usage (run from project root):
  python3 tool/b64_i18n.py

Integrated into Makefile translate target.
"""

import re
import base64
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
MAIN_FILE = ROOT / 'lib/gch_gen/translations.g.dart'
PART_FILE = ROOT / 'lib/gch_gen/translations_zh_CN.g.dart'
DECODE_FN = '_gchD'

# ── helpers ──────────────────────────────────────────────────────────────────

def b64(s: str) -> str:
    return base64.b64encode(s.encode('utf-8')).decode('ascii')

def dart_unescape(s: str) -> str:
    """Convert Dart string literal escapes to real characters."""
    return (s
        .replace(r'\\', '\x00BACKSLASH\x00')
        .replace(r'\n', '\n')
        .replace(r'\t', '\t')
        .replace(r'\r', '\r')
        .replace(r"\'", "'")
        .replace(r'\"', '"')
        .replace('\x00BACKSLASH\x00', '\\'))

# ── process part file ─────────────────────────────────────────────────────────

# Pattern: optional tabs + "String get word => 'literal';"
# Captures: (indent + "String get word => ") + (content between quotes) + (";")
GETTER_RE = re.compile(
    r"^(\t+String get \w+ => ')((?:[^'\\]|\\.)*)(';)$",
    re.MULTILINE,
)

def encode_part(content: str) -> tuple[str, int]:
    count = 0

    def replacer(m: re.Match) -> str:
        nonlocal count
        prefix  = m.group(1)   # e.g. "\tString get appTitle => '"
        literal = m.group(2)   # e.g. "GUICHAO"
        suffix  = m.group(3)   # ";"  (with closing quote already consumed in group 1 / group 3)

        # prefix ends with "'" – strip it; suffix starts with "'" – strip it
        prefix_base = prefix[:-1]   # remove trailing '
        suffix_base = suffix[1:]    # remove leading '  → just ";"

        real_str = dart_unescape(literal)
        encoded  = b64(real_str)
        count += 1
        return f"{prefix_base}{DECODE_FN}('{encoded}'){suffix_base}"

    return GETTER_RE.sub(replacer, content), count


# ── inject helper into main file ──────────────────────────────────────────────

IMPORT_LINE   = "import 'dart:convert';"
HELPER_BLOCK  = (
    "\n// i18n string decoder – injected by tool/b64_i18n.py\n"
    "String _gchD(String s) {\n"
    "  try { return utf8.decode(base64Decode(s)); } catch (_) { return s; }\n"
    "}\n"
)
MARKER = '// [b64_i18n injected]'

def inject_main(content: str) -> str:
    if MARKER in content:
        return content  # already injected

    # Add dart:convert import after existing imports block
    # Find last import line
    lines = content.splitlines(keepends=True)
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import_idx = i

    if last_import_idx == -1:
        print("  ⚠️  Could not find import block in translations.g.dart", file=sys.stderr)
        return content

    # Insert dart:convert import after last import (if not already present)
    if IMPORT_LINE not in content:
        lines.insert(last_import_idx + 1, IMPORT_LINE + '\n')

    content = ''.join(lines)

    # Inject helper AFTER last `part '...'` line
    # (Dart requires all directives before declarations, so _gchD must come after part)
    for m in re.finditer(r"^part '[^']+';", content, re.MULTILINE):
        last_part_end = m.end()
    insert_pos = last_part_end
    content = (content[:insert_pos]
               + '\n'
               + MARKER + '\n'
               + HELPER_BLOCK
               + content[insert_pos:])

    return content


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    print("🔐 b64_i18n: encoding translation string literals...")

    part_src = PART_FILE.read_text(encoding='utf-8')
    encoded_src, count = encode_part(part_src)
    PART_FILE.write_text(encoded_src, encoding='utf-8')
    print(f"  ✅ {PART_FILE.name}: {count} getters encoded")

    main_src = MAIN_FILE.read_text(encoding='utf-8')
    new_main = inject_main(main_src)
    if new_main != main_src:
        MAIN_FILE.write_text(new_main, encoding='utf-8')
        print(f"  ✅ {MAIN_FILE.name}: _gchD() helper injected")
    else:
        print(f"  ℹ️  {MAIN_FILE.name}: already contains helper, skipped")

    print(f"🔐 Done. {count} strings encoded.")


if __name__ == '__main__':
    main()
