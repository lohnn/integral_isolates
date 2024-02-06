# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2024-01-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`integral_isolates` - `v0.5.1`](#integral_isolates---v051)
 - [`use_isolate` - `v0.3.0+1`](#use_isolate---v0301)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `use_isolate` - `v0.3.0+1`

---

#### `integral_isolates` - `v0.5.1`

 - **FEAT**: Made IsolatGetter and TailoredIsolateGetter publicly overridable again (#42).


## 2023-12-29

### Changes

---

Packages with breaking changes:

 - [`integral_isolates` - `v0.5.0`](#integral_isolates---v050)
 - [`use_isolate` - `v0.3.0`](#use_isolate---v030)

Packages with other changes:

 - There are no other changes in this release.

---

#### `integral_isolates` - `v0.5.0`

 - **REFACTOR**: code cleanup and small internal refactor (#27).
 - **DOCS**: Slightly improved documentation of integral_isolates (#40).
 - **BREAKING** **REFACTOR**: Computation functions are now renamed to `compute` and `computeIsolate` (#37).
 - **BREAKING** **FEAT**(19): hooks stream and tailored isolate support added (#39).

#### `use_isolate` - `v0.3.0`

 - **BREAKING** **REFACTOR**: Computation functions are now renamed to `compute` and `computeIsolate` (#37).
 - **BREAKING** **FEAT**(19): hooks stream and tailored isolate support added (#39).


## 2023-08-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`use_isolate` - `v0.2.0+2`](#use_isolate---v0202)

---

#### `use_isolate` - `v0.2.0+2`

 - **FIX**: Disposal of Isolate for hooks implemented (#30).


## 2023-04-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`integral_isolates` - `v0.4.1`](#integral_isolates---v041)
 - [`use_isolate` - `v0.2.0+1`](#use_isolate---v0201)

---

#### `integral_isolates` - `v0.4.1`

 - **FEAT**: isolate stream (#18).

#### `use_isolate` - `v0.2.0+1`

 - **DOCS**: Set specific versions and name for example (#17).


## 2023-04-16

### Changes

---

Packages with breaking changes:

 - [`integral_isolates` - `v0.4.0`](#integral_isolates---v040)
 - [`use_isolate` - `v0.2.0`](#use_isolate---v020)

Packages with other changes:

 - There are no other changes in this release.

---

#### `integral_isolates` - `v0.4.0`

 - deprecated the class `Isolated` in favor of `StatefulIsolate`. The class `TailoredStatefulIsolate` was also added, adding support for an isolate that allows for specifying input and output types.

 - **FEAT**: specialized/tailored isolated (#14).
 - **BREAKING** **FEAT**: added useTailoredIsolate and updated documentation (#16).

#### `use_isolate` - `v0.2.0`

 - **FEAT**: specialized/tailored isolated (#14).
 - **BREAKING** **FEAT**: added useTailoredIsolate and updated documentation (#16).


## 2022-12-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`integral_isolates` - `v0.3.0+2`](#integral_isolates---v0302)
 - [`use_isolate` - `v0.1.0+5`](#use_isolate---v0105)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `use_isolate` - `v0.1.0+5`

---

#### `integral_isolates` - `v0.3.0+2`

 - **DOCS**: Proper format for marble diagrams for the markdown that is created (#11).


## 2022-12-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`integral_isolates` - `v0.3.0+1`](#integral_isolates---v0301)
 - [`use_isolate` - `v0.1.0+4`](#use_isolate---v0104)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `use_isolate` - `v0.1.0+4`

---

#### `integral_isolates` - `v0.3.0+1`

 - **REFACTOR**: flow improvements (#10).


## 2022-09-23

### Changes

---

Packages with breaking changes:

 - [`integral_isolates` - `v0.3.0`](#integral_isolates---v030)

Packages with other changes:

 - [`use_isolate` - `v0.1.0+3`](#use_isolate---v0103)

---

#### `integral_isolates` - `v0.3.0`

 - **REFACTOR**: Refactor/flow improvements (#9).
 - **DOCS**: Update README.md.
 - **BREAKING** **REFACTOR**: Use typed exceptions when errors occur (#8).

#### `use_isolate` - `v0.1.0+3`

 - **REFACTOR**: Refactor/flow improvements (#9).


## 2022-09-19

### Changes

---

Packages with breaking changes:

 - [`integral_isolates` - `v0.2.0`](#integral_isolates---v020)

Packages with other changes:

 - [`use_isolate` - `v0.1.0+2`](#use_isolate---v0102)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `use_isolate` - `v0.1.0+2`

---

#### `integral_isolates` - `v0.2.0`

 - **DOCS**: doc & examples updates.
 - **BREAKING** **REFACTOR**: ComputeCallback -> IsolateCallback.

## 1.0.0

- Initial version.
