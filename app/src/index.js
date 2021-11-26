import Web3 from "web3";
import weiboArtifact from "../../build/contracts/Weibo.json";

const App = {
  web3: null,
  account: null,
  weibo: null,

  start: async function () {
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

    this.refreshHome();
    this.refreshAdmin();
    this.refreshMy();
  },

  refreshBalance: async function () {
    const { getBalance } = this.meta.methods;
    const balance = await getBalance(this.account).call();

    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  createUser: async function () {
    const username = $("#inputUsername").val();
    if (username.length > 0 && username.length <= 64) {
      await this.weibo.methods.createUser(username).send({ from: this.account });
      this.weibo.events.CreateUser(function (error, event) {
        if (!error && event.returnValues.isSuccess) {
          console.log("注册账户成功");
        }
        else if (!error && !event.returnValues.isSuccess) {
          alert("账户注册失败: " + event.returnValues.message);
        }
      });
      // 清空输入框
      $("#inputUsername").val("");
      this.refreshHome();
      this.refreshMy();
      this.refreshAdmin();
    }
  },

  // 发微博
  postBlog: async function () {
    const content = $("#newBlogContent").val();
    if (content.length > 0 && content.length <= 160) {
      await this.weibo.methods.postBlog(content).send({ from: this.account });
      this.weibo.events.PostBlog(function (error, event) {
        if (!error && event.returnValues.isSuccess) {
          console.log("微博发送成功");
        }
        else if (!error && !event.returnValues.isSuccess) {
          alert("微博发送失败: " + event.returnValues.message);
        }
      });
      // 清空输入框
      $("#newBlogContent").val("");
      this.refreshHome();
      this.refreshMy();
      this.refreshAdmin();
    }
  },

  // 刷新主页
  refreshHome: async function () {
    // 获取所有blog
    let blogList = [];
    const userNumber = await this.weibo.methods.getUserAmount().call();
    for (let user_id = 0; user_id < userNumber; user_id++) {
      const userInfo = await this.weibo.methods.getUserInfo(user_id).call();
      if (userInfo.isSuccess) {
        const blogNumber = userInfo.blogNumber;
        for (let blog_id = 0; blog_id < blogNumber; blog_id++) {
          const blog = await this.weibo.methods.getBlog(user_id, blog_id).call();
          if (blog.isSuccess) {
            blog.user_name = userInfo.name;
            blog.user_id = user_id;
            blog.blog_id = blog_id;
            blog.timestamp = parseInt(blog.timestamp) * 1000;
            blogList.push(blog);
          }
        }
      }
    }
    // 按时间排序
    blogList.sort(function (a, b) {return b.timestamp - a.timestamp;});
    let blogListDOM = "";
    for (let i = 0; i < blogList.length; i++) {
      const blog = blogList[i];
      blogListDOM += `<div class="blog">
                        <h4>${blog.user_name}</h4>
                        <div class="blogTime">
                          ${new Date(blog.timestamp).toLocaleString("zh-CN")} &ensp;
                          <span user_id="${blog.user_id}" blog_id="${blog.blog_id}" onclick="App.like(this)"><i class="far fa-thumbs-up"></i></span> <span>${blog.like}</span> &ensp;
                          <span user_id="${blog.user_id}" blog_id="${blog.blog_id}" onclick="App.dislike(this)"><i class="far fa-thumbs-down"></i></span> <span>${blog.dislike}</span>
                        </div>
                        <p>
                        ${blog.content}
                        </p>
                      </div>`
    }
    $("#recentBlog").html(blogListDOM);
  },

  // 点赞
  like: async function (likeBtn) {
    const user_id = parseInt($(likeBtn).attr("user_id"));
    const blog_id = parseInt($(likeBtn).attr("blog_id"));
    await this.weibo.methods.likeBlog(user_id, blog_id).send({from: this.account});
    this.refreshHome();
    this.refreshMy();
    this.refreshAdmin();
  },

  // 点踩
  dislike: async function (dislikeBtn) {
    const user_id = parseInt($(dislikeBtn).attr("user_id"));
    const blog_id = parseInt($(dislikeBtn).attr("blog_id"));
    await this.weibo.methods.dislikeBlog(user_id, blog_id).send({from: this.account});
    this.refreshHome();
    this.refreshMy();
    this.refreshAdmin();
  },

  // 刷新个人页
  refreshMy: async function () {
    const id = await this.weibo.methods.getUserId(this.account).call();
    // 更新账户信息
    const userInfo = await this.weibo.methods.getUserInfo(id).call();
    if (userInfo.isSuccess) {
      $("#myID").text(id);
      $("#myName").text(userInfo.name);
      $("#myAddr").text(userInfo.addr);
      $("#myBlogNumber").text(userInfo.blogNumber);
      $("#myLike").text(userInfo.like);
      $("#myDislike").text(userInfo.dislike);
      let table = "";
      for (let blog_id = 0; blog_id < userInfo.blogNumber; blog_id++) {
        const blog = await this.weibo.methods.getBlog(id, blog_id).call();
        if (blog.isSuccess) {
          // NOTE: JS处理UNIX时间戳需要*1000
          table += `<tr>
                    <td>${blog_id}</td>
                    <td>${new Date(parseInt(blog.timestamp) * 1000).toLocaleString("zh-CN")}</td>
                    <td>${blog.content}</td>
                    <td>${blog.like}</td>
                    <td>${blog.dislike}</td>
                  </tr>`;
        }
        $("#myBlogTable").html(table);
      }
    }
  },

  // 刷新管理页
  refreshAdmin: async function () {
    // 更新后台信息
    const userAmount = await this.weibo.methods.getUserAmount().call();
    const blogAmount = await this.weibo.methods.getBlogAmount().call();
    $("#userAmount").text(userAmount);
    $("#blogAmount").text(blogAmount);
    // 更新用户列表
    let table = "";
    for (let id = 0; id < userAmount; id++) {
      const userInfo = await this.weibo.methods.getUserInfo(id).call();
      if (userInfo.isSuccess) {
        table += `<tr>
                    <td>${id}</td>
                    <td>${userInfo.name}</td>
                    <td>${userInfo.addr}</td>
                    <td>${userInfo.blogNumber}</td>
                    <td>${userInfo.like}</td>
                    <td>${userInfo.dislike}</td>
                  </tr>`;
      }
    }
    $("#userTable").html(table);
  }
};

window.App = App;

window.addEventListener("load", function () {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
    window.ethereum.on("accountsChanged", function () {
      App.start();
    });
    window.ethereum.on("networkChanged", function () {
      App.start();
    })
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
