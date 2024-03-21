//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";

contract CrossPolymer is UniversalChanIbcApp {

    string public constant QUERY_FOR_SECRET = "crossChainQuery";
    address public immutable deployer;
    string private _secret;

    event ReceivedSecret(string message);

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {
        deployer = msg.sender;
    }


    function sendUniversalPacket(address destPortAddr, bytes32 channelId, uint64 timeoutSeconds) external {
        bytes memory payload = abi.encode(msg.sender, QUERY_FOR_SECRET);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }


    function revealSecret() external returns(string memory){
        require(deployer == msg.sender, "Not you who deployed!");
        return _secret;
    }

    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket) { }


    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
    {
        _secret = abi.decode(ack.data, (string));
        emit ReceivedSecret(_secret);
    }


    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
    }
}

