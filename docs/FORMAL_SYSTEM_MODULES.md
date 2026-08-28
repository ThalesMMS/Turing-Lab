# Formal-System Modules

The formal-system registry is the extension boundary for editor workspaces. It
keeps navigation, capability menus, persistence, examples, help, and file
formats aligned when a document family is added.

The core API is exported from
`lib/core/formal_systems/formal_systems.dart`. Core descriptors do not contain
localized labels, Flutter widgets, or runtime class names.

## Register a Module

1. Choose stable identifiers for the document type, variant, schema, route,
   localization namespace, and accessibility-semantics namespace. These values
   are persisted and must not be derived from display text.
2. Implement `FormalSystemModule<TDocument>`. Its `FormalSystemDescriptor`
   declares the schema version, category, capabilities, formats, and conversion
   edges. Use `DescriptorFormalSystemModule` only when the module has metadata
   but no runtime document adapter.
3. Add the module to the registry supplied to the app. Existing production
   modules are assembled by `FormalSystemRegistry.defaultRegistry`; tests can
   provide a registry containing an extra module without changing navigation or
   file-operation widgets.
4. Add the presentation adapter that supplies the localized label, icon, help
   topic, and responsive page factory. Keep these Flutter-specific values out of
   the core descriptor.

`FormalSystemKey` combines a type and variant. Use distinct variants for
related environments such as single-tape and multi-tape Turing machines, or
regular-language and context-free-language pumping-lemma workspaces.

## Declare Capabilities

Every capability is explicit. Select `SupportedCapability`,
`ExperimentalCapability`, `UnavailableCapability`, or `LegacyOnlyCapability`
instead of installing a callback that does nothing. A menu action is visible
only when the active descriptor enables the corresponding capability.

Document formats are declared with `DocumentFormatSupport`. Register a format
in the shared `DocumentFormatCatalog`, then state separately whether the module
can import and export it. Implement `DocumentCodecCapability<TDocument>` when
the module owns an encoder or decoder. Do not dispatch codecs by runtime class
name or by a display label.

Optional typed adapters are available for:

- `ExampleCatalogCapability<TDocument>` for offline examples;
- `SessionCapability<TDocument>` for session serialization and restoration;
- `ConversionCapability<TSource, TTarget>` for a declared conversion edge.

A learning-only workspace may intentionally declare session persistence or
file formats unavailable. It must not fabricate an empty document merely to
satisfy a menu or persistence path.

## Persistence and Migration

Persist the `FormalSystemKey`, `DocumentSchemaId`, and
`DocumentSchemaVersion` with each document payload. A schema migration belongs
to the module that understands that payload. Never use `runtimeType`, a
localized name, or the current navigation position as a persisted identity.

When changing a persisted schema:

1. Increment its `DocumentSchemaVersion`.
2. Add a migration from every supported older version.
3. Preserve unsupported future payloads for recovery instead of rewriting
   them as the current version.
4. Add round-trip, legacy-migration, malformed-payload, and future-version
   tests.

## Examples and Help

Example metadata must identify its owning formal-system key. The module's
example adapter loads typed documents; shared UI may filter the catalog by the
active descriptor without knowing the document class.

Use a stable help-topic identifier in the presentation adapter. Localized
titles and descriptions are resolved at render time from the descriptor's
localization namespace, so registry validation is independent of locale.

## Required Tests

Cover the following before registering a production module:

- registry construction and deterministic duplicate rejection;
- capability and file-action filtering;
- mobile, tablet, and desktop navigation generation;
- session round-trip and schema migration when persistence is supported;
- unsupported actions remaining absent rather than becoming no-ops;
- examples, help routing, and each declared codec or conversion;
- a registry override containing a test-only module, proving that shared
  navigation and file-operation code needs no central switch edit.

The registry rejects duplicate formal-system keys, routes, schemas, formats,
extensions, conversion edges, localization namespaces, and semantics
namespaces. Treat the resulting `FormalSystemConfigurationException` as a
configuration error and fix the colliding declarations.
