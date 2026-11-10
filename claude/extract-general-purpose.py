# Pull the built-in general-purpose subagent out of the claude-code binary and
# re-emit it as ~/.claude/agents/general-purpose.md with extra frontmatter.
# usage: extract-general-purpose.py <claude binary> <autoCompactWindow> <out.md>
import json
import re
import sys

binary, window, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
data = open(binary, "rb").read()


def die(msg):
    sys.exit(f"extract-general-purpose: {msg} (claude-code bundle layout changed?)")


anchor = data.find(b'agentType:"general-purpose",whenToUse:"')
if anchor < 0:
    die("general-purpose agent definition not found")

# whenToUse is a plain JS double-quoted string
m = re.compile(rb'whenToUse:("(?:[^"\\]|\\.)*")').match(data, anchor + len(b'agentType:"general-purpose",'))
if not m:
    die("whenToUse not found")
description = json.loads(m.group(1).decode())

# the prompt function immediately precedes the definition:
#   function X(){return`${"You are an agent ..."} ... ${`Your strengths: ...`}`}var Y={agentType:...
start = data.rfind(b"You are an agent for Claude Code", 0, anchor)
ret = data.rfind(b"return`", 0, start)
end = data.rfind(b"`}var ", 0, anchor)
if min(start, ret, end) < 0 or not (ret < start < end) or anchor - ret > 20000:
    die("prompt function not found")
body = data[ret + len(b"return`") : end].decode()

# only literal interpolations are expected: ${"..."} and ${`...`}
body = re.sub(r'\$\{("(?:[^"\\]|\\.)*")\}', lambda m: json.loads(m.group(1)), body)
body = re.sub(r"\$\{`([^`$]*)`\}", lambda m: m.group(1), body, flags=re.S)
if "${" in body or "`" in body:
    die("prompt has non-literal interpolation")
prompt = re.sub(r"\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), body)
prompt = prompt.replace("\\`", "`").replace("\\$", "$").replace("\\\\", "\\")
if "You are an agent for Claude Code" not in prompt or len(prompt) < 200:
    die("extracted prompt looks wrong")

frontmatter = {
    "name": "general-purpose",
    "description": description,
    "tools": "*",
    "autoCompactWindow": window,
}
with open(out, "w") as f:
    f.write("---\n")
    for k, v in frontmatter.items():
        f.write(f"{k}: {json.dumps(v, ensure_ascii=False)}\n")
    f.write("---\n\n" + prompt.strip() + "\n")
