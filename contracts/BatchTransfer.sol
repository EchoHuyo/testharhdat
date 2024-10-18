//pragma solidity ^0.8.7;
//
//interface IERC20 {
//    function transferFrom(address from, address to, uint256 value) external returns (bool);
//}
//
//contract BatchTransfer {
//    address public owner;
//    constructor(){
//        owner = msg.sender;
//    }
//    modifier onlyOwner() {
//        require(msg.sender == owner, "Ownable: caller is not the owner");
//        _;
//    }
//    function batchTransfer(address[] memory _to, uint256 _value) payable public onlyOwner {
//        for (uint256 i = 0; i < _to.length; i++) {
//            payable(_to[i]).transfer(_value);
////            _to[i].call{value: _value}("");
//        }
//    }
//
//    function batchTransferToken(address _token, address[] memory _to, uint256 _value) public {
//        for (uint256 i = 0; i < _to.length; i++) {
//            IERC20(_token).transferFrom(msg.sender, _to[i], _value);
//        }
//    }
//
//    function batchToOneTransferToken(address _token, address[] memory _to, uint256 _value, address from) public {
//        for (uint256 i = 0; i < _to.length; i++) {
//            IERC20(_token).transferFrom(_to[i], from, _value);
//        }
//    }
//}