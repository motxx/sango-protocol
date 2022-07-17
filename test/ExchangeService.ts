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

    sango1 = await deploySangoBy(s1, {
      rbtAddress,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorProp: 10000,
      cetBurnerProp: 0,
      cbtStakerProp: 0,
      primaryProp: 0,
    });
    await sango1.deployed();

    sango2 = await deploySangoBy(s2, {
      rbtAddress,
      creators: [s2.address],
      creatorShares: [1],
      primaries: [sango1.address],
      primaryShares: [1],
      creatorProp: 5000,
      cetBurnerProp: 0,
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

describe("distribute on DAG", () => {
  let exchangeService: Contract;
  let rbt: Contract;
  let rbtAddress: string;

  beforeEach(async () => {
    const ExchangeService = await ethers.getContractFactory("ExchangeService");
    exchangeService = await ExchangeService.deploy();
    await exchangeService.deployed();
    rbtAddress = await exchangeService.rbt();
    rbt = await ethers.getContractAt("RBT", rbtAddress);
  });

  it("Should verify balance of the creators of primary contents", async () => {
    /**
     *         ┌─┐
     *      ┌──┴C6──┐
     *     ┌▼┐     ┌▼┐
     *  ┌──┴C4──┬──┴C5──┐
     * ┌▼┐     ┌▼┐     ┌▼┐
     * └C1     └C2     └C3
     */

    const [, s1, s2, s3, s4, s5, s6] = await ethers.getSigners();

    const deploySango_ = async (
      signer: SignerWithAddress,
      creators: string[],
      creatorShares: number[],
      primaries: string[],
      primaryShares: number[],
      primaryProp: number,
    ) => {
      return await deploySangoBy(signer, {
        rbtAddress,
        creators,
        creatorShares,
        primaries,
        primaryShares,
        creatorProp: 10000 - primaryProp,
        cetBurnerProp: 0,
        cbtStakerProp: 0,
        primaryProp,
      });
    };

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
});