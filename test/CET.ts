import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { deploySango, deploySangoBy } from "./helpers/utils";

chai.use(solidity);

describe("Content Excited Token", async () => {
  let cetOwner: SignerWithAddress;
  let excitingModule: SignerWithAddress;
  let s1: SignerWithAddress;
  let cet: Contract;

  beforeEach(async () => {
    [, cetOwner, excitingModule, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    const cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");

    const sango = await deploySangoBy(cetOwner, {
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 2000,
      cetHoldersAlloc: 2000,
      cbtStakersAlloc: 2000,
      primariesAlloc: 2000,
    });

    cet = await ethers.getContractAt("CET", await sango.cet());
  });

  describe("When CET modules are set up", async () => {
    beforeEach(async () => {
      await cet.connect(cetOwner).setExcitingModules([excitingModule.address]);
    });

    it("Should statementOfCommit", async () => {
      await cet.connect(s1).statementOfCommit();
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(0);
    });
  
    it("Should mintCET", async () => {
      await cet.connect(s1).statementOfCommit();
      await cet.connect(excitingModule).mintCET(s1.address, 1000);
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(1000);
    });
    /*
    it("Should claimCET", async () => {
      await cet.connect(s1).statementOfCommit();
      await cet.connect(s1).claimCET(s1.address); // TODO: Implement mint logic to calc CET value.
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(1000);
    });
    */
  });
});

describe("Delegate CET mint to ExcitingModule", async () => {
  let cbt: Contract;
  let cet: Contract;
  let s1: SignerWithAddress;
  let sango: Contract;

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
    sango = await deploySango({
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 2000,
      cetHoldersAlloc: 2000,
      cbtStakersAlloc: 2000,
      primariesAlloc: 2000,
    });
    cet = await ethers.getContractAt("CET", await sango.cet());
  });

  it("Should claimCET", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);

    await cet.setExcitingModules([em1.address]);
    await cet.connect(s1).statementOfCommit();
    await cet.connect(s1).claimCET(s1.address);
    expect(await cet.balanceOf(s1.address)).equals(1);
    expect(await cet.holdingAmount(s1.address)).equals(10000);
  });

  it("Should claimCET by multiple exciting modules", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();
    const em2 = await ExcitingModule.deploy();

    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();
    const mo2 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);
    await em2.setCETOracle(cet.address, mo2.address);

    await cet.setExcitingModules([em1.address, em2.address]);
    await cet.connect(s1).statementOfCommit();
    await cet.connect(s1).claimCET(s1.address);
    expect(await cet.holdingAmount(s1.address)).equals(20000);
  });

  it("Should not claimCET if no additional engagement got", async () => {
    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em1 = await ExcitingModule.deploy();

    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo1 = await MockOracle.deploy();

    await em1.setCETOracle(cet.address, mo1.address);

    await cet.setExcitingModules([em1.address]);
    await cet.connect(s1).statementOfCommit();
    await cet.connect(s1).claimCET(s1.address);
    await expect(cet.connect(s1).claimCET(s1.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'ExcitingModule: no amount to mint'");
  });
});
