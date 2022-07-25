import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type SangoCtorArgs = {
  rbt: string;
  cbt: string;
  creators: string[];
  creatorShares: number[];
  primaries: string[];
  primaryShares: number[];
  creatorProp: number;
  cetBurnerProp: number;
  cbtStakerProp: number;
  primaryProp: number;
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
