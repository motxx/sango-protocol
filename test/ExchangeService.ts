import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySangoBy, getCreators, getPrimaries, getWrappedCBT, getCET } from "./helpers/utils";

chai.use(solidity);

describe("ExchangeService", () => {
  let exchangeService: Contract;
  let rbt: Contract;
  let cbt: Contract;
  let sango1: Contract;
  let sango2: Contract;
  let royaltyProvider: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  const distributeRoyalty = async (sango: Contract, amount: number) => {
    await exchangeService.mint(royaltyProvider.address, amount);
    await rbt.connect(royaltyProvider).approve(sango.address, amount);
    await sango.connect(royaltyProvider).distribute(rbt.address, amount);
  };

  beforeEach(async () => {
    [, royaltyProvider, s1, s2] = await ethers.getSigners();

    const ExchangeService = await ethers.getContractFactory("ExchangeService");
    exchangeService = await ExchangeService.deploy();
    await exchangeService.deployed();
    const rbtAddress = await exchangeService.rbt();
    rbt = await ethers.getContractAt("RBT", rbtAddress);
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");

    sango1 = await deploySangoBy(s1, {
      cbt: cbt.address,
      approvedTokens: [rbt.address],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 10000,
      cetHoldersAlloc: 0,
      cbtStakersAlloc: 0,
      primariesAlloc: 0,
    });

    sango2 = await deploySangoBy(s2, {
      cbt: cbt.address,
      approvedTokens: [rbt.address],
      creators: [s2.address],
      creatorShares: [1],
      primaries: [sango1.address],
      primaryShares: [1],
      creatorsAlloc: 5000,
      cetHoldersAlloc: 0,
      cbtStakersAlloc: 0,
      primariesAlloc: 5000,
    });
  });

  describe("mint", () => {
    it("Should mint RBT", async () => {
      await distributeRoyalty(sango1, 1000);
      expect(await exchangeService.totalSupply()).to.equal(1000);
      expect(await rbt.balanceOf(sango1.address)).to.equal(1000);

      await sango1.forceClaimAll(rbt.address);
      await (await (getCreators(sango1))).claimNext(s1.address, rbt.address);

      expect(await rbt.balanceOf(s1.address)).to.equal(1000);
    });

    it("Should not mint RBT if caller is not the owner", async () => {
      await expect(exchangeService.connect(s1).mint(royaltyProvider.address, 1000)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
    });
  });

  describe("burn", () => {
    it("Should burn RBT", async () => {
      await distributeRoyalty(sango1, 1000);
      await sango1.forceClaimAll(rbt.address);
      const creators = await getCreators(sango1);
      await creators.claimNext(s1.address, rbt.address);

      await exchangeService.connect(s1).burn(1000);
      expect(await exchangeService.totalSupply()).to.equal(0);
      expect(await rbt.balanceOf(s1.address)).to.equal(0);
    });

    it("Should not burn RBT if burn amount exceeds totalSupply", async () => {
      await distributeRoyalty(sango1, 1000);
      await sango1.forceClaimAll(rbt.address);
      const creators = await getCreators(sango1);
      await creators.claimNext(s1.address, rbt.address);

      await expect(exchangeService.connect(s1).burn(1100)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ExchnageService: burn amount exceeds totalSupply'");
    });

    it("Should not burn RBT if burn amount exceeds account balance", async () => {
      await distributeRoyalty(sango1, 1000);
      await sango1.forceClaimAll(rbt.address);
      await (await (getCreators(sango1))).claimNext(s1.address, rbt.address);

      await distributeRoyalty(sango2, 1000);
      await sango2.forceClaimAll(rbt.address);
      const sango2Creators = await getCreators(sango2);
      await sango2Creators.claimNext(s2.address, rbt.address);

      await expect(exchangeService.connect(s1).burn(1100)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ERC20: burn amount exceeds balance'");
    });
  });

  describe("totalSupply", () => {
    it("Should increase totalSupply", async () => {
      await distributeRoyalty(sango1, 1000);
      expect(await exchangeService.totalSupply()).to.equal(1000);

      await distributeRoyalty(sango2, 100);
      expect(await exchangeService.totalSupply()).to.equal(1100);
    });

    it("Should decrease totalSupply", async () => {
      await distributeRoyalty(sango1, 1000);
      await sango1.forceClaimAll(rbt.address);
      await (await (getCreators(sango1))).claimNext(s1.address, rbt.address);

      await distributeRoyalty(sango2, 100);
      await sango2.forceClaimAll(rbt.address);
      await (await (getCreators(sango2))).claimNext(s2.address, rbt.address);

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
  let royaltyProvider: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;
  let s3: SignerWithAddress;
  let s4: SignerWithAddress;
  let s5: SignerWithAddress;
  let s6: SignerWithAddress;
  let sOther: SignerWithAddress;

  const distributeRoyalty = async (sango: Contract, amount: number) => {
    await exchangeService.mint(royaltyProvider.address, amount);
    await rbt.connect(royaltyProvider).approve(sango.address, amount);
    await sango.connect(royaltyProvider).distribute(rbt.address, amount);
  };

  beforeEach(async () => {
    [, cbtWallet, royaltyProvider, s1, s2, s3, s4, s5, s6, sOther] = await ethers.getSigners();

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
      primariesAlloc: number,
    ) => {
      const sango = await deploySangoBy(signer, {
        cbt: cbt.address,
        approvedTokens: [rbt.address],
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorsAlloc: 10000 - primariesAlloc,
        cetHoldersAlloc: 0,
        cbtStakersAlloc: 0,
        primariesAlloc,
      });
      return sango;
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

    await distributeRoyalty(C6, 10000);
    await C6.forceClaimAll(rbt.address);
    await (await getCreators(C6)).claimNext(s6.address, rbt.address);
    expect(await rbt.balanceOf(s6.address)).to.equal(8000);
    await (await getPrimaries(C6)).claimNext(C4.address, rbt.address);
    await (await getPrimaries(C6)).claimNext(C5.address, rbt.address);
    expect(await rbt.balanceOf(C4.address)).to.equal(1000);
    expect(await rbt.balanceOf(C5.address)).to.equal(1000);
    await C4.forceClaimAll(rbt.address);
    await C5.forceClaimAll(rbt.address);
    await (await getCreators(C4)).claimNext(s4.address, rbt.address);
    await (await getCreators(C5)).claimNext(s5.address, rbt.address);
    expect(await rbt.balanceOf(s4.address)).to.equal(900);
    expect(await rbt.balanceOf(s5.address)).to.equal(900);
    await (await getPrimaries(C4)).claimNext(C1.address, rbt.address);
    await (await getPrimaries(C4)).claimNext(C2.address, rbt.address);
    await (await getPrimaries(C5)).claimNext(C2.address, rbt.address);
    await (await getPrimaries(C5)).claimNext(C3.address, rbt.address);
    expect(await rbt.balanceOf(C1.address)).to.equal(66);
    expect(await rbt.balanceOf(C2.address)).to.equal(66);
    expect(await rbt.balanceOf(C3.address)).to.equal(66);
    await C1.forceClaimAll(rbt.address);
    await C2.forceClaimAll(rbt.address);
    await C3.forceClaimAll(rbt.address);
    await (await getCreators(C1)).claimNext(s1.address, rbt.address);
    await (await getCreators(C2)).claimNext(s2.address, rbt.address);
    await (await getCreators(C3)).claimNext(s3.address, rbt.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(66);
    expect(await rbt.balanceOf(s2.address)).to.equal(66);
    expect(await rbt.balanceOf(s3.address)).to.equal(66);
  });

  it("Should distribute royalties to CBT stakers of primary contents", async () => {
    const deploySango_ = async (
      signer: SignerWithAddress,
      creators: string[],
      creatorShares: number[],
      primaries: string[],
      primaryShares: number[],
      primariesAlloc: number,
    ) => {
      const sango = await deploySangoBy(signer, {
        cbt: cbt.address,
        approvedTokens: [rbt.address],
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorsAlloc: 0,
        cetHoldersAlloc: 0,
        cbtStakersAlloc: 10000 - primariesAlloc,
        primariesAlloc,
      });
      return sango;
    };

    // - Setup -
    // Create contents royalty graph.
    /**
     *     ┌─┐s5
     *  ┌──└C4──┐
     * ┌▼┐s2,3 ┌▼┐s4
     * └C2     └C3
     *  │  ┌─┐s1│
     *  └─►└C1◄─┘
     */

    const C1 = await deploySango_(sOther, [], [], [], [], 1000);
    const C2 = await deploySango_(sOther, [], [], [C1.address], [1], 1000);
    const C3 = await deploySango_(sOther, [], [], [C1.address], [1], 1000);
    const C4 = await deploySango_(sOther, [], [], [C2.address, C3.address], [1, 1], 2000);

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
    await distributeRoyalty(C4, 10000);

    await C4.forceClaimAll(rbt.address);
    await (await getWrappedCBT(C4)).claimNext(s5.address, rbt.address);
    expect(await rbt.balanceOf(s5.address)).to.equal(8000);

    await (await getPrimaries(C4)).claimNext(C2.address, rbt.address);
    await (await getPrimaries(C4)).claimNext(C3.address, rbt.address);
    expect(await rbt.balanceOf(C2.address)).to.equal(1000);
    expect(await rbt.balanceOf(C3.address)).to.equal(1000);

    await C2.forceClaimAll(rbt.address);
    await C3.forceClaimAll(rbt.address);
    await (await getWrappedCBT(C2)).claimNext(s3.address, rbt.address);
    await (await getWrappedCBT(C3)).claimNext(s4.address, rbt.address);
    expect(await rbt.balanceOf(s3.address)).to.equal(900);
    expect(await rbt.balanceOf(s4.address)).to.equal(900);

    await (await getPrimaries(C2)).claimNext(C1.address, rbt.address);
    await (await getPrimaries(C3)).claimNext(C1.address, rbt.address);
    await C1.forceClaimAll(rbt.address);
    await (await getWrappedCBT(C1)).claimNext(s1.address, rbt.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(180);

    // s2 claims wCBT after distribution, but cannot get royalties.
    await wCBT2.connect(s2).claimWCBT();
    await (await getWrappedCBT(C2)).claimNext(s2.address, rbt.address);

    expect(await rbt.balanceOf(s2.address)).to.equal(0);
    await expect((await getWrappedCBT(C2)).claimNext(s2.address, rbt.address)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: no more incoming amount exists'");
  });

  it("Should distribute royalties to CET holders of primary contents", async () => {
    const deploySango_ = async (
      signer: SignerWithAddress,
      creators: string[],
      creatorShares: number[],
      primaries: string[],
      primaryShares: number[],
      primariesAlloc: number,
    ) => {
      const sango = await deploySangoBy(signer, {
        cbt: cbt.address,
        approvedTokens: [rbt.address],
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorsAlloc: 0,
        cetHoldersAlloc: 10000 - primariesAlloc,
        cbtStakersAlloc: 0,
        primariesAlloc,
      });
      return sango;
    };

    // - Setup -
    // Create contents royalty graph.
    /**
     *     ┌─┐s5
     *  ┌──└C4──┐
     * ┌▼┐s2,3 ┌▼┐s4
     * └C2     └C3
     *  │  ┌─┐s1│
     *  └─►└C1◄─┘
     */

    const C1 = await deploySango_(sOther, [], [], [], [], 1000);
    const C2 = await deploySango_(sOther, [], [], [C1.address], [1], 1000);
    const C3 = await deploySango_(sOther, [], [], [C1.address], [1], 1000);
    const C4 = await deploySango_(sOther, [], [], [C2.address, C3.address], [1, 1], 2000);

    // Assign mock oracles.
    const cet1 = await ethers.getContractAt("CET", await C1.cet());
    const cet2 = await ethers.getContractAt("CET", await C2.cet());
    const cet3 = await ethers.getContractAt("CET", await C3.cet());
    const cet4 = await ethers.getContractAt("CET", await C4.cet());

    const ExcitingModule = await ethers.getContractFactory("ExcitingModule");
    const em = await ExcitingModule.deploy();
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const mo = await MockOracle.deploy();

    await em.setCETOracle(cet1.address, mo.address);
    await em.setCETOracle(cet2.address, mo.address);
    await em.setCETOracle(cet3.address, mo.address);
    await em.setCETOracle(cet4.address, mo.address);
    await cet1.connect(sOther).setExcitingModules([em.address]);
    await cet2.connect(sOther).setExcitingModules([em.address]);
    await cet3.connect(sOther).setExcitingModules([em.address]);
    await cet4.connect(sOther).setExcitingModules([em.address]);

    // s1 ~ s5 statementOfCommit to contents.
    await cet1.connect(s1).statementOfCommit();
    await cet2.connect(s2).statementOfCommit();
    await cet2.connect(s3).statementOfCommit();
    await cet3.connect(s4).statementOfCommit();
    await cet4.connect(s5).statementOfCommit();

    await cet1.connect(s1).claimCET(s1.address);
    /* s2 not claimed yet. */
    await cet2.connect(s3).claimCET(s3.address);
    await cet3.connect(s4).claimCET(s4.address);
    await cet4.connect(s5).claimCET(s5.address);

    // - Execute & Verify -
    // Mint royalties to C4 and distribute them.
    // Each stakers can get royalties except s2.
    await distributeRoyalty(C4, 10000);

    await C4.forceClaimAll(rbt.address);
    await (await getCET(C4)).claimNext(s5.address, rbt.address);
    expect(await rbt.balanceOf(s5.address)).to.equal(8000);
    await (await getPrimaries(C4)).claimNext(C2.address, rbt.address);
    await (await getPrimaries(C4)).claimNext(C3.address, rbt.address);
    expect(await rbt.balanceOf(C2.address)).to.equal(1000);
    expect(await rbt.balanceOf(C3.address)).to.equal(1000);

    await C2.forceClaimAll(rbt.address);
    await C3.forceClaimAll(rbt.address);
    await (await getCET(C2)).claimNext(s3.address, rbt.address);
    await (await getCET(C3)).claimNext(s4.address, rbt.address);
    expect(await rbt.balanceOf(s3.address)).to.equal(900);
    expect(await rbt.balanceOf(s4.address)).to.equal(900);

    await (await getPrimaries(C2)).claimNext(C1.address, rbt.address);
    await (await getPrimaries(C3)).claimNext(C1.address, rbt.address);
    await C1.forceClaimAll(rbt.address);
    await (await getCET(C1)).claimNext(s1.address, rbt.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(180);

    // s2 claims CET after distribution, but cannot get royalties.
    await cet2.connect(s2).claimCET(s2.address);
    await (await getCET(C2)).claimNext(s2.address, rbt.address);

    expect(await rbt.balanceOf(s2.address)).to.equal(0);
    await expect((await getCET(C2)).claimNext(s2.address, rbt.address)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: no more incoming amount exists'");
  });
});
