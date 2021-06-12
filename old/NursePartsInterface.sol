// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NursePartsInterface {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event Mint(address indexed to, uint256 indexed id, uint256 value);
    event Burn(address indexed owner, uint256 indexed id, uint256 value);
    
    function masters() external view returns (address);
    function nurseRaids() external view returns (address);
    function cloneNurses() external view returns (address);

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    function mint(address to, uint256 id, uint256 value) external;
    function burn(address owner, uint256 id, uint256 value) external;
}