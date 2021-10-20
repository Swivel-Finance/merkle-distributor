// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Utils/MerkleProof.sol";
import "./Interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    address public immutable override admin;
    // MUST SET
    address public SWIVELMULTISIG = address(0);
    // This is a packed array of booleans.
    mapping(uint256 => bytes32) private merkleRoot;
    
    mapping(uint256 => mapping (uint256 => uint256)) private claimedBitMap;
    
    mapping(uint256 => bool) private isCancelled;

    constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot[0] = merkleRoot_;
        admin = SWIVELMULTISIG;
    }

    
    function resetDistribution(address from, address to, uint256 amount, uint256 dropNonce, bytes32 merkleRoot_) public onlyAdmin(admin) {
        require(!isCancelled[dropNonce], 'Drop nonce already cancelled');
        
        // remove current token balance
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(to, balance);
        
        // transfer enough tokens for new distribution
        _token.transferFrom(from, address(this), amount);
        
        // cancel previous drop nonce / previous distribution
        isCancelled[dropNonce] = true;
        
        // overwrite old merkleRoot with new distribution's merkleRoot
        merkleRoot[dropNonce] = merkleRoot_;
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

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 dropNonce) external override {
        require(!isClaimed(index, dropNonce), 'MerkleDistributor: Drop already claimed.');
        require(!isCancelled[dropNonce], 'Drop nonce already cancelled');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot[dropNonce], node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index, dropNonce);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
    
    modifier onlyAdmin(address a) {
        require(msg.sender == a, 'sender must be admin');
        _;
  }
}
