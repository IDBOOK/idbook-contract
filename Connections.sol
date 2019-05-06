pragma solidity >=0.4.21 <0.6.0;

contract Connections {
    address public lord;
    mapping (address => mapping (bytes32 => bool)) connections;

    constructor() public {
        lord = msg.sender;
    }

    function connect(bytes32 fromOrg, bytes32 toOrg, address toMember) public {
        bytes32 connection = makeConnection(fromOrg, toOrg, toMember);

        require(!connections[msg.sender][connection], "Duplicate connection.");

        connections[msg.sender][connection] = true;
    }

    function disconnect(bytes32 fromOrg, bytes32 toOrg, address toMember) public {
        bytes32 connection = makeConnection(fromOrg, toOrg, toMember);

        require(connections[msg.sender][connection], "Connection does not exist.");

        delete connections[msg.sender][connection];
    }

    function connected(bytes32 fromOrg, bytes32 toOrg, address toMember)
        public view
        returns (bool)
    {
        return connections[msg.sender][makeConnection(fromOrg, toOrg, toMember)];
    }

    function makeConnection(bytes32 fromOrg, bytes32 toOrg, address toMember)
        internal pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(fromOrg, toOrg, toMember));
    }
}
