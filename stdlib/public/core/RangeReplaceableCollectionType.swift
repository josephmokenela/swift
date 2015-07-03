//===--- RangeReplaceableCollectionType.swift -----------------*- swift -*-===//
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
//
//  A Collection protocol with replaceRange
//
//===----------------------------------------------------------------------===//

/// A *collection* that supports replacement of an arbitrary subRange
/// of elements with the elements of another collection.
public protocol RangeReplaceableCollectionType : CollectionType {
  /// Create an empty instance.
  init()

  //===--- Fundamental Requirements ---------------------------------------===//

  /// Replace the given `subRange` of elements with `newElements`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`subRange.count`) if
  ///   `subRange.endIndex == self.endIndex` and `isEmpty(newElements)`,
  ///   O(`self.count` + `newElements.count`) otherwise.
  mutating func replaceRange<
    C : CollectionType where C.Generator.Element == Generator.Element
  >(
    subRange: Range<Index>, with newElements: C
  )

  /*
  We could have these operators with default implementations, but the compiler
  crashes:

  <rdar://problem/16566712> Dependent type should have been substituted by Sema
  or SILGen

  func +<
    S : SequenceType
    where S.Generator.Element == Generator.Element
  >(_: Self, _: S) -> Self

  func +<
    S : SequenceType
    where S.Generator.Element == Generator.Element
  >(_: S, _: Self) -> Self

  func +<
    S : CollectionType
    where S.Generator.Element == Generator.Element
  >(_: Self, _: S) -> Self

  func +<
    RC : RangeReplaceableCollectionType
    where RC.Generator.Element == Generator.Element
  >(_: Self, _: S) -> Self
*/

  /// A non-binding request to ensure `n` elements of available storage.
  ///
  /// This works as an optimization to avoid multiple reallocations of
  /// linear data structures like `Array`.  Conforming types may
  /// reserve more than `n`, exactly `n`, less than `n` elements of
  /// storage, or even ignore the request completely.
  mutating func reserveCapacity(n: Index.Distance)

  //===--- Derivable Requirements (see free functions below) --------------===//

  /// Append `x` to `self`.
  ///
  /// Applying `successor()` to the index of the new element yields
  /// `self.endIndex`.
  ///
  /// - Complexity: Amortized O(1).
  mutating func append(x: Generator.Element)

  /*
  The 'extend' requirement should be an operator, but the compiler crashes:

  <rdar://problem/16566712> Dependent type should have been substituted by Sema
  or SILGen

  func +=<
    S : SequenceType
    where S.Generator.Element == Generator.Element
  >(inout _: Self, _: S)
  */

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  mutating func extend<
    S : SequenceType
    where S.Generator.Element == Generator.Element
  >(newElements: S)

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func insert(newElement: Generator.Element, atIndex i: Index)

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  mutating func splice<
    S : CollectionType where S.Generator.Element == Generator.Element
  >(newElements: S, atIndex i: Index)

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func removeAtIndex(i: Index) -> Generator.Element

  mutating func _customRemoveLast() -> Generator.Element?

  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func removeRange(subRange: Range<Index>)

  /// Remove all elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - parameter keepCapacity: If `true`, is a non-binding request to
  ///    avoid releasing storage, which can be a useful optimization
  ///    when `self` is going to be grown again.
  ///
  /// - Complexity: O(`self.count`).
  mutating func removeAll(keepCapacity keepCapacity: Bool /*= false*/)
}

//===----------------------------------------------------------------------===//
// Default implementations for RangeReplaceableCollectionType
//===----------------------------------------------------------------------===//

extension RangeReplaceableCollectionType {
  public mutating func append(newElement: Generator.Element) {
    insert(newElement, atIndex: endIndex)
  }

  public mutating func extend<
    S : SequenceType where S.Generator.Element == Generator.Element
  >(newElements: S) {
    for element in newElements {
      append(element)
    }
  }

  public mutating func insert(
    newElement: Generator.Element, atIndex i: Index
  ) {
    replaceRange(i..<i, with: CollectionOfOne(newElement))
  }

  public mutating func splice<
    C : CollectionType where C.Generator.Element == Generator.Element
  >(newElements: C, atIndex i: Index) {
    replaceRange(i..<i, with: newElements)
  }

  public mutating func removeAtIndex(index: Index) -> Generator.Element {
    _precondition(!isEmpty, "can't remove from an empty collection")
    let result: Generator.Element = self[index]
    replaceRange(index...index, with: EmptyCollection())
    return result
  }

  public mutating func removeRange(subRange: Range<Index>) {
    replaceRange(subRange, with: EmptyCollection())
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    if !keepCapacity {
      self = Self()
    }
    else {
      replaceRange(indices, with: EmptyCollection())
    }
  }

  public mutating func reserveCapacity(n: Index.Distance) {}
}

extension RangeReplaceableCollectionType {
  public mutating func _customRemoveLast() -> Generator.Element? {
    return nil
  }
}

extension RangeReplaceableCollectionType where Index : BidirectionalIndexType {
  /// Remove an element from the end.
  ///
  /// - Complexity: O(1)
  /// - Requires: `!self.isEmpty`
  public mutating func removeLast() -> Generator.Element {
    _precondition(!isEmpty, "can't removeLast from an empty collection")
    if let result = _customRemoveLast() {
      return result
    }
    return removeAtIndex(endIndex.predecessor())
  }
}

/// Insert `newElement` into `x` at index `i`.
///
/// Invalidates all indices with respect to `x`.
///
/// - Complexity: O(`x.count`).
@available(*, unavailable, message="call the 'insert()' method on the collection")
public func insert<
    C: RangeReplaceableCollectionType
>(inout x: C, _ newElement: C.Generator.Element, atIndex i: C.Index) {
  fatalError("unavailable function can't be called")
}

/// Insert `newElements` into `x` at index `i`.
///
/// Invalidates all indices with respect to `x`.
///
/// - Complexity: O(`x.count + newElements.count`).
@available(*, unavailable, message="call the 'splice()' method on the collection")
public func splice<
    C: RangeReplaceableCollectionType,
    S : CollectionType where S.Generator.Element == C.Generator.Element
>(inout x: C, _ newElements: S, atIndex i: C.Index) {
  fatalError("unavailable function can't be called")
}

/// Remove from `x` and return the element at index `i`.
///
/// Invalidates all indices with respect to `x`.
///
/// - Complexity: O(`x.count`).
@available(*, unavailable, message="call the 'removeAtIndex()' method on the collection")
public func removeAtIndex<
    C: RangeReplaceableCollectionType
>(inout x: C, _ index: C.Index) -> C.Generator.Element {
  fatalError("unavailable function can't be called")
}

/// Remove from `x` the indicated `subRange` of elements.
///
/// Invalidates all indices with respect to `x`.
///
/// - Complexity: O(`x.count`).
@available(*, unavailable, message="call the 'removeRange()' method on the collection")
public func removeRange<
    C: RangeReplaceableCollectionType
>(inout x: C, _ subRange: Range<C.Index>) {
  fatalError("unavailable function can't be called")
}

/// Remove all elements from `x`.
///
/// Invalidates all indices with respect to `x`.
///
/// - parameter keepCapacity: If `true`, is a non-binding request to
///    avoid releasing storage, which can be a useful optimization
///    when `x` is going to be grown again.
///
/// - Complexity: O(`x.count`).
@available(*, unavailable, message="call the 'removeAll()' method on the collection")
public func removeAll<
    C: RangeReplaceableCollectionType
>(inout x: C, keepCapacity: Bool = false) {
  fatalError("unavailable function can't be called")
}

/// Append elements from `newElements` to `x`.
///
/// - Complexity: O(N).
@available(*, unavailable, message="call the 'extend()' method on the collection")
public func extend<
    C: RangeReplaceableCollectionType,
    S : SequenceType where S.Generator.Element == C.Generator.Element
>(inout x: C, _ newElements: S) {
  fatalError("unavailable function can't be called")
}

/// Remove an element from the end of `x`  in O(1).
///
/// - Requires: `x` is nonempty.
@available(*, unavailable, message="call the 'removeLast()' method on the collection")
public func removeLast<
    C: RangeReplaceableCollectionType where C.Index : BidirectionalIndexType
>(inout x: C) -> C.Generator.Element {
  fatalError("unavailable function can't be called")
}

public func +<
    C : RangeReplaceableCollectionType,
    S : SequenceType
    where S.Generator.Element == C.Generator.Element
>(var lhs: C, rhs: S) -> C {
  // FIXME: what if lhs is a reference type?  This will mutate it.
  lhs.extend(rhs)
  return lhs
}

public func +<
    C : RangeReplaceableCollectionType,
    S : SequenceType
    where S.Generator.Element == C.Generator.Element
>(lhs: S, rhs: C) -> C {
  var result = C()
  result.reserveCapacity(rhs.count + numericCast(rhs.underestimateCount()))
  result.extend(lhs)
  result.extend(rhs)
  return result
}

public func +<
    C : RangeReplaceableCollectionType,
    S : CollectionType
    where S.Generator.Element == C.Generator.Element
>(var lhs: C, rhs: S) -> C {
  // FIXME: what if lhs is a reference type?  This will mutate it.
  lhs.reserveCapacity(lhs.count + numericCast(rhs.count))
  lhs.extend(rhs)
  return lhs
}

public func +<
    RRC1 : RangeReplaceableCollectionType,
    RRC2 : RangeReplaceableCollectionType 
    where RRC1.Generator.Element == RRC2.Generator.Element
>(var lhs: RRC1, rhs: RRC2) -> RRC1 {
  // FIXME: what if lhs is a reference type?  This will mutate it.
  lhs.reserveCapacity(lhs.count + numericCast(rhs.count))
  lhs.extend(rhs)
  return lhs
}

@available(*, unavailable, message="'ExtensibleCollectionType' has been folded into 'RangeReplaceableCollectionType'")
public typealias ExtensibleCollectionType = RangeReplaceableCollectionType
