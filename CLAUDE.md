# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About uEmacs/PK

uEmacs/PK 4.0 is a small, portable text editor based on MicroEMACS 3.9e. It's written in C and designed to be highly portable across UNIX, VMS, and MS-DOS platforms. The codebase is approximately 17,600 lines of C code prioritizing simplicity and portability over feature bloat.

## Building and Running

```bash
# Build the editor
make

# Build with verbose output
make V=1

# Clean build artifacts
rm -f em core lintout makeout tags makefile.bak *.o
# or use
make clean

# Install (requires appropriate permissions)
make install  # Installs to /usr/bin and /usr/lib by default

# Run the editor
./em [filename]
./em +<n>        # Start at line n
./em -g<n>       # Go to line n
./em --help      # Show usage
./em --version   # Show version
```

The Makefile automatically detects the platform (Linux, FreeBSD, Darwin) and sets appropriate compiler flags via the `DEFINES` variable.

## Architecture Overview

### Core Data Structures

**Line Structure** (`line.h`, `line.c`):
- Text is stored in circularly-linked lists of `struct line`
- Each line contains: forward/backward pointers, size, used bytes, and text array
- The header line is a blank line beyond the end of buffer
- Lines do NOT store end-of-line characters (implied)

**Buffer Structure** (`estruct.h:452`, `buffer.c`):
- Each buffer has: name, filename, mode flags, point/mark positions, window count
- Buffers are kept in a linked list (`bheadp` is the head)
- Special buffer `*List*` stores buffer listings
- Modes include: WRAP, CMOD, EXACT, VIEW, OVER, MAGIC, CRYPT, ASAVE

**Window Structure** (`estruct.h:410`, `window.c`):
- Multiple windows can display the same buffer
- Each window tracks: buffer pointer, top line, cursor position (dot), mark position
- Windows linked via `w_wndp`; `wheadp` is head, `curwp` is current
- Update flags (WFFORCE, WFMOVE, WFEDIT, WFHARD, WFMODE) guide redisplay

**Terminal Abstraction** (`estruct.h:506`):
- `struct terminal` provides function pointers for platform-specific I/O
- Implementations in: `posix.c` (UNIX), `ansi.c`, `vmsvt.c`, `ibmpc.c`, `tcap.c`
- Accessed via macros: `TTopen`, `TTclose`, `TTgetc`, `TTputc`, `TTmove`, etc.

### Key Subsystems

**Display System** (`display.c`):
- Two-screen model: virtual screen (`vscreen`) and physical screen (`pscreen`)
- Virtual screen updated by commands, then synced to physical screen
- Smart redisplay algorithm with scrolling support (borrowed from vile)
- Uses window flags to minimize redraws (WFFORCE, WFMOVE, WFEDIT, WFHARD)
- `update(FALSE)` is the main redisplay entry point called from main loop

**Command Execution** (`main.c:473`):
- Main loop in `main()` at line 305: get command, execute, update display
- `execute()` binds keys to functions or handles self-inserting characters
- Key bindings stored in `keytab[]` array (defined in `ebind.h`)
- Function pointers are `fn_t` type: `int (*)(int f, int n)`

**Key Binding System** (`bind.c`, `ebind.h`):
- `keytab[]` maps key codes to function pointers
- `names[]` table maps function names to pointers (for M-x commands)
- Keys can have META, CTRL, CTLX, or SPEC modifiers (see `estruct.h:240`)
- `getbind()` looks up function for a key code

**Search and Replace** (`search.c`, `isearch.c`):
- Regular search: `forwsearch`, `backsearch`, `sreplace`, `qreplace`
- Incremental search: `fisearch`, `risearch`
- Magic mode (MAGIC=1) enables regex via `struct magic` (`estruct.h:667`)
- Pattern stored in global `pat[]`, replacement in `rpat[]`

**File I/O** (`file.c`, `fileio.c`):
- `file.c` handles high-level operations (read, write, save, find)
- `fileio.c` provides low-level I/O primitives
- Encryption support via `crypt.c` when CRYPT mode enabled
- File locking on BSD/SVR4 via `lock.c` and `pklock.c`

**Macro System** (`exec.c`, `eval.c`):
- Keyboard macros: C-X ( to start, C-X ) to end, C-X E to execute
- Named procedures via `!store` directive
- Variables prefixed with `$` (environment) or `%` (user)
- Control flow: `!if`, `!else`, `!endif`, `!while`, `!endwhile`, `!goto`, `!return`
- Startup file: `emacs.rc` (or `.emacsrc`)

### Important Header Files

- `estruct.h` - All structure definitions, platform detection, configuration
- `edef.h` - Global variable declarations (extern)
- `efunc.h` - Function declarations organized by source file
- `ebind.h` - Default key bindings table
- `evar.h` - Environment variable table
- `epath.h` - Search paths for startup files

### Platform Support

The code uses conditional compilation via `#if PLATFORM` macros:
- `AUTOCONF` - Automatic configuration (preferred)
- `MSDOS` - MS-DOS with Turbo C or MSC
- `BSD` - Berkeley UNIX
- `USG` / `SYSV` / `SVR4` - System V variants
- `VMS` - VAX/VMS
- `POSIX` - POSIX systems

Platform-specific code is isolated in: `posix.c`, `ibmpc.c`, `vmsvt.c`, `ansi.c`, `vt52.c`

### UTF-8 Support

UTF-8 handling in `utf8.c` and `utf8.h`:
- `unicode_t` type for Unicode code points
- Display system works with UTF-8 encoded text
- Character operations account for multi-byte sequences

## Code Conventions

- Global variables declared in `edef.h` with `extern`, defined in corresponding `.c` files
- Function declarations in `efunc.h`, organized by source file
- Functions take `(int f, int n)` parameters: `f` is flag for argument present, `n` is numeric argument
- Return values: `TRUE` (1), `FALSE` (0), `ABORT` (2), `FAILED` (3)
- Window update hints set via `wp->w_flag |= WFEDIT` or similar
- Use `mlwrite()` for message line output, `TTbeep()` for error beep

## Common Modification Patterns

**Adding a new command:**
1. Implement function in appropriate `.c` file with signature `int cmd(int f, int n)`
2. Add `extern` declaration to `efunc.h` in the appropriate section
3. Add to `names[]` table in `names.c` for M-x access
4. Optionally bind to key in `ebind.h` or via `bind-to-key` command

**Modifying display behavior:**
- Virtual screen updated by setting `curwp->w_flag` bits
- Physical update happens in `display.c:update()`
- Mode line updates via `upmode()`, triggered by WFMODE flag

**Adding a buffer mode:**
1. Define bit in `estruct.h` mode flags section (around line 477)
2. Add name to `modename[]` and letter to `modecode[]` in `globals.c`
3. Implement mode-specific behavior in `execute()` or command handlers
