/// Contract the study feature's presentation layer depends on.
///
/// Structural anchor for `features/study/domain/`. It is deliberately empty:
/// the methods are written in M4.5, **from what presentation turns out to
/// need**, not from what a data source happens to offer. Guessing them now
/// would mean writing an implementation and a test for a call nobody makes.
///
/// This file is pure Dart on purpose — no Flutter, no Drift. AD-01 keeps the
/// planned Spring Boot backend cheap only while that stays true, and the cost
/// of breaking it does not show up until the backend lands.
abstract interface class StudyRepository {}
