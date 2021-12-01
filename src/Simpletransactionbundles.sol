// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

/// @title Contracts "check_state" function is supposed to be called as the last transaction in a flashbots bundle
/// @dev This works by setting all transaction costs to a minimum. If the state is as expected, we pay the miner to include our bundle.
contract Simpletransactionbundles {
    address owner;

    // empty constructor
    constructor() {
        owner = msg.sender;
    }

    /// @notice This functions queries blockchain state. If the state is as expected, we pay the miner.
    /// @dev SECURITY WARNING: do not call this for anything else but checking the state of the chain after your transactions.
    function check_state(uint mineBy, uint minerPayment, bytes[] memory extcalldata) public payable {

        // transaction expired, we do not want the bundle to be mined
        require(block.number <= mineBy, "N");

        uint len = extcalldata.length;
        for (uint i = 0; i < len; i++) {
            (address addr, bytes32 expected, bytes memory arguments) = abi.decode(extcalldata[i], (address, bytes32, bytes));

            // call externally and get chain state
            (, bytes memory data) = (addr).call(arguments);

            // check the state against expected values
            require(keccak256(data) == expected, "S");

        }

        // every check passed: pay the miner
        block.coinbase.transfer(minerPayment);
    }

    /// @notice this is only needed to rescue users that misused "check_state"
    function rescue(bytes[] memory extcalldata) public payable {
        require(msg.sender == owner);

        uint len = extcalldata.length;
        for (uint i = 0; i < len; i++) {
            (address addr, bytes32 expected, bytes memory arguments) = abi.decode(extcalldata[i], (address, bytes32, bytes));

            // call externally
            (, bytes memory data) = (addr).call(arguments);
        }

        uint bal = address(this).balance;
        if (bal > 0) {
            payable(owner).transfer(bal);
        }
    }
}
