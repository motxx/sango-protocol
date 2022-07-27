import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

chai.use(solidity);

describe("Content Believe Token", async () => {
  let s1: SignerWithAddress;
  let cbt: Contract;

  beforeEach(async () => {
    [, s1] = await ethers.getSigners();
  });

  it("Should deploy", async () => {
    const CBT = await ethers.getContractFactory("CBT");
    const dummyVestingWallet = "0x0000000000000000000000000000000000000001";
    cbt = await CBT.deploy(dummyVestingWallet);
    expect(await cbt.balanceOf(dummyVestingWallet)).to.equals(10 ** 14);
  });

  it("Should distribute vesting wallet CBT", async () => {
    // TODO
  });
});
