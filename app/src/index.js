import Web3 from "web3";
import weiboArtifact from "../../build/contracts/Weibo.json";

const App = {
  web3: null,
  account: null,
  weibo: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = weiboArtifact.networks[networkId];
      this.weibo = new web3.eth.Contract(
        weiboArtifact.abi,
        deployedNetwork.address,
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
      // this.refreshBalance();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  refreshBalance: async function() {
    const { getBalance } = this.meta.methods;
    const balance = await getBalance(this.account).call();

    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  createUser: async function() {
    const username = $("#inputUsername").val();
    console.log(username);
    if (username.length > 0 && username.length <= 64) {
      await this.weibo.methods.createUser(username).send({from: this.account});
      this.weibo.events.CreateUser(function (error, event) {
        console.log(event);
        if (!error && event.returnValues.isSuccess) {
          alert("注册成功");
          this.refreshMy();
          this.refreshAdmin();
        }
        else if (!error && !event.returnValues.isSuccess) {
          alert("注册失败: "+event.returnValues.message);
        }
      });
    }
  },

  // 刷新主页
  refreshHome: async function() {
  },

  // 刷新个人页
  refreshMy: async function() {
  },

  // 刷新管理页
  refreshAdmin: async function() {
    const result = await this.weibo.methods.getAllUserAndBlogs().call();
    $("#userAmount").text(result.userAmount);
    $("#blogAmount").text(result.blogAmount);
  }
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
