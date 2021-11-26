pragma solidity >=0.4.21 <0.7.0;

contract Weibo {
    // 管理员
    address admin;

    modifier onlyAdmin() {
        if (msg.sender == admin) _;
    }
    
    // 博文
    struct Blog {
        uint   timestamp;
        string content;
        bool   valid;
        uint   like;
        uint   dislike;
    }

    // 微博用户
    struct User {
        address addr;
        string  name;
        bool    valid;
        uint    blogNumber;
        mapping(uint => Blog) blogs;
    }

    mapping(address => User) users;
    mapping(address => string) address2name;
    mapping(string => address) name2address;

    //构造函数 部署合约的账户为admin账户
    constructor() public {
        admin = msg.sender;
    }

    // 返回admin账户
    function getAdmin() view public returns (address) {
        return admin;
    }

    // 创建用户
    event CreateUser(address sender, bool isSuccess, string message);
    function createUser(string memory name) public {
        // name已经被占用
        if (name2address[name] != address(0)) {
            emit CreateUser(msg.sender, false, "昵称已被占用");
            return;
        }
        // msg.sender 已经注册过
        if (bytes(address2name[msg.sender]).length != 0) {
            emit CreateUser(msg.sender, false, "您的账户已被注册");
            return;
        }
        // 昵称长度超过64字节限制
        if (bytes(name).length == 0 || bytes(name).length > 64) {
            emit CreateUser(msg.sender, false, "昵称长度不合理");
            return;
        }
        users[msg.sender].addr = msg.sender;
        users[msg.sender].name = name;
        users[msg.sender].blogNumber = 0;
        users[msg.sender].valid = true;
        // 保存账户到昵称的双向映射关系
        address2name[msg.sender] = name;
        name2address[name] = msg.sender;
        emit CreateUser(msg.sender, true, "新用户创建成功");
    }

    // 发微博
    event PostBlog(address sender, bool isSuccess, string message);
    function postBlog(string memory content) public {
        // 微博长度超过160字节
        if (bytes(content).length > 160) {
            emit PostBlog(msg.sender, false, "博文长度超过限制");
            return;
        }
        users[msg.sender].blogs[users[msg.sender].blogNumber].timestamp = now;
        users[msg.sender].blogs[users[msg.sender].blogNumber].content = content;
        users[msg.sender].blogs[users[msg.sender].blogNumber].like = 0;
        users[msg.sender].blogs[users[msg.sender].blogNumber].dislike = 0;
        users[msg.sender].blogs[users[msg.sender].blogNumber].valid = true;
        emit PostBlog(msg.sender, true, "微博发布成功");
    }

    // 给博文点赞
    event LikeBlog(address sender, bool isSuccess, string message);
    function likeBlog(address author, uint id) public {
        if (!users[author].valid) {
            emit LikeBlog(msg.sender, false, "用户不存在");
            return;
        }
        if (!users[author].blogs[id].valid) {
            emit LikeBlog(msg.sender, false, "博文不存在");
            return;
        }
        users[author].blogs[id].like += 1;
        emit LikeBlog(msg.sender, true, "点赞成功");
    }

    // 给博文点踩
    event DislikeBlog(address sender, bool isSuccess, string message);
    function dislikeBlog(address author, uint id) public {
        if (!users[author].valid) {
            emit LikeBlog(msg.sender, false, "用户不存在");
            return;
        }
        if (!users[author].blogs[id].valid) {
            emit LikeBlog(msg.sender, false, "博文不存在");
            return;
        }
        users[author].blogs[id].dislike += 1;
        emit LikeBlog(msg.sender, true, "点踩成功");
    }
}