import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("Sango", () => {
  let graph: Contract;

  beforeEach(async () => {
    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();
    const SangoGraph = await ethers.getContractFactory("SangoGraph");
    graph = await SangoGraph.deploy(rbt.address);
    await graph.deployed();
  });

  describe("Basics", () => {
    it("addEdge and getWeight", async () => {
      const src  = "0x0000000000000000000000000000000000000001";
      const dest = "0x0000000000000000000000000000000000000002";
      graph.addEdge(src, dest, 10);
      expect(await graph.getWeight(src, dest)).to.equal(10);
      expect(await graph.getWeight(dest, src)).to.equal(0);
      expect(await graph.getWeight(src, src)).to.equal(0);
    });
  });
});
