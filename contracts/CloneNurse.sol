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
<<<<<<< Updated upstream
        uint256 supportPower;
        uint256 masterAccReward;
        uint256 supporterAccReward;
        bool supportable;
    }
    struct SupportInfo {
        uint256 groupId;
        address supporter;
        uint256 lpTokenAmount;
        uint256 accReward;
=======
>>>>>>> Stashed changes
    }

    INursePart public override nursePart;
    IMaidCoin public override maidCoin;
    ITheMaster public override theMaster;

    mapping(uint256 => uint256) public supportRoute;
    mapping(address => uint256) public supportTo;
    mapping(uint256 => uint256) public supportedPower;
    mapping(uint256 => uint256) public totalRewardsFromSupporters;

    uint256 public immutable WINNING_BONUS_TAKERS;

    NurseType[] public override nurseTypes;
    Nurse[] public override nurses;

<<<<<<< Updated upstream
    SupportInfo[] public override supportInfo;
    mapping(uint256 => uint256) public override idOfGroupId;
    mapping(uint256 => bool) public override destroyed;

    uint256 private lastUpdateBlock;
    uint256 private _accRewardPerShare;
    uint256 private totalPower;
=======
>>>>>>> Stashed changes

    constructor(
        address nursePartAddr,
        address maidCoinAddr,
        address theMasterAddr
    ) {
        nursePart = INursePart(nursePartAddr);
        maidCoin = IMaidCoin(maidCoinAddr);
        theMaster = ITheMaster(theMasterAddr);
        WINNING_BONUS_TAKERS = theMaster.WINNING_BONUS_TAKERS();
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

<<<<<<< Updated upstream
        uint256 power = originPowerOf(nurserType);
        totalPower += power;

        uint256 masterAccReward = (_update() * power) / 1e18;   //TODO
        nurses.push(
            Nurse({
                nurseType: nurserType,
                supportPower: 0,
                masterAccReward: masterAccReward,
                supporterAccReward: 0,
                supportable: supportable
            })
        );

        id = nurses.length;
        idOfGroupId[id] = id;
        theMaster.deposit(pid, masterAccReward, id);
        if (id < WINNING_BONUS_TAKERS) {
            uint256 amount = theMaster.claimWinningBonus(id);
=======
        uint256 power = nurseType.power;
        id = nurses.length;
        nurses.push(Nurse({nurseType: nurserType}));
        supportRoute[id] = id;
        if (id < WINNING_BONUS_TAKERS) {
            uint256 amount = theMaster.claimWinningBonus(msg.sender, id);
>>>>>>> Stashed changes
            maidCoin.transfer(msg.sender, amount);
        }
        _mint(msg.sender, id);
    }

    //function assembleWithPermit           //TODO

    function destroy(uint256 id, uint256 toId) external override {
        require(msg.sender == ownerOf(id));
        require(ownerOf(toId) != address(0));
        require(!destroyed[id]);
        require(!destroyed[toId]);
        require(toId != id);
<<<<<<< Updated upstream
        (address addr, , , , , ) = theMaster.poolInfo(pid);
        require(addr == address(this));

        idOfGroupId[id] = toId;
        destroyed[id] = true;
        //TODO : destroyReturn

        (uint256 amount, ) = theMaster.userInfo(pid, id);
        theMaster.withdraw(pid, amount, id);

        totalPower -= originPowerOf(id);
=======
        // withdraw needed.

        supportRoute[id] = toId;
        supportedPower[toId] += supportedPower[id];
        theMaster.mint(msg.sender, nurseTypes[nurses[id].nurseType].destroyReturn);
>>>>>>> Stashed changes
        _burn(id);
    }

    // claim
    // pendingReward

    // mapping(uint256 => uint256) public supportRoute;
    // mapping(address => uint256) public supportTo;
    // mapping(uint256 => uint256) public supportedPower;
    // mapping(uint256 => uint256) public totalRewardsFromSupporters;

<<<<<<< Updated upstream
        _increaseSupport(id, lpTokenAmount);

        emit Support(supportId, msg.sender, id, lpTokenAmount);
    }

    function increaseSupportWithPermit(
        uint256 supportId,
        uint256 lpTokenAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        lpToken.permit(msg.sender, address(this), lpTokenAmount, deadline, v, r, s);
        increaseSupport(supportId, lpTokenAmount);
    }

    function increaseSupport(uint256 supportId, uint256 lpTokenAmount) public override {
        SupportInfo storage _support = supportInfo[supportId];
        require(_support.supporter == msg.sender);

        _support.lpTokenAmount += lpTokenAmount;
        claimSupport(supportId);

        uint256 id = _findId(_support.groupId);
        _increaseSupport(id, lpTokenAmount);

        emit IncreaseSupport(supportId, msg.sender, id, lpTokenAmount);
    }

    function _findId(uint256 groupId) internal returns (uint256 id) {
        id = idOfGroupId[groupId];
        while (true) {
            uint256 newId = idOfGroupId[id];
            if (newId == id) {
                idOfGroupId[groupId] = id;
                break;
            }
            id = newId;
        }
    }

    function _increaseSupport(uint256 id, uint256 lpTokenAmount) internal {
        uint256 supportPower = (lpTokenAmount * lpTokenToNursePower) / 1e18;
        nurses[id].supportPower += supportPower;
        totalPower += supportPower;

        lpToken.transferFrom(msg.sender, address(this), lpTokenAmount);
    }

    function decreaseSupport(uint256 supportId, uint256 lpTokenAmount) external override {
        SupportInfo storage _support = supportInfo[supportId];
        require(_support.supporter == msg.sender);

        _support.lpTokenAmount -= lpTokenAmount;
        claimSupport(supportId);

        uint256 id = _findId(_support.groupId);
        uint256 supportPower = (lpTokenAmount * lpTokenToNursePower) / 1e18;
        nurses[id].supportPower -= supportPower;
        totalPower -= supportPower;

        lpToken.transfer(msg.sender, lpTokenAmount);

        emit DecreaseSupport(supportId, msg.sender, id, lpTokenAmount);
    }

    function _update() internal returns (uint256 result) {
        result = _accRewardPerShare;
        if (lastUpdateBlock != block.number) {
            (, , , , uint256 accRewardPerShare, ) = theMaster.poolInfo(1);
            _accRewardPerShare = accRewardPerShare;
            lastUpdateBlock = block.number;
        }
    }

    function claimableAmountOf(uint256 id) external view override returns (uint256) {
        if (ownerOf(id) == address(0)) {
            return 0;
        }

        Nurse memory nurse = nurses[id];
        (uint256 originPower, uint256 power, uint256 acc) = _nurseInfo(nurse);
        return (acc * originPower) / power - nurse.masterAccReward;
    }

    function claimableSupportAmountOf(uint256 supportId) external view override returns (uint256) {
        SupportInfo memory _support = supportInfo[supportId];
        if (_support.supporter == address(0)) {
            return 0;
        }

        uint256 id = idOfGroupId[_support.groupId];
        while (true) {
            uint256 newId = idOfGroupId[id];
            if (newId == id) {
                break;
            }
            id = newId;
        }

        Nurse memory nurse = nurses[id];
        (, uint256 power, uint256 acc) = _nurseInfo(nurse);

        uint256 supporterAccReward = (acc * nurse.supportPower) / power - nurse.supporterAccReward;
        return
            (supporterAccReward * _support.lpTokenAmount * lpTokenToNursePower) /
            1e18 /
            nurse.supportPower -
            _support.accReward;
    }

    function claim(uint256 id) public override {
        require(ownerOf(id) == msg.sender);

        Nurse storage nurse = nurses[id];
        (uint256 originPower, uint256 power, uint256 acc) = _nurseInfo(nurse);
        uint256 reward = (acc * originPower) / power - nurse.masterAccReward;
        nurse.masterAccReward += reward;

        maidCoin.transfer(msg.sender, reward);

        emit Claim(id, msg.sender, reward);
    }

    function claimSupport(uint256 supportId) public override {
        SupportInfo storage _support = supportInfo[supportId];
        require(_support.supporter == msg.sender);

        uint256 id = _findId(_support.groupId);

        Nurse storage nurse = nurses[id];
        (, uint256 power, uint256 acc) = _nurseInfo(nurse);
        uint256 totalReward = (acc * nurse.supportPower) / power - nurse.supporterAccReward;
        nurse.supporterAccReward += totalReward;

        uint256 reward = (totalReward * _support.lpTokenAmount * lpTokenToNursePower) /
            1e18 /
            nurse.supportPower -
            _support.accReward;
        totalReward += reward;
        _support.accReward += reward;

        maidCoin.transfer(msg.sender, totalReward);

        emit ClaimSupport(supportId, msg.sender, totalReward);
    }

    function _nurseInfo(Nurse memory nurse)
        internal
        view
        returns (
            uint256 originPower,
            uint256 power,
            uint256 acc
        )
    {
        originPower = originPowerOf(nurse.nurseType);
        power = originPower + nurse.supportPower;
        (, , , , uint256 accRewardPerShare, ) = theMaster.poolInfo(1);
        acc = (accRewardPerShare * power) / 1e18;
=======
    function setSupportTo(uint256 to) public {
        require(msg.sender == address(theMaster));
    }

    function changeSupportRoute(uint256 to) public {
        require(msg.sender == address(theMaster));
    }

    function changeSupportedPower(uint256 id, uint256 power) public {
        require(msg.sender == address(theMaster));
>>>>>>> Stashed changes
    }
}
