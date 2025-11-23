# Word Wrap Enhancement for uEmacs/PK

## Summary

Enhanced uEmacs with proper word wrap functionality for command-line word processing. The editor now supports dynamic wrapping at the terminal edge with configurable margins.

## What Was Added

### 1. New Command: `set-fill-window`

**File:** `random.c:33`

Sets the fill column to terminal width minus an optional margin.

```c
int setfillwindow(int f, int n)
```

**Usage:**
- `M-x set-fill-window` - Sets to full terminal width
- `ESC 8 M-x set-fill-window` - Sets to terminal width minus 8 columns

**Bound in:** `names.c:195` as "set-fill-window"

### 2. New Environment Variable: `$wrapmargin`

**Files Modified:**
- `evar.h:66` - Added to `envars[]` array
- `evar.h:112` - Added `#define EVWRAPMARGIN 41`
- `eval.c:323` - Added getter in `gtenv()`
- `eval.c:677` - Added setter in `svar()`
- `globals.c:7` - Defined global `int wrapmargin = 0`
- `edef.h:22` - Declared extern

**Purpose:** When set to a positive value, automatically wraps text at terminal width minus this margin, overriding `$fillcol`.

**Usage:**
```
set $wrapmargin 8
```

### 3. Enhanced Auto-Wrap Logic

**File:** `main.c:494`

Modified the word wrap trigger in `execute()` to:
1. Check if `$wrapmargin` is set (> 0)
2. If yes, calculate wrap column as `term.t_ncol - wrapmargin`
3. Otherwise, fall back to `$fillcol`
4. Trigger wrap when column exceeds calculated wrap point

**Before:**
```c
if (c == ' ' && (curwp->w_bufp->b_mode & MDWRAP) && fillcol > 0 &&
    n >= 0 && getccol(FALSE) > fillcol &&
    (curwp->w_bufp->b_mode & MDVIEW) == FALSE)
    execute(META | SPEC | 'W', FALSE, 1);
```

**After:**
```c
if (c == ' ' && (curwp->w_bufp->b_mode & MDWRAP) && n >= 0 &&
    (curwp->w_bufp->b_mode & MDVIEW) == FALSE) {
    int wrapcol = fillcol;
    if (wrapmargin > 0 && wrapmargin < term.t_ncol)
        wrapcol = term.t_ncol - wrapmargin;
    if (wrapcol > 0 && getccol(FALSE) > wrapcol)
        execute(META | SPEC | 'W', FALSE, 1);
}
```

## Files Modified

1. `random.c` - Added `setfillwindow()` function
2. `efunc.h` - Added function declaration
3. `names.c` - Added name binding
4. `evar.h` - Added `$wrapmargin` variable definition
5. `eval.c` - Added getter/setter for `$wrapmargin`
6. `globals.c` - Defined `wrapmargin` global
7. `edef.h` - Declared `wrapmargin` extern
8. `main.c` - Enhanced auto-wrap logic in `execute()`

## How to Use

### Quick Start for Word Processing

```
./em myfile.txt
M-x add-mode [return] wrap [return]
ESC 8 M-x set-fill-window [return]
```

Now type freely - text will automatically wrap 8 columns from the right edge.

### Permanent Configuration

Add to `~/.emacsrc` (or `emacs.rc`):

```
; Enable wrap mode for all buffers
add-global-mode wrap

; Set automatic margin-based wrapping
set $wrapmargin 8
```

### Dynamic Terminal Resizing

The `$wrapmargin` approach automatically adjusts when you resize your terminal:
- Terminal is 80 columns wide, margin is 8 → wraps at column 72
- Resize terminal to 120 columns → now wraps at column 112
- No need to reconfigure!

### Manual Column Setting

If you prefer a fixed column regardless of terminal size:

```
ESC 72 M-x set-fill-column
```

Or in `.emacsrc`:
```
set $fillcol 72
```

## Design Decisions

1. **Margin vs. Fixed Column:** Added `$wrapmargin` rather than just the command because:
   - Enables dynamic adjustment to terminal resizing
   - More natural for terminal-based word processing
   - Preserves the original `$fillcol` behavior for backward compatibility

2. **Priority:** `$wrapmargin` overrides `$fillcol` when set because:
   - The margin approach is explicitly for terminal edge wrapping
   - Makes the behavior predictable and intentional
   - Users can still use `$fillcol` by setting `$wrapmargin` to 0

3. **Integration:** Modified `execute()` rather than `wrapword()` because:
   - The wrap trigger logic lives in `execute()`
   - Keeps the change localized to one logical place
   - `wrapword()` just performs the wrap action, doesn't decide when

## Testing

Build and test:

```bash
make clean && make
./em test_wrap.txt
```

Then try:
1. `M-x add-mode` → `wrap`
2. `M-x set` → `$wrapmargin` → `8`
3. Type a long line with spaces and watch it wrap automatically

Or use the command approach:
1. `M-x add-mode` → `wrap`
2. `ESC 8 M-x set-fill-window`
3. Type and watch it wrap

## Compatibility

- Fully backward compatible
- Existing `$fillcol` behavior unchanged when `$wrapmargin` is 0 (default)
- Existing `set-fill-column` command still works
- All existing key bindings and modes unaffected

## Future Enhancements (Ideas)

- Auto-enable wrap mode when `$wrapmargin` is set
- Hook to auto-set margin on terminal resize
- Per-buffer margin settings
- Visual indicator showing wrap column

## Acknowledgment

After 38 years of faithful service for coding, uEmacs now serves equally well for command-line word processing.
