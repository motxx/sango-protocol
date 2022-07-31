import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySangoBy } from "./helpers/utils";

chai.use(solidity);

describe("ExchangeService", () => {
  let exchangeService: Contract;
  let rbt: Contract;
  let cbt: Contract;
  let sango1: Contract;
  let sango2: Contract;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  beforeEach(async () => {
    [, s1, s2] = await ethers.getSigners();

    const ExchangeService = await ethers.getContractFactory("ExchangeService");
    exchangeService = await ExchangeService.deploy();
    await exchangeService.deployed();
    const rbtAddress = await exchangeService.rbt();
    rbt = await ethers.getContractAt("RBT", rbtAddress);
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");

    sango1 = await deploySangoBy(s1, {
      rbt: rbtAddress,
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorProp: 10000,
      cetHolderProp: 0,
      cbtStakerProp: 0,
      primaryProp: 0,
    });
    await sango1.deployed();

    sango2 = await deploySangoBy(s2, {
      rbt: rbtAddress,
      cbt: cbt.address,
      creators: [s2.address],
      creatorShares: [1],
      primaries: [sango1.address],
      primaryShares: [1],
      creatorProp: 5000,
      cetHolderProp: 0,
      cbtStakerProp: 0,
      primaryProp: 5000,
    });
    await sango2.deployed();
  });

  describe("mint", () => {
    it("Should mint RBT", async () => {
      await exchangeService.mint(sango1.address, 1000);
      expect(await exchangeService.totalSupply()).to.equal(1000);
      expect(await rbt.balanceOf(sango1.address)).to.equal(1000);

      await sango1.releaseCreatorShares(s1.address);
      expect(await rbt.balanceOf(s1.address)).to.equal(1000);
    });

    it("Should not mint RBT if caller is not the owner", async () => {
      await expect(exchangeService.connect(s1).mint(sango1.address, 1000)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
    });
  });

  describe("burn", () => {
    it("Should burn RBT", async () => {
      await exchangeService.mint(sango1.address, 1000);
      await sango1.releaseCreatorShares(s1.address);

      await exchangeService.connect(s1).burn(1000);
      expect(await exchangeService.totalSupply()).to.equal(0);
      expect(await rbt.balanceOf(s1.address)).to.equal(0);
    });

    it("Should not burn RBT if burn amount exceeds totalSupply", async () => {
      await exchangeService.mint(sango1.address, 1000);
      await sango1.releaseCreatorShares(s1.address);

      await expect(exchangeService.connect(s1).burn(1100)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ExchnageService: burn amount exceeds totalSupply'");
    });

    it("Should not burn RBT if burn amount exceeds account balance", async () => {
      await exchangeService.mint(sango1.address, 1000);
      await exchangeService.mint(sango2.address, 1000);
      await sango1.releaseCreatorShares(s1.address);

      await expect(exchangeService.connect(s1).burn(1100)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ERC20: burn amount exceeds balance'");
    });
  });

  describe("totalSupply", () => {
    it("Should increase totalSupply", async () => {
      await exchangeService.mint(sango1.address, 1000);
      expect(await exchangeService.totalSupply()).to.equal(1000);
      await exchangeService.mint(sango2.address, 100);
      expect(await exchangeService.totalSupply()).to.equal(1100);
    });

    it("Should decrease totalSupply", async () => {
      await exchangeService.mint(sango1.address, 1000);
      await exchangeService.mint(sango2.address, 100);
      await sango1.releaseCreatorShares(s1.address);
      await sango2.releaseCreatorShares(s2.address);
      expect(await exchangeService.totalSupply()).to.equal(1100);

      await exchangeService.connect(s1).burn(100);
      expect(await exchangeService.totalSupply()).to.equal(1000);

      await exchangeService.connect(s2).burn(10);
      expect(await exchangeService.totalSupply()).to.equal(990);
    });
  });
});

describe("E2E", () => {
  let exchangeService: Contract;
  let rbt: Contract;
  let cbt: Contract;
  let rbtAddress: string;
  let cbtWallet: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;
  let s3: SignerWithAddress;
  let s4: SignerWithAddress;
  let s5: SignerWithAddress;
  let s6: SignerWithAddress;

  beforeEach(async () => {
    [, cbtWallet, s1, s2, s3, s4, s5, s6] = await ethers.getSigners();

    const ExchangeService = await ethers.getContractFactory("ExchangeService");
    exchangeService = await ExchangeService.deploy();
    await exchangeService.deployed();
    rbtAddress = await exchangeService.rbt();
    rbt = await ethers.getContractAt("RBT", rbtAddress);
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);
  });

  it("Should distribute royalties to creators of primary contents", async () => {
    const deploySango_ = async (
      signer: SignerWithAddress,
      creators: string[],
      creatorShares: number[],
      primaries: string[],
      primaryShares: number[],
      primaryProp: number,
    ) => {
      return await deploySangoBy(signer, {
        rbt: rbtAddress,
        cbt: cbt.address,
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorProp: 10000 - primaryProp,
        cetHolderProp: 0,
        cbtStakerProp: 0,
        primaryProp,
      });
    };

    /**
     *         ┌─┐
     *      ┌──┴C6──┐
     *     ┌▼┐     ┌▼┐
     *  ┌──┴C4──┬──┴C5──┐
     * ┌▼┐     ┌▼┐     ┌▼┐
     * └C1     └C2     └C3
     */

    const C1 = await deploySango_(s1, [s1.address], [1], [], [], 0);
    const C2 = await deploySango_(s2, [s2.address], [1], [], [], 0);
    const C3 = await deploySango_(s3, [s3.address], [1], [], [], 0);
    const C4 = await deploySango_(s4, [s4.address], [1], [C1.address, C2.address], [2, 1], 1000);
    const C5 = await deploySango_(s5, [s5.address], [1], [C2.address, C3.address], [1, 2], 1000);
    const C6 = await deploySango_(s6, [s6.address], [1], [C4.address, C5.address], [1, 1], 2000);

    await exchangeService.mint(C6.address, 10000);
    await C6.releaseCreatorShares(s6.address);
    expect(await rbt.balanceOf(s6.address)).to.equal(8000);
    await C6.releasePrimaryShares(C4.address);
    await C6.releasePrimaryShares(C5.address);
    expect(await rbt.balanceOf(C4.address)).to.equal(1000);
    expect(await rbt.balanceOf(C5.address)).to.equal(1000);
    expect(await rbt.balanceOf(s4.address)).to.equal(0);
    expect(await rbt.balanceOf(s5.address)).to.equal(0);
    await C4.releaseCreatorShares(s4.address);
    await C5.releaseCreatorShares(s5.address);
    expect(await rbt.balanceOf(s4.address)).to.equal(900);
    expect(await rbt.balanceOf(s5.address)).to.equal(900);
    await C4.releasePrimaryShares(C1.address);
    await C4.releasePrimaryShares(C2.address);
    await C5.releasePrimaryShares(C2.address);
    await C5.releasePrimaryShares(C3.address);
    expect(await rbt.balanceOf(C1.address)).to.equal(67);
    expect(await rbt.balanceOf(C2.address)).to.equal(67);
    expect(await rbt.balanceOf(C3.address)).to.equal(66);
  });

  it("Should distribute royalties to CBT stakers of primary contents", async () => {
    const deploySango_ = async (
      signer: SignerWithAddress,
      creators: string[],
      creatorShares: number[],
      primaries: string[],
      primaryShares: number[],
      primaryProp: number,
    ) => {
      return await deploySangoBy(signer, {
        rbt: rbtAddress,
        cbt: cbt.address,
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorProp: 0,
        cetHolderProp: 0,
        cbtStakerProp: 10000 - primaryProp,
        primaryProp,
      });
    };

    /**
     *     ┌─┐s5
     *  ┌──└C4──┐
     * ┌▼┐s2,3 ┌▼┐s4
     * └C2     └C3
     *  │  ┌─┐s1│
     *  └─►└C1◄─┘
     */

    const C1 = await deploySango_(s1, [], [], [], [], 1000);
    const C2 = await deploySango_(s2, [], [], [C1.address], [1], 1000);
    const C3 = await deploySango_(s3, [], [], [C1.address], [1], 1000);
    const C4 = await deploySango_(s4, [], [], [C2.address, C3.address], [1, 1], 2000);

    // - Setup -
    // s1 ~ s5 get 100 CBT and stake them to contents.
    const wCBT1 = await ethers.getContractAt("WrappedCBT", await C1.wrappedCBT());
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT1.address, 100);
    await wCBT1.connect(s1).stake(100);

    const wCBT2 = await ethers.getContractAt("WrappedCBT", await C2.wrappedCBT());
    await cbt.connect(cbtWallet).transfer(s2.address, 100);
    await cbt.connect(s2).approve(wCBT2.address, 100);
    await wCBT2.connect(s2).stake(100);
    await cbt.connect(cbtWallet).transfer(s3.address, 200);
    await cbt.connect(s3).approve(wCBT2.address, 200);
    await wCBT2.connect(s3).stake(200);

    const wCBT3 = await ethers.getContractAt("WrappedCBT", await C3.wrappedCBT());
    await cbt.connect(cbtWallet).transfer(s4.address, 100);
    await cbt.connect(s4).approve(wCBT3.address, 100);
    await wCBT3.connect(s4).stake(100);

    const wCBT4 = await ethers.getContractAt("WrappedCBT", await C4.wrappedCBT());
    await cbt.connect(cbtWallet).transfer(s5.address, 100);
    await cbt.connect(s5).approve(wCBT4.address, 100);
    await wCBT4.connect(s5).stake(100);

    // s1, s3 ~ s5 claim wCBT.
    await wCBT1.connect(s1).claimWCBT();
    /* s2 not claimed yet */
    await wCBT2.connect(s3).claimWCBT();
    await wCBT3.connect(s4).claimWCBT();
    await wCBT4.connect(s5).claimWCBT();

    // - Execute & Verify -
    // Mint royalties to C4 and distribute them.
    // Each stakers can get royalties except s2.
    await exchangeService.mint(C4.address, 10000);

    await C4.releaseCBTStakerShares(s5.address);
    expect(await rbt.balanceOf(s5.address)).to.equal(8000);

    await C4.releasePrimaryShares(C2.address);
    await C4.releasePrimaryShares(C3.address);
    expect(await rbt.balanceOf(C2.address)).to.equal(1000);
    expect(await rbt.balanceOf(C3.address)).to.equal(1000);
    await C2.releaseCBTStakerShares(s3.address);
    await C3.releaseCBTStakerShares(s4.address);
    expect(await rbt.balanceOf(s3.address)).to.equal(900);
    expect(await rbt.balanceOf(s4.address)).to.equal(900);

    await C2.releasePrimaryShares(C1.address);
    await C3.releasePrimaryShares(C1.address);
    await C1.releaseCBTStakerShares(s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(180);

    // s2 claims wCBT, but cannot get royalties.
    await wCBT2.connect(s2).claimWCBT();
    await expect(C2.releaseCBTStakerShares(s2.address)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: account is not due payment'");
  });
});
