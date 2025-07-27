#!/usr/bin/env bun

import fs from "node:fs";

function slugify(s: string): string {
  return s
    .replaceAll(/[,`./]/g, "")
    .toLowerCase()
    .split(" ")
    .join("-");
}

type Item = string | Item[]

function is_string(s: Item): s is string {
  return typeof s === "string";
}

function md_list(sep="-*+", tab=0): ((_: Item[]) => Item[]) {
  return (xs: Item[]) => xs.flatMap(x =>
    is_string(x)
    ? ["  ".repeat(tab)+sep[0]+" "+x]
    : md_list(sep.substring(1), tab+1)(x)
  );
}

function toc(xs: Item[]): Item[] {
  return xs.map(x =>
    is_string(x)
    ? `[${x}](#${slugify(x)})`
    : toc(x)
  );
}

function content(depth=2): ((_: Item[]) => Item[]) {
  const header_prefix = "#".repeat(depth);
  return (xs: Item[]) => xs.flatMap(x =>
    is_string(x)
    ? (() => {
      const res = [header_prefix + " " + x];
      const filename = `src/${slugify(x)}.md`;
      if (fs.existsSync(filename)) {
        res.push(
          fs.readFileSync(filename).toString(),
          "",
        );
      }
      return res;
    })()
    : content(depth + 1)(x)
  );
}

const summary: Item[] = [
  "Principles",
  "Practices", [
    "Just some Go proverbs I agree with, with no details",
    "Globals",
    "Use pointers only if they are really needed",
    "Naming",
    "Group related things together",
    "Reduce variables scopes as much as you can",
    "Reduce nesting",
    "On panicking",
    "Language features",
    "Standart library", [
      "`context.Context` usage",
      "Time routines",
    ],
    "Libraries/frameworks API design, including `internal`",
    "Libraries and tools",
    "Project organization",
    "Error handling",
    "Comments",
    "Other",
  ],
];

fs.writeFileSync("README.md", [
  ...md_list()(toc(summary)),
  "",
  ...content()(summary),
  "",
].join("\n"));
