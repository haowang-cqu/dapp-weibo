const Weibo = artifacts.require("Weibo");

module.exports = function(deployer) {
  deployer.deploy(Weibo);
};
