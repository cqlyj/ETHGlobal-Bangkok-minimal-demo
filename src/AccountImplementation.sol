// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC6551Account} from "lib/erc6551/src/interfaces/IERC6551Account.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC6551Executable} from "lib/erc6551/src/interfaces/IERC6551Executable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {InteractionNft, ERC721URIStorage} from "src/InteractionNft.sol";

// All token bound accounts SHOULD be created via the singleton registry.

// All token bound account implementations MUST implement ERC-165 interface detection.

// All token bound account implementations MUST implement ERC-1271 signature validation.

contract AccountImplementation is
    IERC6551Account,
    IERC6551Executable,
    IERC165,
    IERC1271,
    InteractionNft
{
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private s_state;
    uint256 immutable i_deploymentChainId = block.chainid;
    address private approvedMinter;
    bool private initialized;
    address private toUserAddress;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Account__InvalidSigner();
    error Account__OnlyCallOperationAllowed();
    error AccountImplementation__AlreadyInitialized();
    error Account__NotValidSignerOrApprovedMinter();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyValidSignerOrApprovedMinter() {
        if (!_isValidSigner(msg.sender) && msg.sender != approvedMinter) {
            revert Account__NotValidSignerOrApprovedMinter();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() InteractionNft() {
        s_state = 0;
        initialized = false;
    }

    function initialize(address to) external onlyValidSignerOrApprovedMinter {
        toUserAddress = to;
    }

    // This function is only allowed to be called once
    // The minter will be set in the same time the account is created => in the Registry contract
    function setApprovedMinter(address minter) external {
        if (initialized) {
            revert AccountImplementation__AlreadyInitialized();
        }
        approvedMinter = minter;
        initialized = true;
    }

    function mintInteractionNFT(
        address campaignAddress
    ) external onlyValidSignerOrApprovedMinter {
        mintLinkedNFT(toUserAddress, campaignAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           IERC6551EXECUTABLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Executes a low-level operation if the caller is a valid signer on the account.
     *
     * Reverts and bubbles up error if operation fails.
     *
     * Accounts implementing this interface MUST accept the following operation parameter values:
     * - 0 = CALL
     * - 1 = DELEGATECALL
     * - 2 = CREATE
     * - 3 = CREATE2
     *
     * Accounts implementing this interface MAY support additional operations or restrict a signer's
     * ability to execute certain operations.
     *
     * @param to        The target address of the operation
     * @param value     The Ether value to be sent to the target
     * @param data      The encoded operation calldata
     * @param operation A value indicating the type of operation to perform
     * @return result The result of the operation
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory result) {
        if (!_isValidSigner(msg.sender)) {
            revert Account__InvalidSigner();
        }

        // for now, let's say only calls are allowed
        if (operation != 0) {
            revert Account__OnlyCallOperationAllowed();
        }

        // modify the account state
        s_state++;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            IERC6551ACCOUNT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows the account to receive Ether.
     *
     * Accounts MUST implement a `receive` function.
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received.
     */
    receive() external payable {}

    /**
     * @dev Returns the identifier of the non-fungible token which owns the account.
     *
     * The return value of this function MUST be constant - it MUST NOT change over time.
     *
     * @return chainId       The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId       The ID of the token
     */
    function token()
        public
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        // https://eips.ethereum.org/EIPS/eip-6551#reference-implementation
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    /**
     * @dev Returns a value that SHOULD be modified each time the account changes state.
     *
     * @return The current account state
     */
    function state() external view returns (uint256) {
        return s_state;
    }

    /**
     * @dev Returns a magic value indicating whether a given signer is authorized to act on behalf
     * of the account.
     *
     * MUST return the bytes4 magic value 0x523e3260 if the given signer is valid.
     *
     * By default, the holder of the non-fungible token the account is bound to MUST be considered
     * a valid signer.
     *
     * Accounts MAY implement additional authorization logic which invalidates the holder as a
     * signer or grants signing permissions to other non-holder accounts.
     *
     * @param  signer     The address to check signing authorization for
     * param  context    Additional data used to determine whether the signer is valid
     * @return magicValue Magic value indicating whether the signer is valid
     */

    // for now just say that the holder of the NFT is a valid signer
    function isValidSigner(
        address signer,
        bytes calldata /*context*/
    ) external view returns (bytes4 magicValue) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector; // 0x523e3260
        }
        return bytes4(0);
    }

    /*//////////////////////////////////////////////////////////////
                                IERC165
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                                IERC1271
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            getOwner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getOwner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != i_deploymentChainId) {
            return address(0);
        }
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == getOwner();
    }
}
