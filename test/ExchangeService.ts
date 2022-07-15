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
    })
  });
});
