# CLAUDE.md — src/serialization/

The `Serializer` / `Deserializer` pair, the `SerializationError` type, the
`WellKnownObjects` registry, the `@serializationTransients` protocol, file save/load
(`FileSaving` / `FileLoading`), and the source-edits registry live here.

**All serialization / deserialization / duplication documentation — the format spec, the
traversal contract shared with `DeepCopierMixin` duplication, the per-class protocol, the
per-type handlers, and the file-I/O / `file://` capability map — lives in ONE place:**

→ [`../../docs/serialization-duplication-reference.md`](../../docs/serialization-duplication-reference.md)

Do not duplicate that content here or in any other CLAUDE.md; this file is a pointer only.
