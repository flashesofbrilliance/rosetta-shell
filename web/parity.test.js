#!/usr/bin/env node
// Parity gate: the lint rules inside web/rosetta-voice.html must produce
// byte-identical output to `bin/rosetta lint` on every sample script.
// Usage: node web/parity.test.js   (exit 0 = identical, 1 = drift)
"use strict";
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const html = fs.readFileSync(path.join(__dirname, "rosetta-voice.html"), "utf8");
const m = html.match(/\/\/ RULES-BEGIN[\s\S]*?\n([\s\S]*?)\/\/ RULES-END/);
if (!m) { console.error("parity: RULES-BEGIN/RULES-END block not found"); process.exit(1); }
const { RULES, lintLine } = new Function(m[1] + "\nreturn { RULES, lintLine };")();

const files = [
  "examples/non-portable-sample.sh",
  "examples/translate-demo.sh",
  "web/parity-lines.sh",
  ...fs.readdirSync(path.join(root, "conformance/fixtures")).map((f) => "conformance/fixtures/" + f),
].filter((f) => f.endsWith(".sh"));

let fail = 0;
for (const f of files) {
  const text = fs.readFileSync(path.join(root, f), "utf8");
  const lines = text.split("\n");
  if (lines[lines.length - 1] === "") lines.pop(); // read loop sees no line after a final newline
  let js = "", n = 0;
  lines.forEach((line, i) => {
    for (const r of lintLine(line)) { js += `${f}:${i + 1}: ${r.msg}\n     -> ${r.fix}\n`; n++; }
  });
  js += `\n${n} finding(s).\n`;
  const sh = spawnSync("sh", ["bin/rosetta", "lint", f], { cwd: root, encoding: "utf8" }).stdout;
  if (sh === js) { console.log(`ok   ${f} (${n} findings)`); }
  else { fail++; console.log(`DIFF ${f}\n--- bin/rosetta\n${sh}--- web\n${js}`); }
}
console.log(fail ? `\nparity: ${fail} file(s) differ` : `\nparity: all ${files.length} files identical (${RULES.length} rules)`);
process.exit(fail ? 1 : 0);
