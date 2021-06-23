// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ERC721.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC1271.sol";

contract CloneNurse is Ownable, ERC721("CloneNurse", "CNURSE"), ICloneNurse {
    struct NurseType {
        uint256 partCount;
        uint256 destroyReturn;
        uint256 power;
    }
    struct Nurse {
        uint256 nurseType;
    }

    INursePart public override nursePart;
    IMaidCoin public override maidCoin;
    ITheMaster public override theMaster;

    mapping(uint256 => uint256) public supportRoute;
    mapping(address => uint256) public supportTo;
    mapping(uint256 => uint256) public supportedPower;
    mapping(uint256 => uint256) public totalRewardsFromSupporters;

    NurseType[] public override nurseTypes;
    Nurse[] public override nurses;

    constructor(
        address nursePartAddr,
        address maidCoinAddr,
        address theMasterAddr
    ) {
        nursePart = INursePart(nursePartAddr);
        maidCoin = IMaidCoin(maidCoinAddr);
        theMaster = ITheMaster(theMasterAddr);
    }

    function addNurseType(
        uint256 partCount,
        uint256 destroyReturn,
        uint256 power
    ) external onlyOwner returns (uint256 nurseType) {
        nurseType = nurseTypes.length;
        nurseTypes.push(NurseType({partCount: partCount, destroyReturn: destroyReturn, power: power}));
    }

    function assemble(uint256 nurserType, bool supportable) external override returns (uint256 id) {
        NurseType memory nurseType = nurseTypes[nurserType];
        nursePart.safeTransferFrom(msg.sender, address(this), nurserType, nurseType.partCount, "");
        nursePart.burn(nurserType, nurseType.partCount);
        // deposit needed.

        uint256 power = nurseType.power;
        id = nurses.length;
        nurses.push(Nurse({nurseType: nurserType}));
        supportRoute[id] = id;
        _mint(msg.sender, id);
    }

    //function assembleWithPermit           //TODO

    function destroy(uint256 id, uint256 toId) external override {
        require(msg.sender == ownerOf(id));
        require(ownerOf(toId) != address(0));
        require(!destroyed[id]);
        require(!destroyed[toId]);
        require(toId != id);
        // withdraw needed.

        supportRoute[id] = toId;
        supportedPower[toId] += supportedPower[id];
        theMaster.mint(msg.sender, nurseTypes[nurses[id].nurseType].destroyReturn);
        _burn(id);
    }

    // claim
    // pendingReward

    // mapping(uint256 => uint256) public supportRoute;
    // mapping(address => uint256) public supportTo;
    // mapping(uint256 => uint256) public supportedPower;
    // mapping(uint256 => uint256) public totalRewardsFromSupporters;

    function setSupportTo(uint256 to) public {
        require(msg.sender == address(theMaster));
    }

    function changeSupportRoute(uint256 to) public {
        require(msg.sender == address(theMaster));
    }

    function changeSupportedPower(uint256 id, uint256 power) public {
        require(msg.sender == address(theMaster));
    }
}
