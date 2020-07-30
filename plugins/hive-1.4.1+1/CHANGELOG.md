## 1.4.1+1

### Other
- Added docs to all public members

# 1.4.1

### Enhancements
- Minor performance improvements

### Fixes
- When a database operation failed, subsequent operations would not be performed

### Other
- Fixed GitHub homepage path

# 1.4.0+1

### Enhancements
- Minor performance improvements

### Fixes
- Allow more versions of `crypto`

# 1.4.0

### Enhancements
- ~1000% encryption / decryption performance improvement
- Added option to implement custom encryption algorithm
- Added `box.valuesBetween(startKey, endKey)`
- Allow tree shaking to drop encryption engine if no encryption is used

### Fixes
- `Hive.deleteBoxFromDisk()` did not work for boxes with upper-case names

### More
- Deprecated `encryptionKey` parameter. Use `Hive.openBox('name', encryptionCipher: HiveAesCipher(yourKey))`.
- Dropped `pointycastle` dependency
- Dropped `path` dependency

# 1.3.0

*Use latest version of `hive_generator`*

### Breaking changes
- `TypeAdapters` and `@HiveType()` now require a `typeId`
- `Hive.registerAdapter()` does not need a `typeId` anymore.
- Removed `BinaryReader.readAsciiString()`
- Removed `BinaryWriter.writeAsciiString()`

### Enhancements
- New documentation with tutorials and live code

### Fixes
- `box.clear()` resets auto increment counter

### More
- Not calling `Hive.init()` results in better exception

# 1.2.0

### Breaking changes
- Removed the `Hive.path` getter
- Removed `Hive.openBoxFromBytes()` (use the `bytes` parameter of `Hive.openBox()` instead)
- `LazyBox` and `Box` now have a common parent class: `BoxBase`
- Lazy boxes need to be opened using `Hive.openLazyBox()`
- Open lazy boxes can be acquired using `Hive.lazyBox()`
- Box name bug resolved (more information below)

### Enhancements
- Support for relationships, `HiveLists` (see docs for details)
- Support for inheritance
- Lazy boxes can now have a type argument `LazyBox<YourModel>`
- Added method to delete boxes without opening them `Hive.deleteBoxFromDisk()`
- Added `path` parameter to open boxes in a custom path
- Improved documentation

### Fixes
- `HiveObjects` have not been initialized correctly in lazy boxes
- Fixed bug where uppercase box name resulted in an uppercase filename
- Fixed compaction bug which caused corrupted boxes
- Fixed bug which did not allow the key `0xFFFFFFFF`
- Fixed bug where not all `BoxEvent`s have been broadcasted

### More
- Changed type of `encryptionKey` from `Uint8List` to `List<int>`

### Important:
Due to a bug in previous Hive versions, boxes whose name contains uppercase characters were stored in a file that also contains upper case characters (e.g. 'myBox' -> 'myBox.hive').

To avoid different behavior on case sensitive file systems, Hive should store files with lower case names. This bug has been resolved in version 1.2.0.

If your box name contains upper case characters, the new version will not find a box stored by an older version. Please rename the hive file manually in that case.  
This also applies to the web version.

# 1.1.1

### Breaking changes
- `object.delete()` now throws exception if object is not stored in a box

### Fixes
- Fixed bug where `object.save()` would fail on subsequent calls

# 1.1.0+2

### Fixes
- Fixed bug that it was not possible to open typed boxes (`Box<E>`)

# 1.1.0+1

### Fixes
- Fixed bug that corrupted boxes were not detected

# 1.1.0

### Breaking changes
- Changed return type of `addAll()` from `List<int>` to `Iterable<int>`.
- Removed the option to register `TypeAdapters` for a specific box. E.g. `box.registerTypeAdapter()`.
- `getAt()`, `putAt()`, `deleteAt()` and `keyAt()` no longer allow indices out of range.

### Enhancements
- Added `HiveObject`
- Boxes have now an optional type parameter `Box<E>`
- Support opening boxes from assets

### Fixes
- Fixed bug which was caused by not awaiting write operations
- Fixed bug where custom compaction strategy was not applied
- Hive now locks box files while they are open to prevent concurrent access from multiple processes

### More
- Improved performance of `putAll()`, `deleteAll()`, `add()`, `addAll()`
- Changed `values` parameter of `addAll()` from `List` to `Iterable`
- Improved documentation
- Preparation for queries

# 1.0.0
- First stable release

# 0.5.1+1
- Change `keys` parameter of `deleteAll` from `List` to `Iterable`
- Fixed bug in `BinaryWriter`

# 0.5.1
- Fixed `Hive.init()` bug in browser
- Fixed a bug with large lists or strings
- Improved box opening time in the browser
- Improved general write performance
- Improved docs
- Added integration tests

# 0.5.0
- Added `keyComparator` parameter for custom key order
- Added `isEmpty` and `isNotEmpty` getters to box
- Added support for reading and writing subclasses
- Removed length limitation for Lists, Maps, and Strings
- Greatly improved performance of storing Uint8Lists in browser
- Removed CRC check in the browser (not needed)
- Improved documentation
- TypeIds are now allowed in the range of 0-223
- Fixed compaction
- Fixed writing longer Strings
- **Breaking:** Binary format changed

# 0.4.1+1
- Document all public APIs
- Fixed flutter_web error

# 0.4.1
- Allow different versions of the `path` package

# 0.4.0
- Added `BigInt` support
- Added `compactionStrategy` parameter
- Added automatic crash recovery
- Added `add()` and `addAll()` for auto-increment keys
- Added `getAt()`, `putAt()` and `deleteAt()` for working with indices
- Support for int (32 bit unsigned) keys
- Non-lazy boxes now notify their listeners immediately about changes
- Bugfixes
- More tests
- **Breaking:** Open boxes with `openBox()`
- **Breaking:** Writing `null` is no longer equivalent to deleting a key
- **Breaking:** Temporarily removed support for transactions. New API design needed. Will be coming back in a future version.
- **Breaking:** Binary format changed
- **Breaking:** API changes

# 0.3.0+1
- Bugfix: `Hive['yourBox']` didn't work with uppercase box names

# 0.3.0
- Big step towards stable API
- Support for transactions
- Annotations for hive_generator
- Bugfixes
- Improved web support
- **Breaking:** `inMemory` -> `lazy`
- **Breaking:** Binary format changed

# 0.2.0
- Support for dart2js
- Improved performance
- Added `inMemory` option
- **Breaking:** Minor API changes
- **Breaking:** Changed Endianness to little
- **Breaking:** Removed Migrator

# 0.1.1
- Downgrade to `meta: ^1.1.6` to support flutter

# 0.1.0
- First release
