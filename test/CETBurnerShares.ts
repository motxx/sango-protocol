import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("RBTProportions", () => {
  let cetShares: Contract;
  let rbt: Contract;
  let s1: SignerWithAddress;

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    const CETHolderShares = await ethers.getContractFactory("CETHolderShares");
    cetShares = await CETHolderShares.deploy(rbt.address);
    await cetShares.deployed();
  });

  describe("addPayee", () => {
    it("Should add EOA as CET Holder", async () => {
      await cetShares.addPayee(s1.address, 1000); // Transaction NOT reverted.
    });

    it("Should not add SangoContract as CET Holder", async () => {
      const SangoContent = await ethers.getContractFactory("CETHolderShares");
      const sango = await SangoContent.deploy(rbt.address);
      await sango.deployed();

      await expect(cetShares.addPayee(sango.address, 1000)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'CETHolderShares: currently only EOA supported'");
      });
  });
});
