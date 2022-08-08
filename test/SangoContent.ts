import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySango, getCreators, getPrimaries, getWrappedCBT, getCET, getTreasury } from "./helpers/utils";
import { Contract } from "ethers";

chai.use(solidity);

describe("Contents Royalty Graph", async () => {
  let cbt: Contract;
  let s1: SignerWithAddress;

  const DefaultAllocs = {
    creatorsAlloc: 2000,
    cbtStakersAlloc: 2000,
    cetHoldersAlloc: 2000,
    primariesAlloc: 2000,
  };

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
  });

  it("Should construct DAG", async () => {
    const first = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...DefaultAllocs,
    });
    const second = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address],
      primaryShares: [100],
      ...DefaultAllocs,
    });
    const third = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, second.address],
      primaryShares: [200, 300],
      ...DefaultAllocs,
    });
    expect(await (await getPrimaries(first)).accounts()).deep.equals([]);
    expect(await (await getPrimaries(second)).accounts()).deep.equals([first.address]);
    expect(await (await getPrimaries(third)).accounts()).deep.equals([first.address, second.address]);
  });

  it("Should not have duplicate primaries", async () => {
    const first = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [],
      primaryShares: [],
      ...DefaultAllocs,
    });
    await expect(deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, first.address],
      primaryShares: [100, 200],
      ...DefaultAllocs,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'FixedRoyaltyClaimRight: duplicate accounts'");
  });
});

describe("setRoyaltyAllocation", async () => {
  let content: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let creators: Contract;
  let wCBT: Contract;
  let cet: Contract;
  let primaries: Contract;
  let treasury: Contract;

  beforeEach(async () => {
    [owner, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    const cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
    content = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 10,
      cbtStakersAlloc: 20,
      cetHoldersAlloc: 30,
      primariesAlloc: 40,
    });
    creators = await getCreators(content);
    wCBT = await getWrappedCBT(content)
    cet = await getCET(content);
    primaries = await getPrimaries(content);
    treasury = await getTreasury(content);
  });

  it("Should verify constructor allocations", async () => {
    expect(await content.balanceOf(creators.address)).equals(10);
    expect(await content.balanceOf(wCBT.address)).equals(20);
    expect(await content.balanceOf(cet.address)).equals(30);
    expect(await content.balanceOf(primaries.address)).equals(40);
    expect(await content.balanceOf(treasury.address)).equals(9900);
  });

  it("Should verify allocations are updated", async () => {
    await content.setRoyaltyAllocation(
      100,
      200,
      300,
      400
    );
    expect(await content.balanceOf(creators.address)).equals(100);
    expect(await content.balanceOf(wCBT.address)).equals(200);
    expect(await content.balanceOf(cet.address)).equals(300);
    expect(await content.balanceOf(primaries.address)).equals(400);
    expect(await content.balanceOf(treasury.address)).equals(9000);
  });
});

describe("forceClaimAll", async () => {
  let content: Contract;
  let erc20: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;

  beforeEach(async () => {
    [owner, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    const cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy();
    await erc20.mint(owner.address, 1000);

    content = await deploySango({
      cbt: cbt.address,
      approvedTokens: [erc20.address],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 100,
      cbtStakersAlloc: 200,
      cetHoldersAlloc: 300,
      primariesAlloc: 400,
    });
  });

  it("Should verify all allocs are claimed", async () => {
    const creators = await getCreators(content);
    const wCBT = await getWrappedCBT(content)
    const cet = await getCET(content);
    const primaries = await getPrimaries(content);
    const treasury = await getTreasury(content);

    await erc20.approve(content.address, 100);
    await content.distribute(erc20.address, 100);
    await content.forceClaimAll(erc20.address);

    expect(await erc20.balanceOf(creators.address)).equals(1);
    expect(await erc20.balanceOf(wCBT.address)).equals(2);
    expect(await erc20.balanceOf(await cet.claimRight())).equals(3);
    expect(await erc20.balanceOf(primaries.address)).equals(4);
    expect(await erc20.balanceOf(treasury.address)).equals(90);
  });
});
