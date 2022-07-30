import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("RBTProportions", () => {
  let rbtProp: Contract;

  beforeEach(async () => {
    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();
    const RBTProportions = await ethers.getContractFactory("RBTProportions");
    rbtProp = await RBTProportions.deploy(rbt.address);
    await rbtProp.deployed();
  });

  describe("setRBTProportions", () => {
    it("Should set correct proportions (no treasury)", async () => {
      await rbtProp.setRBTProportions(6000, 2000, 1500, 500);
      expect(await rbtProp.creatorProportion()).to.equal(6000);
      expect(await rbtProp.cetHolderProportion()).to.equal(2000);
      expect(await rbtProp.cbtStakerProportion()).to.equal(1500);
      expect(await rbtProp.primaryProportion()).to.equal(500);
    });

    it("Should set correct proportions (treasury exists)", async () => {
      await rbtProp.setRBTProportions(6000, 2000, 1000, 900);
      expect(await rbtProp.treasuryProportion()).to.equal(100);
    });
  });
});
