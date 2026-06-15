from __future__ import annotations

import base64
import collections
import json
import re
import sys


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def redact_secret(text: str) -> str:
    return re.sub(r"sk-or-v1-[A-Za-z0-9_-]+", "sk-or-v1-[REDACTED]", text)


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "run_output.json"
    with open(path, encoding="utf-8") as f:
        run = json.load(f)

    results = run.get("results", [])
    status_counts = collections.Counter(r.get("status") for r in results)
    print(f"phase={run.get('phase')} n={len(results)} status={dict(status_counts)}")

    bad = [r for r in results if r.get("status") != "ok"]
    if bad:
        print("\nFirst non-ok rows:")
        for row in bad[:5]:
            print(f"- {row.get('qid')}: {row.get('status')} | {row.get('question')}")

    sealed = run.get("sealed", {})
    data = sealed.get("data")
    if data:
        try:
            decoded = json.loads(base64.b64decode(data).decode("utf-8"))
        except Exception as exc:
            print(f"\nCould not decode sealed data: {exc}")
            return 0

        errors = collections.Counter()
        providers = collections.Counter()
        models = collections.Counter()
        for item in decoded:
            if item.get("error"):
                errors[item["error"]] += 1
            if item.get("provider"):
                providers[item["provider"]] += 1
            if item.get("model"):
                models[item["model"]] += 1

        if errors:
            print("\nSealed errors:")
            for error, count in errors.most_common(5):
                print(f"- x{count}: {redact_secret(error)}")
        if providers:
            print(f"\nProviders: {dict(providers)}")
        if models:
            print(f"Models: {dict(models)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
