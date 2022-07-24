import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

chai.use(solidity);

describe("Wrapped CBT", async () => {
  let cbtWallet: SignerWithAddress;
  let s1: SignerWithAddress;
  let cbt: Contract;
  let wCBT: Contract;

  beforeEach(async () => {
    [, cbtWallet, s1] = await ethers.getSigners();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);

    const WCBT = await ethers.getContractFactory("WrappedCBT");
    wCBT = await WCBT.deploy(cbt.address);
  });

  it("Should purchase", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await wCBT.connect(s1).purchase(100);
    expect(await cbt.balanceOf(s1.address)).to.equals(900);
    expect(await wCBT.balanceOf(s1.address)).to.equals(100);
  });
});
