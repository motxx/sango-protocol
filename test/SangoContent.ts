import chai, { assert } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";

chai.use(solidity);

describe("SangoContent", () => {
  let sango1: Contract;
  let sango2: Contract;
  let sango3: Contract;

  beforeEach(async () => {
    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();
    const SangoContent = await ethers.getContractFactory("SangoContent");
    const deploySango = async () => {
      const sango = await SangoContent.deploy(rbt.address);
      await sango.deployed();
      return sango;
    };
    sango1 = await deploySango();
    sango2 = await deploySango();
    sango3 = await deploySango();
  });

  it("Should add primary", async () => {
    await sango1.addPrimary(sango2.address, 100);
    await sango1.addPrimary(sango3.address, 200);
    await sango2.addPrimary(sango3.address, 300);
    assert.deepEqual(await sango1.getPrimaries(), [sango2.address, sango3.address]);
    assert.deepEqual(await sango2.getPrimaries(), [sango3.address]);
    assert.deepEqual(await sango3.getPrimaries(), []);
  });
});
