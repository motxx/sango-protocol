import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySango } from "./helpers/utils";

chai.use(solidity);

describe("CETHolderShares", () => {
  let cetShares: Contract;
  let rbt: Contract;
  let s1: SignerWithAddress;
  let sCET: SignerWithAddress;

  beforeEach(async () => {
    [, s1, sCET] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    const CETHolderShares = await ethers.getContractFactory("CETHolderShares");
    cetShares = await CETHolderShares.deploy(rbt.address);
    await cetShares.deployed();
  });

  describe("addPayee", () => {
    it("Should add EOA as CET Holder", async () => {
      await cetShares.grantCETRole(sCET.address);
      await cetShares.connect(sCET).addPayee(s1.address, 1000); // Transaction NOT reverted.
    });

    it("Should not add SangoContract as CET Holder", async () => {
      const SangoContent = await ethers.getContractFactory("SangoContent");
      const CBT = await ethers.getContractFactory("CBT");
      const cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
      const sango = await deploySango({
        rbt: rbt.address,
        cbt: cbt.address,
        creators: [],
        creatorShares: [],
        primaries: [],
        primaryShares: [],
        creatorProp: 10000,
        cetHolderProp: 0,
        cbtStakerProp: 0,
        primaryProp: 0,
      });
      await sango.deployed();

      await cetShares.grantCETRole(sCET.address);
      await expect(cetShares.connect(sCET).addPayee(sango.address, 1000)).to.revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'CETHolderShares: only EOA supported'");
      });
  });
});
