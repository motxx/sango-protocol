import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

chai.use(solidity);

describe("Wrapped CBT", async () => {
  let cbtWallet: SignerWithAddress;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let cbt: Contract;
  let wCBT: Contract;

  beforeEach(async () => {
    [owner, cbtWallet, s1] = await ethers.getSigners();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);

    const WCBT = await ethers.getContractFactory("WrappedCBT");
    wCBT = await WCBT.deploy(cbt.address);
  });

  it("Should stake", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).receiveWCBT();
    expect(await cbt.balanceOf(s1.address)).to.equals(900);
    expect(await wCBT.balanceOf(s1.address)).to.equals(100);
  });

  it("Should not stake if less than minAmount", async () => {
    await wCBT.setMinAmount(200);
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await expect(wCBT.connect(s1).stake(199)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: less than minAmount'");
    await wCBT.connect(s1).stake(200);
  });

  it("Should not stake if less than minAmount", async () => {
    await wCBT.setMinAmount(200);
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await expect(wCBT.connect(s1).stake(199)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: less than minAmount'");
    await wCBT.connect(s1).stake(200);
  });

  it("Should redeem", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await wCBT.connect(s1).stake(100);
    await wCBT.redeem(s1.address);
    expect(await cbt.balanceOf(s1.address)).to.equals(1000);
    expect(await wCBT.balanceOf(s1.address)).to.equals(0);
  });

  it("Should withdraw", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await wCBT.connect(s1).stake(100);
    await wCBT.withdraw(20);
    expect(await cbt.balanceOf(owner.address)).to.equals(20);
    expect(await cbt.balanceOf(wCBT.address)).to.equals(80);
  });

  it("Should not redeem if lack of CBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 1000);
    await wCBT.connect(s1).stake(100);
    await wCBT.withdraw(20);
    await(expect(wCBT.redeem(s1.address))).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: lack of CBT balance'");
  });
});
