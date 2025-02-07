// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the admin 
    function admin() external view returns (address);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, uint256 dropNonce) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
    // Allows an admin to overwrite the current distribution with a new one 
    function iterateDistribution(address from, address to, uint256 amount, bytes32 merkleRoot_) external;
    // Allows an admin to pause the current distribution 
    function pause(bool b) external returns (bool);
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}