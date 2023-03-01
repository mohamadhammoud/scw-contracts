// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.12;

import "../interfaces/ERC1155TokenReceiver.sol";
import "../interfaces/ERC721TokenReceiver.sol";
import "../interfaces/ERC777TokensRecipient.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ISignatureValidator.sol";
import "../SmartAccount.sol";

/// @title Default Callback Handler - returns true for known token callbacks
/// @author Richard Meissner - <richard@gnosis.pm>
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver, IERC165, ISignatureValidator {
    bytes32 public constant NAME = "Default Callback Handler";
    bytes32 public constant VERSION = "1.0.0";

    //keccak256(
    //    "SmartAccountMessage(bytes message)"
    //);
    bytes32 private constant SMART_ACCOUNT_MSG_TYPEHASH = 0xda033865d68bf4a40a5a7cb4159a99e33dba8569e65ea3e38222eb12d9e66eee;

    /**
     * Implementation of ISignatureValidator (see `interfaces/ISignatureValidator.sol`)
     * @dev Should return whether the signature provided is valid for the provided data.
     * @param _dataHash 32 bytes hash of the data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _dataHash
     * @return a bool upon valid or invalid signature with corresponding _data
     */
    function isValidSignature(bytes32 _dataHash, bytes memory _signature) public view override returns (bytes4) {
        // Caller should be a SmartAccount
        SmartAccount smartAccount = SmartAccount(payable(msg.sender));

        if (_signature.length == 0) {
            return (smartAccount.signedMessages(_dataHash) != 0) ? EIP1271_MAGIC_VALUE : bytes4(0xffffffff);
        } else {
            try smartAccount.checkSignatures(_dataHash, _signature) {
                return EIP1271_MAGIC_VALUE;
            } catch {
                return bytes4(0xffffffff);
            }
        }
    }

    function getMessageHash(bytes memory message) public view returns (bytes32) {
        bytes32 smartAccountMessageHash = keccak256(abi.encode(SMART_ACCOUNT_MSG_TYPEHASH, keccak256(message)));
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), SmartAccount(payable(msg.sender)).domainSeparator(), smartAccountMessageHash));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
