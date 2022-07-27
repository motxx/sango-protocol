import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySango } from "./helpers/utils";
import { Contract } from "ethers";

chai.use(solidity);

describe("Contents Royalty Graph", async () => {
  let rbt: Contract;
  let cbt: Contract;
  let s1: SignerWithAddress;

  const RBTProps = {
    creatorProp: 2000,
    cetBurnerProp: 2000,
    cbtStakerProp: 2000,
    primaryProp: 2000,
  };

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
  });

  it("Should construct DAG", async () => {
    const first = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...RBTProps,
    });
    const second = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address],
      primaryShares: [100],
      ...RBTProps,
    });
    const third = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, second.address],
      primaryShares: [200, 300],
      ...RBTProps,
    });
    assert.deepEqual(await first.getPrimaries(), []);
    assert.deepEqual(await second.getPrimaries(), [first.address]);
    assert.deepEqual(await third.getPrimaries(), [first.address, second.address]);
  });

  it("Should not have duplicate creators", async () => {
    await expect(deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address, s1.address],
      creatorShares: [1, 2],
      primaries: [],
      primaryShares: [],
      ...RBTProps,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });

  it("Should not have duplicate primaries", async () => {
    const first = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [],
      primaryShares: [],
      ...RBTProps,
    });
    await expect(deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, first.address],
      primaryShares: [100, 200],
      ...RBTProps,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });
});

describe("Content Believe Token", async () => {
  let rbt: Contract;
  let cbt: Contract;
  let wCBT: Contract;
  let owner: SignerWithAddress;
  let cbtWallet: SignerWithAddress;
  let s1: SignerWithAddress;
  let sango: Contract;

  const RBTProps = {
    creatorProp: 2000,
    cetBurnerProp: 2000,
    cbtStakerProp: 2000,
    primaryProp: 2000,
  };

  beforeEach(async () => {
    [owner, cbtWallet, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);
    sango = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...RBTProps,
    });
    const wCBTAddress = await sango.wrappedCBT();
    wCBT = await ethers.getContractAt("WrappedCBT", wCBTAddress);
  });

  it("Should stake", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    expect(await cbt.balanceOf(s1.address)).equals(100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await sango.connect(s1).stake(100);
    expect(await sango.connect(s1).isStaking(s1.address)).true;
    expect(await cbt.connect(s1).balanceOf(s1.address)).equals(0);
  });

  it("Should receiveWCBT after lock interval", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await ethers.provider.send("evm_mine", [10000000000]);
    await sango.setLockInterval(1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await sango.connect(s1).stake(100);
    await ethers.provider.send("evm_mine", [10000000999]);
    await expect(sango.connect(s1).receiveWCBT()).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: within lock interval'");
    await ethers.provider.send("evm_mine", [10000001010]);
    await sango.connect(s1).receiveWCBT();
    expect(await sango.connect(s1).isStaking(s1.address)).true;
    expect(await wCBT.balanceOf(s1.address)).equals(100);
  });
});

describe("Content Excited Token", async () => {
  let rbt: Contract;
  let cbt: Contract;
  let cet: Contract;
  let s1: SignerWithAddress;
  let sango: Contract;

  const RBTProps = {
    creatorProp: 2000,
    cetBurnerProp: 2000,
    cbtStakerProp: 2000,
    primaryProp: 2000,
  };

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
    sango = await deploySango({
      rbt: rbt.address,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...RBTProps,
    });
    cet = await ethers.getContractAt("CET", await sango.cet());
  });

  it("Should mintCET / burnCET", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();
    const cet = await ethers.getContractAt("CET", await sango.cet());
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);

    await sango.setExcitingModules([em1.address]);
    await sango.approveCETReceiver(s1.address);
    await sango.mintCET(s1.address);
    expect(await cet.balanceOf(s1.address)).to.equal(10000);
    await sango.connect(s1).burnCET(9000);
    expect(await sango.getBurnedCET(s1.address)).to.equal(9000);
    expect(await cet.balanceOf(s1.address)).to.equal(1000);
  });

  it("Should mintCET by multiple exciting modules", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();
    const em2 = await ExcitingModule.deploy();

    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();
    const mo2 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);
    await em2.setCETOracle(cet.address, mo2.address);

    await sango.setExcitingModules([em1.address, em2.address]);
    await sango.approveCETReceiver(s1.address);
    await sango.mintCET(s1.address);
    expect(await cet.balanceOf(s1.address)).to.equal(20000);
  });

  it("Should not mintCET if no additional engagement got", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();

    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);

    await sango.setExcitingModules([em1.address]);
    await sango.approveCETReceiver(s1.address);
    await sango.mintCET(s1.address);
    await expect(sango.mintCET(s1.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'ExcitingModule: no amount to mint'");
  });
});
