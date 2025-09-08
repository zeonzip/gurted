# Gurted

Gurted (verb)
> “to do something smart, but also dangerous”

Wayfinder (noun)
> “a person helping others navigate”

Gurted is an ecosystem similar to the World Wide Web, it features:
- It's own **Viewfinder** (a custom browser named Flumi) written in Rust and GDScript with [Godot](https://godotengine.org/),
- A custom HTML, CSS and ***Lua*** engine (We do **not like javascript**)
- A custom **DNS** that allows users to create domains with TLDs such as `.based`, `.delulu`, `.aura`, `.twin` and many more.
- A search engine called **Ringle**.

![Preview of Flumi, the official gurted wayfinder](https://raw.githubusercontent.com/outpoot/gurted/refs/heads/main/images/flumi.png?token=GHSAT0AAAAAADIOOUTXJNIN6EFPUEPJVQCK2F6XLTA)

# File structure
- `/dns` - The source code for the **DNS** (Domain Name System)
- `/docs` - The source code for the **Documentation page** available at https://docs.gurted.com
- `/flumi` - The source code for the **Wayfinder** Flumi, used to view gurt:// sites
- `/protocol` - Source code for all gurt related things, like the gdextension and the rust library
- `/search-engine` - The Source code for the official **search engine** (Ringle)

# Download and install

## Windows 
Grab the binary from the [releases page](https://github.com/outpoot/gurted/releases) and run it

## Linux
Download the binary from [releases page](https://github.com/outpoot/gurted/releases) and run it.

## MacOS
Download the binary from the [releases page](https://github.com/outpoot/gurted/releases) and copy it to your applications folder.

# Compiling
The process is identycal to compiling a godot game, however if you modified the protocol library or the gdextension you have to rebuild the gurted gdextension library by running build.sh in `/protocol/gdextension` and copy `/protocol/gdextension/target/x86_64-unknown-linux-gnu/release/libgurt_godot.so` (or the windows/macos library) to `flumi/addons/gurt-protocol/bin/linux` or `flumi/addons/gurt-protocol/bin/windows` for windows.
