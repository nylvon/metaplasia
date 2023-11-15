# ➤ Metaplasia ⚡🦠
![metaplasia_logo](https://github.com/nylvon/metaplasia/assets/116503189/d1028891-ee03-4c2b-9734-dd5f1e4f143d)
## What is this?

**Metaplasia** is a library that offers users the ability to do a few _fun things_ with their types and objects in Zig, such as:![Uploading met<?xml version="1.0" encoding="UTF-8" standalone="no"?>

1. Easy reflection
2. Interfaces
   - Compile-time and run-time (and hybrid)!
4. Type merging
5. Type generation

## Why would I want any of this?

- Interfaces are important and make sure that your code obeys a standard implementation such that it can be swapped out with another bit without needing to re-write everything, thus increasing modularity!
But they also serve an important role as sanity checks for your code!
```zig
// A simple reader interface
const IReader = Interface.init([_]Field {
		Interface.new_variable("buffer", []u8),
		Interface.new_function("read_fn", [_]type {[]u8, []u8}, []u8)
	});

// "grant" returns the type defined below at compile-time if and only if it implements IReader 
const custom_reader_type = Interface.grant(IReader,
	.{
		buffer: []u8,
		read_fn: fn ([]u8, []u8) []u8 = custom_read_fn,

		pub fn custom_read_fn(path: []u8, options: []u8) []u8 {
			// ...
		}
	});
```
- Ever wanted to have a reader and a writer in one package, having those written already, but did not want to write this mixed type by hand? Type merging is the solution! Simply pass two types as 
```zig
// Naive type-merging
const writer_type = struct { ... };
const reader_type = struct { ... };

// Obtain a writer and reader combined type
const writer_reader_type = Metaplasia.merge([_]type {writer_type, reader_type});

// Safe type-merging
const safe_writer_type = Interface.grant(IWriter, .{ ... });
const safe_reader_type = Interface.grant(IReader, .{ ... });

// This type matches both interfaces, because the original types matched them, if not, we'd get a compile error explaining the situation!
// This type can be used as both a writer and a reader, swap freely!
const safe_writer_reader_type = Metaplasia.merge([_]type {safe_writer_type, safe_reader_type});
```

- Now think of a game, where you would have a lot of types, and you would want to re-use them to build more advanced, complex types based off of the original ones. Or, what about procedural types?
```zig
// Some base type that's going to be used in a lot of places
const entity_type = Metaplasia.merge([_]type {health_type, damage_type, identity_type, ...});

// A new player type that 'extends' the entity type. Inheritance, but without all the fuss!
const player_type = Metaplasia.merge([_]type {entity_type, physics_type, chat_type, ... });

// ...
	// insert example for procedural types
};
```

## Current status

Below is the status of current features.
Blank means not implemented.

- [ ] Reflection
- [ ] Interfaces
- [ ] Type merging
- [ ] Type generation

