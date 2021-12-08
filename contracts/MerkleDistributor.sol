// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    address public immutable override admin;
    // Must set and replace msg.sender as admin
    address public immutable SWIVELMULTISIG = address(0);
    uint256 public currentDropNonce;
    // 
    bool public paused;
    // This is a packed array of booleans.
    mapping(uint256 => bytes32) public merkleRoot;
    
    mapping(uint256 => mapping (uint256 => uint256)) private claimedBitMap;
    
    mapping(uint256 => bool) private isCancelled;

    // This event is triggered whenever a call to #iterateDistribution succeeds.
    event newDistribution(bytes32 merkleRoot, uint256 dropNonce);

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot[0] = merkleRoot_;
        admin = msg.sender;
    }

    function _merkleRoot(uint256 dropNonce) public view returns (bytes32) {
        return merkleRoot[dropNonce];
    }
    /// @notice Allows an admin to overwrite the current distribution with a new one 
    /// @param from The address of the wallet containing tokens to distribute
    /// @param to The address that will receive any currently remaining distributions (will normally be the same as from)
    /// @param amount The amount of tokens in the new distribution
    /// @param merkleRoot_ The merkle root associated with the new distribution
    function iterateDistribution(address from, address to, uint256 amount, bytes32 merkleRoot_) external override onlyAdmin(admin) {      
        
        // remove current token balance
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(to, balance);
        
        // transfer enough tokens for new distribution
        _token.transferFrom(from, address(this), amount);
        
        // cancel previous drop nonce / previous distribution
        isCancelled[currentDropNonce] = true;
        
        // add the new distribution's merkleRoot
        merkleRoot[(currentDropNonce+1)] = merkleRoot_;

        // unpause redemptions
        pause(false);

        // emit distribution event
        emit newDistribution(merkleRoot_, (currentDropNonce+1));
    }

    function isClaimed(uint256 index, uint256 dropNonce) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[dropNonce][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index, uint256 dropNonce) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[dropNonce][claimedWordIndex] = claimedBitMap[dropNonce][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external unpaused() override {
        require(!isClaimed(index, currentDropNonce), 'MerkleDistributor: Drop already claimed.');
        require(!isCancelled[currentDropNonce], 'Drop nonce already cancelled');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot[currentDropNonce], node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index, currentDropNonce);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
    /// @notice Called by admin at any point to pause / unpause market transactions
    /// @param b Boolean which indicates the markets paused status
    function pause(bool b) public onlyAdmin(admin) override returns (bool) {
        paused = b;
        return true;
  }
    
    modifier onlyAdmin(address a) {
        require(msg.sender == a, 'sender must be admin');
        _;
    }
  
    modifier unpaused() {
        require(!paused, 'redemptions are paused');
        _;
    }
}