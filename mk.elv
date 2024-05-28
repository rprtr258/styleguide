#!/usr/bin/env elvish

use "str"
fn str-to-lower { each {|s| put (str:to-lower $s)} }
fn str-split {|sep| each {|s| str:split $sep $s} }

use "re"
fn re-replace {|pattern sub| each {|s| put (re:replace $pattern $sub $s)} }

fn slugify {|s|
  all [$s] |
    re-replace "[,`./]" "" |
    str-to-lower |
    str-split " " |
    str:join "-"
}

fn is_string {|s| put (==s (kind-of $s) "string")}

fn md_list {|&sep="-*+" &tab=0|
  each {|x|
    if (is_string $x) {
      put (repeat $tab "  " | str:join "")$sep[0]" "$x
    } else {
      all $x | md_list &sep=$sep[1..] &tab=(+ $tab 1)
    }
  }
}

fn toc {
  each {|x|
    if (is_string $x) {
      put "["$x"](#"(slugify $x)")"
    } else {
      all $x | toc | put [(all)]
    }
  }
}

fn content {|&depth=2|
  var header_prefix = (repeat $depth "#" | str:join "")
  each {|x|
    if (is_string $x) {
      put $header_prefix" "$x
      var filename = "src/"(slugify $x)".md"
      if ?(test -f $filename) {
        put (cat $filename | slurp)
        put ""
      }
    } else {
      all $x | content &depth=(+ $depth 1)
    }
  }
}

var summary = [
  "Principles"
  "Practices" [
    "Just some Go proverbs I agree with, with no details"
    "Globals"
    "Use pointers only if they are really needed"
    "Naming"
    "Group related things together"
    "Reduce variables scopes as much as you can"
    "Reduce nesting"
    "On panicking"
    "Language features"
    "Standart library" [
      "`context.Context` usage"
      "Time routines"
    ]
    "Libraries/frameworks API design, including `internal`"
    "Libraries and tools"
    "Project organization"
    "Error handling"
    "Comments"
    "Other"
  ]
]

echo ({
  all $summary | toc | md_list
  put ""
  all $summary | content
} | str:join "\n") > "README.md"