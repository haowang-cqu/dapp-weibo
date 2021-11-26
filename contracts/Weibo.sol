pragma solidity >=0.4.21 <0.7.0;

contract Weibo {
    // 管理员
    address admin;
    uint256 userNumber;

    modifier onlyAdmin() {
        if (msg.sender == admin) _;
    }

    // 博文
    struct Blog {
        uint256 timestamp;
        string content;
        bool isValid;
        uint256 like;
        uint256 dislike;
    }

    // 微博用户
    struct User {
        uint256 id;
        address addr;
        string name;
        bool isValid;
        uint256 blogNumber;
        mapping(uint256 => Blog) blogs;
    }

    // 存储用户的hash表
    mapping(address => User) users;
    mapping(address => string) address2name;
    mapping(string => address) name2address;
    mapping(uint256 => address) id2address;

    //构造函数 部署合约的账户为admin账户
    constructor() public {
        admin = msg.sender;
        userNumber = 0;
    }

    // 返回admin账户
    function getAdmin() public view returns (address) {
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
        users[msg.sender].id = userNumber;
        users[msg.sender].addr = msg.sender;
        users[msg.sender].name = name;
        users[msg.sender].blogNumber = 0;
        users[msg.sender].isValid = true;
        // 保存id到账户的映射关系
        id2address[userNumber] = msg.sender;
        // 保存账户到昵称的双向映射关系
        address2name[msg.sender] = name;
        name2address[name] = msg.sender;
        userNumber++;
        emit CreateUser(msg.sender, true, "新用户创建成功");
    }

    // 发微博
    event PostBlog(address sender, bool isSuccess, string message);

    function postBlog(string memory content) public {
        // 微博长度超过160字节
        if (bytes(content).length == 0 || bytes(content).length > 160) {
            emit PostBlog(msg.sender, false, "博文长度不合理");
            return;
        }
        users[msg.sender].blogs[users[msg.sender].blogNumber].timestamp = now;
        users[msg.sender].blogs[users[msg.sender].blogNumber].content = content;
        users[msg.sender].blogs[users[msg.sender].blogNumber].like = 0;
        users[msg.sender].blogs[users[msg.sender].blogNumber].dislike = 0;
        users[msg.sender].blogs[users[msg.sender].blogNumber].isValid = true;
        users[msg.sender].blogNumber++;
        emit PostBlog(msg.sender, true, "微博发布成功");
    }

    // 给博文点赞
    event LikeBlog(address sender, bool isSuccess, string message);

    function likeBlog(uint256 user_id, uint256 blog_id) public {
        address addr = id2address[user_id];
        if (!users[addr].isValid) {
            emit LikeBlog(msg.sender, false, "用户不存在");
            return;
        }
        if (!users[addr].blogs[blog_id].isValid) {
            emit LikeBlog(msg.sender, false, "博文不存在");
            return;
        }
        users[addr].blogs[blog_id].like += 1;
        emit LikeBlog(msg.sender, true, "点赞成功");
    }

    // 给博文点踩
    event DislikeBlog(address sender, bool isSuccess, string message);
    function dislikeBlog(uint256 user_id, uint256 blog_id) public {
        address addr = id2address[user_id];
        if (!users[addr].isValid) {
            emit LikeBlog(msg.sender, false, "用户不存在");
            return;
        }
        if (!users[addr].blogs[blog_id].isValid) {
            emit LikeBlog(msg.sender, false, "博文不存在");
            return;
        }
        users[addr].blogs[blog_id].dislike += 1;
        emit LikeBlog(msg.sender, true, "点踩成功");
    }

    // 获取博文总数
    function getBlogAmount() public view returns (uint256) {
        uint256 blogAmount = 0;
        for (uint256 i = 0; i < userNumber; i++) {
            blogAmount += users[id2address[i]].blogNumber;
        }
        return blogAmount;
    }

    // 获取用户总数
    function getUserAmount() public view returns (uint256) {
        return userNumber;
    }

    // 根据根据address获取用户id
    function getUserId(address addr) public view returns (uint256) {
        return users[addr].id;
    }

    // 根据id返回是否查询成功、昵称、账户、博文数、like、dislike
    function getUserInfo(uint256 id)
        public
        view
        returns (
            bool isSuccess,
            string memory name,
            address addr,
            uint256 blogNumber,
            uint256 like,
            uint256 dislike
        )
    {
        if (id2address[id] == address(0)) {
            return (false, "", address(0), 0, 0, 0);
        }
        address _addr = id2address[id];
        uint256 _like = 0;
        uint256 _dislike = 0;
        for (uint256 i = 0; i < users[_addr].blogNumber; i++) {
            _like += users[_addr].blogs[i].like;
            _dislike += users[_addr].blogs[i].dislike;
        }
        return (true, users[_addr].name, users[_addr].addr, users[_addr].blogNumber, _like, _dislike);
    }

    // 根据用户id和博文id返回博文信息
    function getBlog(uint256 user_id, uint256 blog_id)
        public
        view
        returns (
            bool isSuccess,
            uint256 timestamp,
            string memory content,
            uint256 like,
            uint256 dislike
        )
    {
        address addr = id2address[user_id];
        if (!users[addr].isValid || !users[addr].blogs[blog_id].isValid) {
            return (false, 0, "", 0, 0);
        }
        Blog memory blog = users[addr].blogs[blog_id];
        return (true, blog.timestamp, blog.content, blog.like, blog.dislike);
    }
}
