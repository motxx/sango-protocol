import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("SangoContent", async () => {
  let deploySango: (primaries: string[], shares: number[]) => Promise<Contract>;

  beforeEach(async () => {
    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();
    deploySango = async (primaries: string[], shares: number[]) => {
      const SangoContent = await ethers.getContractFactory("SangoContent");
      const sango = await SangoContent.deploy(rbt.address, primaries, shares);
      await sango.deployed();
      return sango;
    };
  });

  it("Should construct DAG", async () => {
    const first = await deploySango([], []);
    const second = await deploySango([first.address], [100]);
    const third = await deploySango([first.address, second.address], [200, 300]);
    assert.deepEqual(await first.getPrimaries(), []);
    assert.deepEqual(await second.getPrimaries(), [first.address]);
    assert.deepEqual(await third.getPrimaries(), [first.address, second.address]);
  });

  it("Should not have duplicate address (edges)", async () => {
    const first = await deploySango([], []);
    await expect(deploySango([first.address, first.address], [100, 200])).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'SangoContent: already primary'");
  });
});
