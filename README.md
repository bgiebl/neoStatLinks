# neoStatLinks

A lightweight Lua library for real-time link processing, parsing, and text rewriting in event-driven applications. This module provides robust pattern matching, string manipulation, and hook-based interception mechanisms for transforming structured link formats.

## Overview

neoStatLinks is a modular link processing system that intercepts and rewrites structured link formats in real-time. It employs advanced pattern matching, multi-strategy parsing, and extensible hook mechanisms to process and transform link data dynamically.

## Features

- **Real-time Link Processing**: Intercepts and processes links as they're generated
- **Multi-Pattern Parsing**: Robust parsing with multiple fallback strategies for varied link formats
- **Hook-Based Architecture**: Supports both direct function replacement and library-based hooking (py_hook)
- **Hexadecimal Data Processing**: Converts and processes hexadecimal-encoded structured data
- **Configurable Debug System**: Conditional debug logging for development and troubleshooting
- **Persistent Settings**: Settings persistence across sessions
- **Event-Driven Design**: Integrates with application lifecycle events

## Architecture

### Core Components

#### Link Parser (`parse_item_link`)
Parses structured link formats using pattern matching and extracts:
- Item identifiers and metadata
- Attribute pairs (stat12, stat34, stat56)
- Bind status and properties
- Rune configurations
- Durability information
- Color encoding
- Name extraction

The parser implements multiple pattern matching strategies with progressive fallback:
1. Full pattern with color encoding
2. Pattern without color
3. Simplified vendor link format
4. Color-only variant

#### Link Rewriter (`RewriteLink`)
Processes parsed link data and applies transformations based on:
- Identifier ranges
- Attribute counts
- Tier calculations
- Stat name resolution

Uses pattern escaping to safely replace link text while preserving format integrity.

#### Hook Management

**Direct Hooking Mode:**
```lua
_G.ChatEdit_AddItemLink = self.ChatEdit_AddItemLink
```

**Library-Based Hooking (py_hook):**
- Registers hooks via `py_hook.AddHook()`
- Supports hook chaining with `nextfn` parameter
- Handles hook registration/unregistration events
- Fallback to direct mode if library unavailable

### String Processing

#### Pattern Escaping (`EscapePattern`)
Escapes special regex characters to enable safe string replacement:
- Handles: `( ) . + - * ? [ ] ^ $ %`
- Uses Lua pattern escape syntax (`%%` prefix)

#### Stat Name Resolution (`_getStatName`)
Resolves stat identifiers to human-readable names using:
- Direct lookup strategies
- Offset-based resolution (0x70000, 500000)
- Multiple fallback mechanisms

### Event System

The library integrates with application lifecycle events:

- **VARIABLES_LOADED**: Initialization and hook setup
- **REGISTER_HOOKS**: Hook registration via event system
- **UNREGISTER_HOOKS**: Hook cleanup
- **PLAYER_ENTERING_WORLD**: Backup hook registration trigger

## Technical Implementation

### Data Structures

#### Parsed Link Object
```lua
{
    itemID = number,
    bindType = number,
    unbound = boolean,
    bindOnEquip = boolean,
    skillExtracted = boolean,
    stats = { stat1, stat2, ... },
    runes = { rune1, rune2, rune3, rune4 },
    emptyRuneSlots = number,
    plus = number,
    tier_add = number,
    rarity_add = number,
    max_dur = number,
    dur = number,
    hash = number,
    color = string,
    misc = number,
    name = string
}
```

### Hex Processing

The library processes hexadecimal-encoded fields:
- Converts hex strings to decimal using `tonumber(value, 16)`
- Extracts bit fields from packed hex values
- Handles variable-length hex strings

### Tier Calculation

Calculates tier from identifier ranges:
```lua
tier = itemID - ManaStoneTier1ID + 1
```

### Replacement Format

Single-stat format: `[T{tier} | {statName}]`
Clean format: `[T{tier} | Clean]`

## Configuration

### Settings Structure
```lua
{
    enabled = boolean,
    debug = boolean
}
```

### Debug System

Conditional logging via `DebugPrint()`:
- Respects both runtime and persistent debug flags
- Formats messages with module prefix
- Only outputs when debug enabled

### Slash Commands

- `/neoStatLinks` or `/nsl` - Main command
- `/nsl debug` - Toggle debug mode
- `/nsl toggle` - Enable/disable module

## Dependencies

- **pylib** (optional): Provides hook management and event system
- **py_hook** (optional): Library-based hooking mechanism

The library gracefully degrades if optional dependencies are unavailable, falling back to direct function replacement.

## Error Handling

- Nil value checks throughout processing pipeline
- Pattern matching fallbacks for varied formats
- Safe string operations with length checks
- Debug logging for troubleshooting

## Performance Considerations

- Conditional debug output (no performance impact when disabled)
- Pattern matching optimized for common formats first
- Event registration only when needed
- Settings cached in memory

## Usage Example

```lua
-- Module initializes automatically
-- Hooks are registered on VARIABLES_LOADED event

-- Enable debug mode
/neoStatLinks debug

-- Toggle module
/neoStatLinks toggle
```

## Development

### Debug Mode
Enable detailed logging:
```lua
neoStatLinksSettings.debug = true
```

Debug output includes:
- Link parsing steps
- Pattern matching attempts
- Stat extraction details
- Hook registration status
- Rewriting operations

### Adding New Link Types

1. Add identifier range to module configuration
2. Implement parsing logic in `parse_item_link`
3. Add rewriting logic in `RewriteLink`
4. Update tier/classification calculations

## License

MIT License - See LICENSE.txt for details

## Author

Xcalmx

