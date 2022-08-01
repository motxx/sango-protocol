import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("RoyaltyProportions", () => {
  let props: Contract;

  beforeEach(async () => {
    const RoyaltyProportions = await ethers.getContractFactory("RoyaltyProportions");
    props = await RoyaltyProportions.deploy();
    await props.deployed();
  });

  describe("setRoyaltyProportions", () => {
    it("Should set correct proportions (no treasury)", async () => {
      await props.setRoyaltyProportions(6000, 2000, 1500, 500);
      expect(await props.creatorProportion()).to.equal(6000);
      expect(await props.cetHolderProportion()).to.equal(2000);
      expect(await props.cbtStakerProportion()).to.equal(1500);
      expect(await props.primaryProportion()).to.equal(500);
    });

    it("Should set correct proportions (treasury exists)", async () => {
      await props.setRoyaltyProportions(6000, 2000, 1000, 900);
      expect(await props.treasuryProportion()).to.equal(100);
    });
  });
});
