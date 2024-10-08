import chai, { assert, expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { deploySangoBy } from "./helpers/utils";

chai.use(solidity);

describe("Wrapped CBT", async () => {
  let cbtWallet: SignerWithAddress;
  let contentOwner: SignerWithAddress;
  let s1: SignerWithAddress;
  let cbt: Contract;
  let wCBT: Contract;

  beforeEach(async () => {
    [, contentOwner, cbtWallet, s1] = await ethers.getSigners();

    const CBT = await ethers.getContractFactory("CBT");
    cbt = await CBT.deploy(cbtWallet.address);
    await cbt.connect(cbtWallet).approve(cbtWallet.address, 10 ** 10);

    const sango = await deploySangoBy(contentOwner, {
      cbt: cbt.address,
      approvedTokens: ["0x0000000000000000000000000000000000012345"],
      creators: [s1.address],
      creatorShares: [1],
      primaries: [] as string[],
      primaryShares: [] as number[],
      creatorsAlloc: 2000,
      cetHoldersAlloc: 2000,
      cbtStakersAlloc: 2000,
      primariesAlloc: 2000,
    });

    wCBT = await ethers.getContractAt("WrappedCBT", await sango.wrappedCBT());
  });

  it("Should stake", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).claimWCBT();
    expect(await cbt.balanceOf(s1.address)).equals(900);
    expect(await wCBT.balanceOf(s1.address)).equals(100);
    expect(await wCBT.isStaking(s1.address)).true;
  });

  it("Should not stake multiple times unless payback", async () => {
    // They cannot stake multiple times unless payback.
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).claimWCBT();
    await expect(wCBT.connect(s1).stake(100)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: already staked'");

    // After payback, they can stake again.
    await wCBT.connect(s1).requestPayback();
    await wCBT.connect(contentOwner).acceptPayback(s1.address);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await wCBT.connect(s1).stake(200);
    await wCBT.connect(s1).claimWCBT();
    expect(await cbt.balanceOf(s1.address)).equals(800);
    expect(await wCBT.balanceOf(s1.address)).equals(200);
  });

  it("Should not stake if less than minStakeAmount", async () => {
    await wCBT.connect(contentOwner).setMinStakeAmount(200);
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 200);
    await expect(wCBT.connect(s1).stake(199)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: less than minStakeAmount'");
    await wCBT.connect(s1).stake(200);
  });

  it("Should claimWCBT after lock interval", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await wCBT.connect(contentOwner).setLockInterval(100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await ethers.provider.send("evm_mine", [10000000000]);
    await wCBT.connect(s1).stake(100);
    await ethers.provider.send("evm_mine", [10000000110]);
    await wCBT.connect(s1).claimWCBT();
    expect(await cbt.balanceOf(s1.address)).equals(900);
    expect(await wCBT.balanceOf(s1.address)).equals(100);
    expect(await wCBT.isStaking(s1.address)).true; // staking should be true after claimWCBT
  });

  it("Should claimWCBT if lock interval not set", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).claimWCBT();
    expect(await cbt.balanceOf(s1.address)).equals(900);
    expect(await wCBT.balanceOf(s1.address)).equals(100);
  });

  it("Should not claimWCBT before lock interval", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 1000);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(contentOwner).setLockInterval(100); // XXX: stake後でも、wCBTの引き落とし前ならロックの効果がある
    await (expect(wCBT.connect(s1).claimWCBT())).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: within lock interval'");
  });

  it("Should acceptPayback", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).requestPayback();
    await wCBT.connect(contentOwner).acceptPayback(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(100);
    expect(await wCBT.balanceOf(s1.address)).equals(0);
  });

  it("Should acceptPayback after claimWCBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(s1).claimWCBT();
    await wCBT.connect(s1).requestPayback();
    await wCBT.connect(contentOwner).acceptPayback(s1.address);
    expect(await cbt.balanceOf(s1.address)).equals(100);
    expect(await wCBT.balanceOf(s1.address)).equals(0); // wCBT should be burned in exchange for payback.
  });

  it("Should not acceptPayback if no payback request", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);

    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);

    await expect(wCBT.connect(contentOwner).acceptPayback(s1.address)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'SangoContent: no payback request'");
  });

  it("Should withdraw", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(contentOwner).withdraw(50);
    expect(await cbt.balanceOf(contentOwner.address)).equals(50);
  });

  it("Should not payback if lack of CBT", async () => {
    await cbt.connect(cbtWallet).transfer(s1.address, 100);
    await cbt.connect(s1).approve(wCBT.address, 100);
    await wCBT.connect(s1).stake(100);
    await wCBT.connect(contentOwner).withdraw(50);
    await wCBT.connect(s1).requestPayback();
    await expect(wCBT.connect(contentOwner).acceptPayback(s1.address)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'WrappedCBT: lack of CBT balance'");
  });
});
