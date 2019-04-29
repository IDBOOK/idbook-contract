pragma solidity >=0.4.21 <0.6.0;

contract Connections {
    address lord;
    mapping (address => mapping (bytes => bool)) connections;

    constructor() public {
        lord = msg.sender;
    }

    function connect(bytes32 fromOrg, bytes32 toOrg, address toMember) public {
        bytes memory connection = abi.encodePacked(fromOrg, toOrg, toMember);

        require(!connections[msg.sender][connection], "Duplicate connection.");

        connections[msg.sender][connection] = true;
    }

    function disconnect(bytes32 fromOrg, bytes32 toOrg, address toMember) public {
        bytes memory connection = abi.encodePacked(fromOrg, toOrg, toMember);

        require(connections[msg.sender][connection], "Connection does not exist.");

        delete connections[msg.sender][connection];
    }

    function connected(bytes32 fromOrg, bytes32 toOrg, address toMember)
        public view
        returns (bool)
    {
        bytes memory connection = abi.encodePacked(fromOrg, toOrg, toMember);
        return connections[msg.sender][connection];
    }
}
