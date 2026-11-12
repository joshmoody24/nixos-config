#!/usr/bin/env node
// PreToolUse hook: blocks Edit/Write/MultiEdit on C-style source files when an
// edit introduces an over-long comment. "why" lives in the repo's AGENTS.md.

const MAX_BLOCK_LINES = 2; // consecutive comment lines allowed before blocking
const MAX_LINE_CHARS = 120; // failsafe: max comment-text chars on a single line

const EXTS = new Set([
  "ts",
  "tsx",
  "js",
  "jsx",
  "mjs",
  "cjs",
  "c",
  "h",
  "cpp",
  "cc",
  "hpp",
  "go",
  "rs",
  "java",
  "cs",
  "swift",
  "kt",
  "scala",
  "php",
]);

const canPrecedeRegex = (ch) =>
  ch === undefined || "(,=:[!&|?{};~+-*%^<>".includes(ch);

// Returns an array of { line, len } for every line bearing comment content.
const scanComments = (src) => {
  const perLine = new Map(); // line number -> comment-text char count
  const add = (line, n) => perLine.set(line, (perLine.get(line) || 0) + n);

  let state = "normal"; // normal | sq | dq | tpl | line | block | regex
  let line = 1;
  let lastSig; // last non-whitespace char in normal context

  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    const next = src[i + 1];
    if (c === "\n") {
      line++;
      if (state === "line") state = "normal";
      continue;
    }

    switch (state) {
      case "normal":
        if (c === "/" && next === "/") {
          state = "line";
          i++;
        } else if (c === "/" && next === "*") {
          state = "block";
          add(line, 0);
          i++;
        } else if (c === "/" && canPrecedeRegex(lastSig)) state = "regex";
        else if (c === "'") state = "sq";
        else if (c === '"') state = "dq";
        else if (c === "`") state = "tpl";
        if (!/\s/.test(c)) lastSig = c;
        break;
      case "sq":
        if (c === "\\") i++;
        else if (c === "'") state = "normal";
        break;
      case "dq":
        if (c === "\\") i++;
        else if (c === '"') state = "normal";
        break;
      case "tpl":
        if (c === "\\") i++;
        else if (c === "`") state = "normal";
        break;
      case "regex":
        if (c === "\\") i++;
        else if (c === "/") state = "normal";
        break;
      case "line":
        add(line, 1);
        break;
      case "block":
        add(line, 0);
        if (c === "*" && next === "/") {
          state = "normal";
          i++;
        } else if (!/\s/.test(c)) add(line, 1);
        break;
    }
  }
  return perLine;
};

const violations = (perLine) => {
  const out = [];
  const lines = [...perLine.keys()].sort((a, b) => a - b);

  for (const [line, len] of perLine) {
    if (len > MAX_LINE_CHARS) {
      out.push(`line ${line}: comment is ${len} chars (max ${MAX_LINE_CHARS})`);
    }
  }

  let runStart = null;
  let prev = null;
  const flush = (end) => {
    if (runStart !== null && end - runStart + 1 > MAX_BLOCK_LINES) {
      out.push(
        `lines ${runStart}-${end}: ${end - runStart + 1}-line comment block ` +
          `(max ${MAX_BLOCK_LINES})`,
      );
    }
  };
  for (const line of lines) {
    if (prev !== null && line === prev + 1) {
      // extend run
    } else {
      if (prev !== null) flush(prev);
      runStart = line;
    }
    prev = line;
  }
  if (prev !== null) flush(prev);

  return out;
};

const IMPORTANT_COMMENT = /\/\*\*\*[\s\S]*?(?:\*\/|$)/g;

const IMPORTANT_COMMENT_NOTES = {
  added: {
    user: "added a /*** comment",
    agent:
      "This edit adds a /*** comment. /*** marks a comment a human wrote and " +
      "considers important. Unless the user gave you these exact words for " +
      "this spot, delete it now. If you think a /*** comment would really " +
      "help here, ask the user whether they agree and what it should say, " +
      "then use exactly their words, fixing only formatting and typos.",
  },
  changed: {
    user: "changed a human-written /*** comment",
    agent:
      "This edit changes or removes a /*** comment, which a human wrote to " +
      "mark something important. Treat it with care: keep its meaning unless " +
      "you were asked to change it, and tell the user what you changed.",
  },
};

const importantComments = (text) => text.match(IMPORTANT_COMMENT) ?? [];

// Which of "added" and "changed" apply to an edit's /*** comments.
const importantCommentChanges = (before, after) => {
  const was = importantComments(before);
  const now = importantComments(after);
  const count = (list, comment) => list.filter((c) => c === comment).length;
  return [
    ...(now.length > was.length ? ["added"] : []),
    ...(was.some((c) => count(was, c) > count(now, c)) ? ["changed"] : []),
  ];
};

const applyEdit = (text, { old_string = "", new_string = "", replace_all }) =>
  replace_all
    ? text.replaceAll(old_string, () => new_string)
    : text.replace(old_string, () => new_string);

const beforeAndAfter = (path, ti) => {
  const fs = require("fs");
  const before = fs.existsSync(path) ? fs.readFileSync(path, "utf8") : "";
  if (typeof ti.content === "string") return { before, after: ti.content };
  const edits = Array.isArray(ti.edits) ? ti.edits : [ti];
  return { before, after: edits.reduce(applyEdit, before) };
};

const main = () => {
  const raw = require("fs").readFileSync(0, "utf8");
  const input = JSON.parse(raw);
  const ti = input.tool_input || {};
  const path = ti.file_path || "";
  const ext = path.split(".").pop().toLowerCase();
  if (!EXTS.has(ext)) process.exit(0);

  const text = (() => {
    if (Array.isArray(ti.edits))
      return ti.edits.map((e) => e.new_string || "").join("\n");
    return ti.new_string ?? ti.content ?? "";
  })();

  const { before, after } = beforeAndAfter(path, ti);
  const notes = importantCommentChanges(before, after).map(
    (kind) => IMPORTANT_COMMENT_NOTES[kind],
  );

  const found = text ? violations(scanComments(text)) : [];
  if (found.length === 0) {
    if (notes.length > 0) {
      process.stdout.write(
        JSON.stringify({
          systemMessage: notes
            .map((n) => `Heads up: an agent ${n.user} in ${path}.`)
            .join("\n"),
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            additionalContext: notes.map((n) => n.agent).join("\n\n"),
          },
        }),
      );
    }
    process.exit(0);
  }

  process.stderr.write(
    `Comment guard blocked this edit to ${path}:\n` +
      found.map((v) => `  - ${v}`).join("\n") +
      `\n\nKeep comments short. Remove or condense ` +
      `the flagged comment(s), then retry. Err on the side of removal.\n`,
  );
  process.exit(2);
};

try {
  main();
} catch (e) {
  // Never block edits on a hook bug; fail open.
  process.stderr.write(
    `comment-guard hook error (failing open): ${e.message}\n`,
  );
  process.exit(0);
}
