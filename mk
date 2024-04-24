#!/usr/bin/awk BEGIN{for (i=2; i<ARGC; i++) { subslice = subslice ARGV[i] " " }; system("risor "ARGV[1]" -- "subslice)}

func slugify(s) {
  return s |
    strings.replace_all(",", "") |
    strings.replace_all("`", "") |
    strings.replace_all(".", "") |
    strings.replace_all("/", "") |
    strings.to_lower |
    strings.split(" ") |
    strings.join("-")
}

func md_list(xs, sep="-*+", tab="") {
  res := ""
  for _, x := range xs {
    if type(x) == "string" {
      res += '{tab}{sep[0]} {x}\n'
    } else {
      res += md_list(x, sep[1:], tab+"   ")
    }
  }
  return res
}

func toc(xs) {
  res := []
  for _, x := range xs {
    if type(x) == "string" {
      res.append('[{x}](#{x | slugify})')
    } else {
      res.append(toc(x))
    }
  }
  return res
}

func content(xs, depth=2) {
  res := ""
  header_prefix := strings.repeat("#", depth)
  for _, x := range xs {
    if type(x) == "string" {
      res += header_prefix + " " + x + "\n"
      filename := filepath.join("src", slugify(x) + ".md")
      cntnt := try(func() {return os.read_file(filename)}, nil)
      if cntnt != nil {
        res += string(cntnt) + "\n\n"
      }
    } else {
      res += content(x, depth+1)
    }
  }
  return res
}

summary := [
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
]

os.write_file("README.md",
  (summary | toc | md_list) +
  (summary | content),
)