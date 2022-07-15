import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("SangoContent", async () => {
  type DeploySango = (creators: string[], creatorShares: number[],
    primaries: string[], primaryShares: number[]) => Promise<Contract>;

  let deploySango: DeploySango;

  let s1: SignerWithAddress;

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    const rbt = await RBT.deploy();

    deploySango = async (creators: string[], creatorShares: number[],
        primaries: string[], primaryShares: number[]) => {
      const SangoContent = await ethers.getContractFactory("SangoContent");
      const sango = await SangoContent.deploy(rbt.address, creators, creatorShares, primaries, primaryShares);
      await sango.deployed();
      return sango;
    };
  });

  it("Should construct DAG", async () => {
    const first = await deploySango([s1.address], [1], [], []);
    const second = await deploySango([s1.address], [1], [first.address], [100]);
    const third = await deploySango([s1.address], [1], [first.address, second.address], [200, 300]);
    assert.deepEqual(await first.getPrimaries(), []);
    assert.deepEqual(await second.getPrimaries(), [first.address]);
    assert.deepEqual(await third.getPrimaries(), [first.address, second.address]);
  });

  it("Should not have duplicate creators", async () => {
    await expect(deploySango([s1.address, s1.address], [1, 2], [], [])).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });

  it("Should not have duplicate primaries", async () => {
    const first = await deploySango([s1.address], [1], [], []);
    await expect(deploySango([s1.address], [1], [first.address, first.address], [100, 200])).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });
});
