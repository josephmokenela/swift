//===--- Map.swift - Lazily map the elements of a Sequence ---------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// The `Generator` used by `MapSequenceView` and `MapCollectionView`.
/// Produces each element by passing the output of the `Base`
/// `Generator` through a transform function returning `T`
@public struct MapSequenceGenerator<Base: Generator, T>: Generator, Sequence {
  @public mutating func next() -> T? {
    let x = _base.next()
    if x {
      return _transform(x!)
    }
    return nil
  }
  
  @public func generate() -> MapSequenceGenerator {
    return self
  }
  
  var _base: Base
  var _transform: (Base.Element)->T
}

//===--- Sequences --------------------------------------------------------===//

/// A `Sequence` whose elements consist of those in a `Base`
/// `Sequence` passed through a transform function returning `T`.
/// These elements are computed lazily, each time they're read, by
/// calling the transform function on a base element.
@public struct MapSequenceView<Base: Sequence, T> : Sequence {
  @public func generate() -> MapSequenceGenerator<Base.GeneratorType,T> {
    return MapSequenceGenerator(
      _base: _base.generate(), _transform: _transform)
  }
  
  var _base: Base
  var _transform: (Base.GeneratorType.Element)->T
}

extension LazySequence {
  /// Return a `MapSequenceView` over this `Sequence`.  The elements of
  /// the result are computed lazily, each time they are read, by
  /// calling `transform` function on a base element.
  func map<U>(
    transform: (S.GeneratorType.Element)->U
  ) -> LazySequence<MapSequenceView<S, U>> {
    return LazySequence<MapSequenceView<S, U>>(
      MapSequenceView(_base: self._base, transform)
    )
  }
} 

/// Return an `Array` containing the results of mapping `transform`
/// over `source`.
@public func map<S:Sequence, T>(
  source: S, transform: (S.GeneratorType.Element)->T
) -> [T] {
  return lazy(source).map(transform).array
}

//===--- Collections ------------------------------------------------------===//

/// A `Collection` whose elements consist of those in a `Base`
/// `Collection` passed through a transform function returning `T`.
/// These elements are computed lazily, each time they're read, by
/// calling the transform function on a base element.
@public struct MapCollectionView<Base: Collection, T> : Collection {
  @public var startIndex: Base.IndexType {
    return _base.startIndex
  }
  
  @public var endIndex: Base.IndexType {
    return _base.endIndex
  }

  @public subscript(index: Base.IndexType) -> T {
    return _transform(_base[index])
  }

  @public func generate() -> MapSequenceView<Base, T>.GeneratorType {
    return MapSequenceGenerator(_base: _base.generate(), _transform: _transform)
  }

  var _base: Base
  var _transform: (Base.GeneratorType.Element)->T
}

extension LazyCollection {
  /// Return a `MapCollectionView` over this `Collection`.  The
  /// elements of the result are computed lazily, each time they are
  /// read, by calling `transform` function on a base element.
  func map<U>(
    transform: (C.GeneratorType.Element)->U
  ) -> LazyCollection<MapCollectionView<C, U>> {
    return LazyCollection<MapCollectionView<C, U>>(
      MapCollectionView(_base: self._base, transform))
  }
} 

/// Return an `Array` containing the results of mapping `transform`
/// over `source`.
@public func map<C:Collection, T>(
  source: C, transform: (C.GeneratorType.Element)->T
) -> [T] {
  return lazy(source).map(transform).array
}
