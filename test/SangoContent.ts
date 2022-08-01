import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploySango } from "./helpers/utils";
import { Contract } from "ethers";

chai.use(solidity);

describe("Contents Royalty Graph", async () => {
  let cbt: Contract;
  let s1: SignerWithAddress;

  const Props = {
    creatorProp: 2000,
    cetHolderProp: 2000,
    cbtStakerProp: 2000,
    primaryProp: 2000,
  };

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy("0x0000000000000000000000000000000000000001");
  });

  it("Should construct DAG", async () => {
    const first = await deploySango({
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      ...Props,
    });
    const second = await deploySango({
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address],
      primaryShares: [100],
      ...Props,
    });
    const third = await deploySango({
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, second.address],
      primaryShares: [200, 300],
      ...Props,
    });
    assert.deepEqual(await first.getPrimaries(), []);
    assert.deepEqual(await second.getPrimaries(), [first.address]);
    assert.deepEqual(await third.getPrimaries(), [first.address, second.address]);
  });

  it("Should not have duplicate creators", async () => {
    await expect(deploySango({
      cbt: cbt.address,
      creators: [s1.address, s1.address],
      creatorShares: [1, 2],
      primaries: [],
      primaryShares: [],
      ...Props,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });

  it("Should not have duplicate primaries", async () => {
    const first = await deploySango({
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [],
      primaryShares: [],
      ...Props,
    });
    await expect(deploySango({
      cbt: cbt.address,
      creators: [s1.address],
      creatorShares: [1],
      primaries: [first.address, first.address],
      primaryShares: [100, 200],
      ...Props,
    })).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: the payee already exists'");
  });
});
