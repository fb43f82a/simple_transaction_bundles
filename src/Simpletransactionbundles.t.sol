// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Simpletransactionbundles.sol";

contract CallReceiver {
    uint stateA = 0;
    uint stateB = 0;

    function changeStateA(uint newval) public {
        stateA = newval;
    }
    function changeStateB(uint newval) public {
        stateB = newval;
    }


    function checkStateA() public returns (uint) {
        return stateA;
    }

    function checkStateB() public returns (uint) {
        return stateB;
    }

   function returns1() public returns (uint256) {
        return 1;
    }

    function reverts(uint bla) public {
        revert();
    }

}

contract SimpletransactionbundlesTest is DSTest {
    Simpletransactionbundles executor;
    CallReceiver receiver;

    event EventNum(uint);
    event Balance(uint);

    function setUp() public {
        executor = new Simpletransactionbundles();
        receiver = new CallReceiver();
    }

    function testFail_wrong_return() public {

        uint256 _expectedReturn = 0; // should be one to pass
        bytes32 expectedReturn = keccak256(abi.encode(_expectedReturn));
        bytes memory argument = abi.encodeWithSelector(CallReceiver.returns1.selector, "");


        bytes memory _extCallData = constructCall(address(receiver),
                        expectedReturn,
                        argument);
                    
        bytes[] memory arr = new bytes[](1);
        arr[0] = _extCallData;


        executor.check_state{value: 1}(block.number, 1, arr);

        assertTrue(true);
    }

    function testFail_call_reverts() public {
       uint256 _dummyUint = 0; 
       bytes32 expectedReturn = keccak256(abi.encode(_dummyUint)); // we don't actually care
       bytes memory argument = abi.encodeWithSelector(CallReceiver.reverts.selector, _dummyUint);


       bytes memory _extCallData = constructCall(address(receiver),
                       expectedReturn,
                       argument);
                   
       bytes[] memory arr = new bytes[](1);
       arr[0] = _extCallData;

       executor.check_state{value: 1}(block.number, 1, arr);

       assertTrue(true);
    }

    function testFail_wrong_blocknum() public {
       uint256 _dummyUint = 0; 
       bytes32 expectedReturn = keccak256(abi.encode(_dummyUint)); // we don't actually care
       bytes memory argument = abi.encodeWithSelector(CallReceiver.reverts.selector, _dummyUint);

       bytes memory _extCallData = constructCall(address(receiver),
                       expectedReturn,
                       argument);
                   
       bytes[] memory arr = new bytes[](1);
       arr[0] = _extCallData;

       executor.check_state{value: 1}(block.number-1, 1, arr);

       assertTrue(true);
    }

    function test_success_1_statechange() public {
        CallReceiver receiver1StateChange = new CallReceiver();
        uint balanceBefore = address(this).balance;

        // this would be the result of a previous transactions inside of the bundle
        receiver1StateChange.changeStateA(9999);

        
        uint256 newStateValA = 9999; 
        bytes32 expectedReturn = keccak256(abi.encode(newStateValA)); // we don't actually care
        bytes memory argument = abi.encodeWithSelector(CallReceiver.checkStateA.selector, newStateValA);


        bytes memory _extCallData = constructCall(address(receiver1StateChange),
                        expectedReturn,
                        argument);

        bytes[] memory arr = new bytes[](1);
        arr[0] = _extCallData;

        executor.check_state{value: 1}(block.number, 1, arr);

        emit Balance(balanceBefore);
        emit Balance(address(this).balance);
        assertTrue(balanceBefore == address(this).balance + 1);
    }

    function test_success_2_statechanges() public {
        CallReceiver receiver2StateChange = new CallReceiver();

        uint balanceBefore = address(this).balance;

        // this would be the result of a previous transactions inside of the bundle
        receiver2StateChange.changeStateA(9999);
        receiver2StateChange.changeStateB(8888);

        
        uint256 newStateValA = 9999; 
        bytes32 expectedReturnA = keccak256(abi.encode(newStateValA)); // we don't actually care
        bytes memory argumentA = abi.encodeWithSelector(CallReceiver.checkStateA.selector, newStateValA);
        bytes memory _extCallDataA = constructCall(address(receiver2StateChange),
                        expectedReturnA,
                        argumentA);

        uint256 newStateValB = 8888; 
        bytes32 expectedReturnB = keccak256(abi.encode(newStateValB)); // we don't actually care
        bytes memory argumentB = abi.encodeWithSelector(CallReceiver.checkStateB.selector, newStateValB);
        bytes memory _extCallDataB = constructCall(address(receiver2StateChange),
                        expectedReturnB,
                        argumentB);


        bytes[] memory arr = new bytes[](2);
        arr[0] = _extCallDataA;
        arr[1] = _extCallDataB;

        executor.check_state{value: 1}(block.number, 1, arr);

        emit Balance(balanceBefore);
        emit Balance(address(this).balance);
        assertTrue(balanceBefore == address(this).balance + 1);
    }

    function constructCall(address addr, bytes32 expectedReturn, bytes memory args) public returns (bytes memory) {
        return abi.encode(addr, expectedReturn, args);
    }

}
