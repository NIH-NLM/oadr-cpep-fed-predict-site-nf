#!/usr/bin/env python3
"""
parse_nf_docs.py — Nextflow module documentation generator for Sphinx.

Walks ``modules/``, extracts the ``/** ... */`` docblock and ``process NAME {``
declaration (plus ``params.*`` references) from every ``.nf`` file, and writes
one ``.rst`` page per module group into ``docs/source/nextflow/``. Run before
``sphinx-build`` so the generated pages stay in sync with the ``.nf`` source:

    python3 docs/parse_nf_docs.py
    sphinx-build -b html docs/source docs/build/html

Usage (from the repo root)::

    python3 docs/parse_nf_docs.py [--modules-dir modules] [--output-dir docs/source/nextflow] [--dry-run]
"""

import argparse
import re
import sys
from pathlib import Path

_DOCBLOCK_RE = re.compile(r'/\*\*(.*?)\*/', re.DOTALL)
_PROCESS_RE  = re.compile(r'process\s+(\w+)\s*\{')
_PARAM_RE    = re.compile(r'params\.(\w+)')


def _strip_leading_stars(text):
    lines = []
    for line in text.splitlines():
        s = line.strip()
        if s.startswith('* '):
            lines.append(s[2:])
        elif s == '*':
            lines.append('')
        else:
            lines.append(s)
    return '\n'.join(lines).strip()


def parse_nf_file(path):
    """Return {name, docstring, params, source_file} for a .nf file, or None."""
    source = path.read_text(encoding='utf-8')
    m = _PROCESS_RE.search(source)
    if not m:
        return None
    docstring = ''
    for dm in _DOCBLOCK_RE.finditer(source):
        if dm.start() < m.start():
            docstring = _strip_leading_stars(dm.group(1))
    return {
        'name': m.group(1),
        'docstring': docstring,
        'params': sorted(set(_PARAM_RE.findall(source))),
        'source_file': str(path),
    }


def _title(text, char='-'):
    return f"{text}\n{char * len(text)}\n"


def process_to_rst(info):
    parts = [_title(info['name'].replace('_', ' ').title(), '^'),
             f".. rubric:: ``{info['name']}``\n",
             f"*Source:* ``{info['source_file']}``\n"]
    if info['docstring']:
        # render the docblock as a literal block so its ``*`` / indentation never
        # clash with RST inline markup
        parts.append('::\n')
        parts += ['   ' + line for line in info['docstring'].splitlines()]
        parts.append('')
    if info['params']:
        parts.append('**Params referenced:**\n')
        parts += [f'- ``params.{p}``' for p in info['params']]
        parts.append('')
    return '\n'.join(parts)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--modules-dir', default='modules')
    ap.add_argument('--output-dir', default='docs/source/nextflow')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    modules_root, output_root = Path(args.modules_dir), Path(args.output_dir)
    if not modules_root.is_dir():
        print(f"ERROR: modules directory not found: {modules_root}", file=sys.stderr)
        sys.exit(1)
    if not args.dry_run:
        output_root.mkdir(parents=True, exist_ok=True)

    index_entries = []
    for group_dir in sorted(p for p in modules_root.iterdir() if p.is_dir()):
        processes = [i for i in (parse_nf_file(f) for f in sorted(group_dir.glob('*.nf'))) if i]
        if not processes:
            continue
        rst = [_title(f"{group_dir.name.replace('_', ' ').title()} Modules", '=')]
        rst += [process_to_rst(i) + '\n' for i in processes]
        out_path = output_root / f"{group_dir.name}_modules.rst"
        if args.dry_run:
            print(f"[dry-run] {out_path} ({len(processes)} processes)")
        else:
            out_path.write_text('\n'.join(rst), encoding='utf-8')
            print(f"Written: {out_path}  ({len(processes)} processes)")
        index_entries.append(f"{group_dir.name}_modules")

    idx = ("Nextflow Workflow Modules\n=========================\n\n"
           "Auto-generated from the ``/** ... */`` docblocks in each ``.nf`` file by\n"
           "``docs/parse_nf_docs.py``. Regenerate after any ``.nf`` change::\n\n"
           "   python3 docs/parse_nf_docs.py\n\n"
           ".. toctree::\n   :maxdepth: 2\n\n")
    idx += ''.join(f"   {e}\n" for e in index_entries)
    if not args.dry_run:
        (output_root / "index.rst").write_text(idx, encoding='utf-8')
    print("Done.")


if __name__ == '__main__':
    main()
