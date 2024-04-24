- if slice returned always contains exactly `n` elements, use array `[n]T` instead (`regexp` functions don't do it, though they return `[][]int` which are really `[][2]int`)
- treat most functions as ways to transform one data to another, don't make every function change something: write to Writer, change some external memory, etc
- focus on frequent path, they must be easy to use, rare path must be also usable if needed
- code must be reusable, every system might be reused in other systems, workers, crons, onetime scripts, tests etc, not being bound to some cringy DI framework and other things the system does not depend on
- don't create interfaces for single implementation
- if there are two ways to implement thing, e.g. A and B and A allows client code to do C, D, E while B allows client code only to do C, prefer A, For example, there might be two ways to write sort function
  1. one allocates copy and sorts it without modifying original slice
  1. another sorts original slice in-place

  Second way allows user to choose whether they want to allocate new array copy before sorting or not, while first way doesn't. So second way is preferable. (that is some sort of Single Responsibility criteria: do only one thing, let the client do everything around)
- use separate config for every subsystem, don't use global application configuration in subsystems
- watch [this lecture](https://www.youtube.com/watch?v=ZQ5_u8Lgvyk) and see [some formal techniques](./reusability.md) to build reusable components
- [Avoid package names like base, util, or common](https://dave.cheney.net/2019/01/08/avoid-package-names-like-base-util-or-common)
- prefer to name package same as directory name, e.g. `module/abc/def/pkg` must have `package pkg`
    - given that, it is prohibited to use hyphen in package (actually directory) names
- prefer to avoid allocations, using parallelism in library code, or try to give user control over them
- avoid boolean args, `getData(id, true)` is unclear about what does `true` mean