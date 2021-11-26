pragma solidity >=0.4.21 <0.7.0;
contract Weibo {
    // 管理员
    address admin;
    uint _numberOfUser;

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
    mapping(uint => address) id2address;

    //构造函数 部署合约的账户为admin账户
    constructor() public {
        admin = msg.sender;
        _numberOfUser = 0;
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
        id2address[_numberOfUser] = msg.sender;//存储id到用户
        _numberOfUser++;
        // 保存账户到昵称的双向映射关系
        address2name[msg.sender] = name;
        name2address[name] = msg.sender;
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
        users[msg.sender].blogs[users[msg.sender].blogNumber].valid = true;
        users[msg.sender].blogNumber++;
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

    //根据用户的姓名获取地址
    event GetUserNameByAddr(address sender, bool isSuccess, string name);
    function getUserNameByAddr(address user) public {
        if(bytes(address2name[user]).length == 0){
            emit GetUserNameByAddr(msg.sender, false, "用户不存在");
            return;
        }
        emit GetUserNameByAddr(msg.sender,true,address2name[user]);
        return;
    }

    //根据用户的地址获取姓名
    event GetUserAddrByName(address sender,bool isSuccess, address user);
    function getUserAddrByName(string memory name) public {
        if(name2address[name] == address(0)){
            emit GetUserNameByAddr(msg.sender,false,"没有该用户");
        }
        emit GetUserAddrByName(msg.sender,true,name2address[name]);
    }

    //根据id返回是否查询成功、昵称、账户、博文总数、like、dislike
    function getUserInfo(address author) view public returns (bool isSuccess,string memory name,address userAddr,uint blogAmount,uint like,uint dislike){
        if(!users[author].valid){
            return(false,"",address(0),0,0,0);
        }
        uint like = 0;
        uint dislike = 0;
        string storage name = users[author].name;
        address userAddr = users[author].addr;
        uint blogNumber = users[author].blogNumber;
        for(uint i = 0;i < blogNumber ; i++){
            like += users[author].blogs[i].like;
            dislike += users[author].blogs[i].dislike;
        }
        return(true,name,userAddr,blogNumber,like,dislike);
        
    }

    //整个系统用户总数、博文总数
    function getUserAmountAndBlogAmount() view public returns(uint userAmount,uint blogAmount){
        uint Allblogs = 0;
        for(uint i = 0;i<_numberOfUser;i++){
            Allblogs += users[id2address[i]].blogNumber;
        }
        return(_numberOfUser,Allblogs);
    }

    function getBlogByID(uint user_id,uint blog_id) view public returns(bool isSucess,uint timestamp,string memory content,uint like,uint dislike){
        if(id2address[user_id]==address(0) || users[id2address[user_id]].blogs[blog_id].valid==false){
            return(false,0,"",0,0);
        }
        uint timestamp = users[id2address[user_id]].blogs[blog_id].timestamp;
        string storage content = users[id2address[user_id]].blogs[blog_id].content;
        uint like = users[id2address[user_id]].blogs[blog_id].like;
        uint dislike = users[id2address[user_id]].blogs[blog_id].dislike;
        return(true,timestamp,content,like,dislike);

    }
}