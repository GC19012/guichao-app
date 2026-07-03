#!/usr/bin/env python3
"""
删除 strings_zh-CN.i18n.json 中所有在 lib/ 下零引用的叶子 key。
删除后递归清除空的父节点。

Usage（从项目根目录运行）:
  python3 tool/prune_i18n.py [--dry-run]
"""
import json
import subprocess
import sys
from pathlib import Path
from copy import deepcopy

ROOT     = Path(__file__).parent.parent
JSON_PATH = ROOT / 'assets/translations/strings_zh-CN.i18n.json'
LIB_DIR  = ROOT / 'lib'
GEN_DIR  = ROOT / 'lib/gch_gen'

DRY_RUN  = '--dry-run' in sys.argv


def get_leaves(obj, prefix=''):
    """返回 [(full_path, getter_name)] 所有叶子"""
    results = []
    for k, v in obj.items():
        full = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            results.extend(get_leaves(v, full))
        else:
            results.append((full, k))
    return results


def has_ref(getter: str) -> bool:
    """在 lib/ 下（排除 gch_gen/）grep getter 是否有引用"""
    result = subprocess.run(
        ['grep', '-r', f'.{getter}', str(LIB_DIR),
         '--include=*.dart', f'--exclude-dir={GEN_DIR.name}', '-l'],
        capture_output=True, text=True
    )
    return bool(result.stdout.strip())


def delete_by_path(obj, path: str):
    """按点号路径删除 obj 中的 key"""
    keys = path.split('.')
    node = obj
    for k in keys[:-1]:
        if k not in node:
            return
        node = node[k]
    node.pop(keys[-1], None)


def prune_empty(obj):
    """递归删除所有值为空 dict 的节点"""
    keys_to_delete = []
    for k, v in list(obj.items()):
        if isinstance(v, dict):
            prune_empty(v)
            if not v:
                keys_to_delete.append(k)
    for k in keys_to_delete:
        del obj[k]


def main():
    data = json.loads(JSON_PATH.read_text(encoding='utf-8'))
    leaves = get_leaves(data)

    print(f"📋 共 {len(leaves)} 个叶子 key，逐一检查引用...")

    to_delete = []
    for full_path, getter in leaves:
        if not has_ref(getter):
            to_delete.append(full_path)

    print(f"\n🗑  零引用 key：{len(to_delete)} 个")
    for p in to_delete:
        print(f"  - {p}")

    if DRY_RUN:
        print("\n⚠️  Dry-run 模式，未修改文件。")
        return

    # 删除
    new_data = deepcopy(data)
    for path in to_delete:
        delete_by_path(new_data, path)

    # 清理空父节点
    prune_empty(new_data)

    # 写回（保留原始缩进风格）
    JSON_PATH.write_text(
        json.dumps(new_data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8'
    )
    print(f"\n✅ 已删除 {len(to_delete)} 个无用 key，文件已更新。")
    print("   请运行 make translate 重新生成翻译文件。")


if __name__ == '__main__':
    main()
