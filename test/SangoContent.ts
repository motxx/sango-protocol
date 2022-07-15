import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySango } from "./helpers/utils";
import { Contract } from "ethers";

chai.use(solidity);

describe("SangoContent", async () => {
  let rbt: Contract;
  let s1: SignerWithAddress;

  const RBTProps = {
    creatorProp: 2000,
    cetBurnerProp: 2000,
    cbtStakerProp: 2000,
    primaryProp: 2000,
  };

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
  });

  it("Should construct DAG", async () => {
    const first = await deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...RBTProps,
    });
    const second = await deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address],
      primaryShares: [100],
      ...RBTProps,
    });
    const third = await deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, second.address],
      primaryShares: [200, 300],
      ...RBTProps,
    });
    assert.deepEqual(await first.getPrimaries(), []);
    assert.deepEqual(await second.getPrimaries(), [first.address]);
    assert.deepEqual(await third.getPrimaries(), [first.address, second.address]);
  });

  it("Should not have duplicate creators", async () => {
    await expect(deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address, s1.address],
      creatorShares: [1, 2],
      primaries: [],
      primaryShares: [],
      ...RBTProps,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });

  it("Should not have duplicate primaries", async () => {
    const first = await deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [],
      primaryShares: [],
      ...RBTProps,
    });
    await expect(deploySango({
      rbtAddress: rbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, first.address],
      primaryShares: [100, 200],
      ...RBTProps,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });
});
