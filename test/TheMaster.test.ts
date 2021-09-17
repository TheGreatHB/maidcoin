import {
    MaidCoin,
    NursePart,
    CloneNurses,
    WETH,
    MaidCafe,
    TheMaster,
    TestLPToken,
    TestSushiToken,
    TestMasterChef,
    MasterCoin
} from "../typechain";

import { ethers } from "hardhat";
import { expect, assert } from "chai";
import { BigNumber, BigNumberish, BytesLike, Contract } from "ethers";
import { mine, getBlock, autoMining, mineTo } from "./shared/utils/blockchain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";

const { constants } = ethers;
const { AddressZero, HashZero, Zero, MaxUint256 } = constants;

const tokenAmount = (number: number) => {
    return ethers.utils.parseEther(String(number));
};

const INITIAL_REWARD_PER_BLOCK = tokenAmount(1);
const START_BLOCK = 300;
const PRECISION = BigNumber.from(10).pow(20);

const mineToStartBlock = async () => {
    await mine(START_BLOCK - (await ethers.provider.getBlockNumber()) - 1);
};

const setupTest = async () => {
    const signers = await ethers.getSigners();
    const [deployer, alice, bob, carol, dan, erin, frank] = signers;

    const TestLPToken = await ethers.getContractFactory("TestLPToken");
    const lpToken = (await TestLPToken.deploy()) as TestLPToken;
    const mockLPToken = (await TestLPToken.deploy()) as TestLPToken;

    const MaidCoin = await ethers.getContractFactory("MaidCoin");
    const coin = (await MaidCoin.deploy()) as MaidCoin;

    const WETH = await ethers.getContractFactory("WETH");
    const weth = (await WETH.deploy()) as WETH;

    const MaidCafe = await ethers.getContractFactory("MaidCafe");
    const cafe = (await MaidCafe.deploy(coin.address, weth.address)) as MaidCafe;

    const MasterCoin = await ethers.getContractFactory("MasterCoin");
    const master = (await MasterCoin.deploy()) as MasterCoin;

    const TestSushiToken = await ethers.getContractFactory("TestSushiToken");
    const sushi = (await TestSushiToken.deploy()) as TestSushiToken;
    const TestMasterChef = await ethers.getContractFactory("TestMasterChef");
    const sushiMC = (await TestMasterChef.deploy(
        sushi.address,
        deployer.address,
        tokenAmount(100),
        0,
        0
    )) as TestMasterChef;

    await sushiMC.add(400, mockLPToken.address, true);
    await sushiMC.add(300, mockLPToken.address, true);
    await sushiMC.add(200, weth.address, true);
    await sushiMC.add(100, lpToken.address, true);

    const NursePart = await ethers.getContractFactory("NursePart");
    const part = (await NursePart.deploy(cafe.address)) as NursePart;

    const TheMaster = await ethers.getContractFactory("TheMaster");
    const theMaster = (await TheMaster.deploy(
        INITIAL_REWARD_PER_BLOCK,
        5200,
        START_BLOCK,
        coin.address,
        lpToken.address,
        sushi.address
    )) as TheMaster;

    const CloneNurses = await ethers.getContractFactory("CloneNurses");
    const nurses = (await CloneNurses.deploy(
        part.address,
        coin.address,
        theMaster.address,
        cafe.address
    )) as CloneNurses;

    for (let i = 1; i < 7; i++) {
        await lpToken.mint(signers[i].address, tokenAmount(10000));
        await part.connect(signers[i]).setApprovalForAll(nurses.address, true);
        await lpToken.connect(signers[i]).approve(theMaster.address, MaxUint256);
        await part.mint(signers[i].address, 0, 100);
        await part.mint(signers[i].address, 1, 100);
        await part.mint(signers[i].address, 2, 100);
        await part.mint(signers[i].address, 3, 100);
    }

    await coin.transferOwnership(theMaster.address);

    await theMaster.add(master.address, false, false, AddressZero, 0, 10);
    await theMaster.add(lpToken.address, false, false, AddressZero, 0, 9);
    await theMaster.add(nurses.address, true, true, AddressZero, 0, 30);
    await theMaster.add(lpToken.address, false, false, nurses.address, 10, 51);

    return {
        deployer,
        alice,
        bob,
        carol,
        dan,
        erin,
        frank,
        coin,
        sushi,
        sushiMC,
        TheMaster,
        theMaster,
        weth,
        lpToken,
        mockLPToken,
        cafe,
        part,
        nurses,
        master
    };
};

describe("TheMaster", function () {
    beforeEach(async function () {
        await ethers.provider.send("hardhat_reset", []);
    });

    it("should be pass testing overall functions with sushiMasterChef", async function () {
        const { alice, bob, carol, dan, erin, frank, coin, theMaster, sushi, sushiMC, nurses } = await setupTest();
        await nurses.addNurseType([5, 5, 5], [100, 200, 500], [10, 20, 50], [1000, 1000, 125]);
        await theMaster.set([1, 3], [60, 0]);

        await autoMining(false);

        await mineTo(100);
        await theMaster.connect(alice).deposit(1, 100, alice.address);
        await theMaster.connect(bob).deposit(1, 200, bob.address);
        await mine();

        await mineTo(200);
        await theMaster.connect(alice).deposit(1, 100, alice.address);
        await nurses.connect(alice).assemble(0, 5);
        await mine();

        await mineTo(250);
        await theMaster.connect(bob).withdraw(1, 100, bob.address);
        await theMaster.connect(carol).deposit(1, 100, carol.address);
        await nurses.connect(bob).assemble(0, 5);
        await theMaster.connect(alice).support(3, 100, 0);
        await mine();

        await mineTo(300);
        await theMaster.connect(dan).support(3, 400, 1);
        await mine();

        await mineTo(350);
        await theMaster.set([1, 3], [9, 51]);
        await theMaster.connect(alice).deposit(1, 100, alice.address);
        await theMaster.connect(carol).deposit(1, 100, carol.address);
        await nurses.connect(alice).assemble(0, 5);
        await nurses.connect(bob).assemble(1, 5);
        await mine();

        await mineTo(400);
        await theMaster.connect(alice).deposit(1, 0, alice.address);
        await theMaster.connect(bob).withdraw(1, 0, bob.address);
        await theMaster.connect(erin).support(3, 200, 3);
        await mine();

        await mineTo(450);
        await nurses.connect(alice).claim([0, 2]);
        await nurses.connect(frank).assemble(2, 5);
        await theMaster.connect(alice).support(3, 100, 0);
        await mine();

        await mineTo(500);
        await sushi.transferOwnership(sushiMC.address);
        await theMaster.setSushiMasterChef(sushiMC.address, 3);
        await theMaster.connect(dan).desupport(3, 400);
        await mine();

        await mineTo(550);
        await theMaster.connect(alice).deposit(1, 0, alice.address);
        await nurses.connect(bob).claim([1]);
        await theMaster.connect(dan).support(3, 1000, 4);
        await mine();

        await mineTo(600);
        await theMaster.connect(alice).claimAllReward(1);
        await theMaster.connect(carol).claimSushiReward(1);
        await nurses.connect(alice).claim([0,2]);
        await nurses.connect(bob).claim([3]);
        await mine();

        await mineTo(650);
        await nurses.connect(bob).claim([1,3]);
        await theMaster.connect(alice).support(3, 0, 0);
        await mine();

        await mineTo(700);
        await theMaster.connect(alice).deposit(1, 100, alice.address);
        await theMaster.connect(bob).claimAllReward(1);
        await theMaster.connect(carol).deposit(1, 100, carol.address);
        await nurses.connect(frank).claim([4]);
        await theMaster.connect(alice).claimAllReward(3);
        await theMaster.connect(dan).claimAllReward(3);
        //next two transaction doesn't work.
        await theMaster.connect(erin).desupport(3, 0);
        await theMaster.connect(alice).deposit(1, 100, alice.address);
        await mine();
        
        console.log(await ethers.provider.getBlock(await getBlock()));
        console.log("Here is the problem.");

        /***
            hash: '0x585a70cd925d47155c7b180516d7f4a0d77a721f03af499d619b1c6387cad446',
            parentHash: '0xaa1a9cb7c0e733ba20c600c691a7a1cd6560ea98b2c9f7fb5b9daf69db2617f2',
            number: 700,
            timestamp: 1631903292,
            nonce: '0x0000000000000042',
            difficulty: 183960,
            gasLimit: BigNumber { _hex: '0x01c9c380', _isBigNumber: true },
            gasUsed: BigNumber { _hex: '0x10a9ce', _isBigNumber: true },            //I think there is still enough gasLimit.
            miner: '0xC014BA5EC014ba5ec014Ba5EC014ba5Ec014bA5E',
            extraData: '0x',
            transactions: [
                '0x86c08d0da8c121333181876a7e3f8218affa29fc757ec2ad1e9e4b3cf1b41550',
                '0x68660427d353d48f833d8bc26c31f79ef825148dcceba13d9ec8743551d4bfbf',
                '0x71dd75de242b29a15a0fcf3fffcbf28d09e73a20ae26d46d4a2310361513a525',
                '0xa7148cffe22f9238ad54c0661189194dcb694b7e873a02b6522dfd5060b02d52',
                '0x9c075057b0ac3ceea0a4ef2c9a340119174fc69dab4a4cfd575622183224505a',
                '0x627fff7f99991d1356b586146362b1f90e8f71f992f575b401cb8d0806f1c889'            
            ],
            baseFeePerGas: BigNumber { _hex: '0x07', _isBigNumber: true }
        */
    });
});
