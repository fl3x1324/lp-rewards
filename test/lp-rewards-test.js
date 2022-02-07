const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LPBadge", function () {
  it("Should return the new greeting once it's changed", async function () {
    const LPBadge = await ethers.getContractFactory("LPBadge");
    const lpBadge = await Greeter.deploy();
    await lpBadge.deployed();
  });
});
