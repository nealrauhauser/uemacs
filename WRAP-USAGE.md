# Word Wrap Usage Guide

uEmacs now has enhanced word wrap functionality for command-line word processing.

## Commands

### set-fill-window
Set the fill column to the terminal width minus an optional margin.

Usage:
- `M-x set-fill-window` - Sets fill column to full terminal width
- `ESC <n> M-x set-fill-window` - Sets fill column to terminal width minus n columns

Example: `ESC 8 M-x set-fill-window` sets the fill column to 8 columns less than terminal width

### set-fill-column (existing)
Set fill column to a specific number.

Usage: `ESC <n> M-x set-fill-column`

Example: `ESC 72 M-x set-fill-column` sets fill column to 72

## Environment Variables

### $fillcol (existing)
The current fill column setting.

### $wrapmargin (new)
Right margin for automatic word wrapping (0=disabled).

When set to a non-zero value, wrap mode will automatically wrap at
terminal width minus this margin, overriding fillcol.

Usage in emacs.rc:
```
set $wrapmargin 8
```

This dynamically adjusts wrapping as the terminal is resized.

### $curwidth (existing)
Returns the current terminal width. Useful in macros.

## Modes

### WRAP mode (existing)
Enable word wrap mode for a buffer.

Usage:
- `M-x add-mode` then type `wrap`
- Or in emacs.rc: `add-mode wrap`

## Typical Setup for Word Processing

Add to your ~/.emacsrc (or emacs.rc):

```
; Enable wrap mode globally
add-global-mode wrap

; Set wrap margin to 8 columns from right edge
set $wrapmargin 8

; Or use a specific column:
; set $fillcol 72
```

## How It Works

When WRAP mode is enabled:
1. If $wrapmargin > 0, text wraps at (terminal width - wrapmargin)
2. Otherwise, text wraps at $fillcol
3. Wrapping occurs when you type a space past the wrap column

The wrapmargin approach is better for terminal use because it automatically
adjusts when you resize the terminal window.

## Examples

### Quick setup for current buffer:
```
M-x add-mode [wrap]
ESC 8 M-x set-fill-window
```

Now type and your text will wrap 8 columns from the right edge.

### Reformatting Text:

**Key Bindings:**

- **`ESC O`** (or `M-O`) - **Reformat entire buffer** - **RECOMMENDED**
  - Reformats all paragraphs in the buffer to fit current wrap column
  - Perfect for when you resize your terminal window!
  - Home row convenience key

- **`ESC Q`** (or `M-Q`) - Fill single paragraph (traditional Emacs)
  - Only reformats the paragraph where cursor is located

- **`ESC J`** (or `M-J`) - Justify paragraph
  - Fills with left margin preserved

**Usage:**

**Most Common: Just hit `ESC O`!**
- Open file with wrap mode enabled
- Resize your terminal window
- Press `ESC` then `O` - entire buffer reformats to new width
- Done!

**Or use commands:**
```
M-x fill-all-paragraphs  (reformat entire buffer)
M-x fill-paragraph       (reformat one paragraph)
M-x justify-paragraph    (reformat with left margin)
```

**Important:** Paragraphs are delimited by blank lines. The fill commands will preserve blank line spacing.
