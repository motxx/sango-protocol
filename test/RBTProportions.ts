import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("RBTProportions", () => {
  let rbtShares: Contract;

  beforeEach(async () => {
    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();
    const RBTShares = await ethers.getContractFactory("setRBTProportions");
    rbtShares = await RBTShares.deploy(rbt);
    await rbtShares.deployed();
  });

  describe("setRBTProportions", () => {
    it("Should set correct proportions", async () => {
    });
  });
});
