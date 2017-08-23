pragma solidity ^0.4.13;

import "ds-test/test.sol";

import "./SafeMath.sol";

contract TestSafeMath is DSTest, SafeMath {
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function test_add() {
        assert(safeAdd(1, 1) == 2);
    }

    function testFail_add_overflow_x() {
        safeAdd(MAX_UINT256, 1);
    }

    function testFail_add_overflow_y() {
        safeAdd(1, MAX_UINT256);
    }

    function testFail_add_overflow() {
        safeAdd(MAX_UINT256 - 1, 2);
    }

    function test_sub() {
        assert(safeSub(1, 1) == 0);
    }

    function testFail_sub_underflow() {
        safeSub(1, 2);
    }

    function test_mul() {
        assert(safeMul(2, 2) == 4);
        assert(safeMul(2, 0) == 0);
        assert(safeMul(0, 2) == 0);
    }

    function testFail_mul_overflow_x() {
        safeMul(MAX_UINT256, 2);
    }

    function testFail_mul_overflow_y() {
        safeMul(2, MAX_UINT256);
    }

    function testFail_mul_overflow() {
        safeMul(MAX_UINT256/2, 3);
    }
}
