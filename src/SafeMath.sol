pragma solidity ^0.4.13;

/// @title SafeMath
/// @author Eliott Teissonniere
/// safe math helper

contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;


  /// @dev Add two uint256 values, throw in case of overflow
  /// @param x first value to add
  /// @param y second value to add
  /// @return x + y
  function safeAdd (uint256 x, uint256 y) constant internal returns (uint256 z) {
    if (x > MAX_UINT256 - y) revert();
    return x + y;
  }

  /// @dev Subtract one uint256 value from another, throw in case of underflow
  /// @param x value to subtract from
  /// @param y value to subtract
  /// @return x - y
  function safeSub (uint256 x, uint256 y) constant internal returns (uint256 z) {
    if (x < y) revert();
    return x - y;
  }

  /// @dev Multiply two uint256 values, throw in case of overflow
  /// @param x first value to multiply
  /// @param y second value to multiply
  /// @return x * y
  function safeMul (uint256 x, uint256 y) constant internal returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    if (x > MAX_UINT256 / y) revert();
    return x * y;
  }
}
