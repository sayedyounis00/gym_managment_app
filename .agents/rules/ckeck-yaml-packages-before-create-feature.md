---
trigger: always_on
---

Before writing or planning any code for a task, you MUST:

1. **Read `pubspec.yaml` first.** Review `dependencies` and `dev_dependencies` to see which packages are already installed, along with their versions.

2. **Use existing packages first.** If an installed package already solves the need (state management, routing, DI, networking, local storage, formatting, etc.), use it. Do not write custom code or add a second package that does the same job.

3. **Stay consistent with the project's stack.** Follow the patterns of the packages already in use. For example, if the project uses `flutter_bloc`, use Cubit/Bloc for state. Don't introduce Provider, GetX, or setState-based logic.

4. **Do not add a new package unless necessary.** Only add one if no installed package can reasonably do the job. When you do:
   - Explain why it's needed and which existing packages were considered.
   - Prefer well-maintained, popular packages compatible with the project's Dart/Flutter SDK constraints.
   - Add it with `flutter pub add <package>`. Never edit versions by hand or guess version numbers.

5. **Never use a package that isn't listed in `pubspec.yaml`.** Don't import something that isn't declared, even if it happens to be available transitively.

6. **Respect versions.** Use APIs that match the installed version of each package. If unsure, check the package's docs or source in the pub cache instead of relying on memory.

7. **State your findings briefly.** At the start of each task, list in one or two lines which existing packages you'll use for it.