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
  let s2: SignerWithAddress;
  let cbt: Contract;
  let wCBT: Contract;

  beforeEach(async () => {
    [owner, cbtWallet, s1, s2] = await ethers.getSigners();
    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);
    await cbt.connect(cbtWallet).approve(cbtWallet.address, 10 ** 10);

    const WCBT = await ethers.getContractFactory("WrappedCBT");
    wCBT = await WCBT.deploy(cbt.address);
  });

  it("Should stake", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.receiveWCBT(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(900);
    expect(await wCBT.balanceOf(s1.address)).equals(100);
  });

  it("Should not stake multiple times unless unstaking(paying back)", async () => {
    // They cannot stake multiple times unless unstaking (paying back).
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await wCBT.stake(s1.address, 100);
    await wCBT.receiveWCBT(s1.address);
    await expect(wCBT.stake(s1.address, 100)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: already staked'");

    // After paying back, they can stake again.
    await wCBT.payback(s1.address);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await wCBT.stake(s1.address, 200);
    await wCBT.receiveWCBT(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(800);
    expect(await wCBT.balanceOf(s1.address)).equals(200);
  });

  it("Should not stake if less than minAmount", async () => {
    await wCBT.setMinAmount(200);
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await expect(wCBT.stake(s1.address, 199)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: less than minAmount'");
    await wCBT.stake(s1.address, 200);
  });

  it("Should receiveCBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.receiveWCBT(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(900);
    expect(await wCBT.balanceOf(s1.address)).equals(100);
  });

  it("Should not receiveCBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.setLockInterval(100); // XXX: stake後でも、wCBTの引き落とし前ならロックの効果がある
    await (expect(wCBT.receiveWCBT(s1.address))).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: within lock interval'");
  });

  it("Should payback", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.payback(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(100);
    expect(await wCBT.balanceOf(s1.address)).equals(0);
  });

  it("Should withdraw", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.withdraw(s2.address, 50);
    expect(await cbt.balanceOf(s2.address)).equals(50);
  });

  it("Should not payback if lack of CBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.stake(s1.address, 100);
    await wCBT.withdraw(s1.address, 50);
    await(expect(wCBT.payback(s1.address))).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: lack of CBT balance'");
  });
});
