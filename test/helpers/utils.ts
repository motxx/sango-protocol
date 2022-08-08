import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type SangoCtorArgs = {
  cbt: string;
  approvedTokens: string[];
  creators: string[];
  creatorShares: number[];
  primaries: string[];
  primaryShares: number[];
  creatorsAlloc: number;
  cetHoldersAlloc: number;
  cbtStakersAlloc: number;
  primariesAlloc: number;
  cetName?: string;
  cetSymbol?: string;
};

export type DeploySangoFunction = (args: SangoCtorArgs) => Promise<Contract>;

export const deploySango = async (args: SangoCtorArgs) => {
  const SangoContent = await ethers.getContractFactory("SangoContent");
  args.cetName = args.cetName ?? "Content Excited Token";
  args.cetSymbol = args.cetSymbol ?? "CET";
  const sango = await SangoContent.deploy(args);
  await sango.deployed();
  return sango;
};

export const deploySangoBy = async (deployer: SignerWithAddress, args: SangoCtorArgs) => {
  const SangoContent = await ethers.getContractFactory("SangoContent");
  args.cetName = args.cetName ?? "Content Excited Token";
  args.cetSymbol = args.cetSymbol ?? "CET";
  const sango = await SangoContent.connect(deployer).deploy(args);
  await sango.deployed();
  return sango;
};

export const getCreators = async (sango: Contract) => {
  const instance = await sango.creators();
  return await ethers.getContractAt("ManagedRoyaltyClaimRight", instance);
};

export const getPrimaries = async (sango: Contract) => {
  const instance = await sango.primaries();
  return await ethers.getContractAt("FixedRoyaltyClaimRight", instance);
};

export const getWrappedCBT = async (sango: Contract) => {
  const instance = await sango.wrappedCBT();
  return await ethers.getContractAt("WrappedCBT", instance);
};

export const getCET = async (sango: Contract) => {
  const instance = await sango.cet();
  return await ethers.getContractAt("CET", instance);
};

export const getTreasury = async (sango: Contract) => {
  const instance = await sango.treasury();
  return await ethers.getContractAt("ManagedRoyaltyClaimRight", instance);
};
