// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VeritixTicket is ERC721URIStorage, Ownable {
    uint256 private _nextTicketId;

    struct EventInfo {
        string name;       // Nama event
        string location;   // Lokasi event
        string date;       // Tanggal event
        bool exists;       // Flag kalau event ada
    }

    struct TicketCategory {
        string name;       // Nama kategori (Cat 1, Cat 2, VIP, dll)
        uint256 price;     // Harga tiket
        uint256 maxSupply; // Maksimal tiket kategori ini
        uint256 sold;      // Jumlah tiket terjual
    }

    // eventId => EventInfo
    mapping(uint256 => EventInfo) public events;

    // eventId => (categoryId => TicketCategory)
    mapping(uint256 => mapping(uint256 => TicketCategory)) public categories;

    // Simpan jumlah kategori per event
    mapping(uint256 => uint256) public categoryCount;

    // ticketId => eventId
    mapping(uint256 => uint256) public ticketToEvent;

    // ticketId => categoryId
    mapping(uint256 => uint256) public ticketToCategory;

    uint256 public nextEventId;

    constructor() ERC721("VeritixTicket", "VTX") Ownable(msg.sender) {
        _nextTicketId = 1;
        nextEventId = 1;
    }

    /// @notice Buat event baru
    function createEvent(
        string memory _name,
        string memory _location,
        string memory _date
    ) external onlyOwner {
        events[nextEventId] = EventInfo({
            name: _name,
            location: _location,
            date: _date,
            exists: true
        });
        nextEventId++;
    }

    /// @notice Tambah kategori tiket ke event
    function addCategory(
        uint256 eventId,
        string memory _name,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        require(events[eventId].exists, "Event tidak ada");
        require(_maxSupply > 0, "Max supply harus > 0");

        uint256 catId = categoryCount[eventId] + 1;
        categories[eventId][catId] = TicketCategory({
            name: _name,
            price: _price,
            maxSupply: _maxSupply,
            sold: 0
        });
        categoryCount[eventId] = catId;
    }

    /// @notice Beli tiket berdasarkan kategori (satu tiket)
    function buyTicket(
        uint256 eventId,
        uint256 categoryId,
        string memory tokenURI
    ) external payable {
        require(events[eventId].exists, "Event tidak ada");
        TicketCategory storage cat = categories[eventId][categoryId];
        require(cat.maxSupply > 0, "Kategori tidak ada");
        require(cat.sold < cat.maxSupply, "Tiket kategori ini habis");
        require(msg.value == cat.price, "Harga salah");

        uint256 ticketId = _nextTicketId;
        _safeMint(msg.sender, ticketId);
        _setTokenURI(ticketId, tokenURI);

        ticketToEvent[ticketId] = eventId;
        ticketToCategory[ticketId] = categoryId;

        cat.sold++;
        _nextTicketId++;
    }

    /// @notice Beli banyak tiket sekaligus (batch purchase)
    function buyMultipleTickets(
        uint256 eventId,
        uint256 categoryId,
        string[] memory tokenURIs
    ) external payable {
        require(events[eventId].exists, "Event tidak ada");
        TicketCategory storage cat = categories[eventId][categoryId];
        require(cat.maxSupply > 0, "Kategori tidak ada");
        require(cat.sold + tokenURIs.length <= cat.maxSupply, "Tidak cukup tiket tersedia");
        require(msg.value == cat.price * tokenURIs.length, "Harga salah");

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 ticketId = _nextTicketId;
            _safeMint(msg.sender, ticketId);
            _setTokenURI(ticketId, tokenURIs[i]);

            ticketToEvent[ticketId] = eventId;
            ticketToCategory[ticketId] = categoryId;

            _nextTicketId++;
        }

        cat.sold += tokenURIs.length;
    }

    /// @notice Update metadata URI tiket (hanya bisa owner/admin)
    function updateTokenURI(uint256 ticketId, string memory newTokenURI) external onlyOwner {
        require(_ownerOf(ticketId) != address(0), "Ticket tidak ada");
        _setTokenURI(ticketId, newTokenURI);
    }

    /// @notice Tarik dana hasil jualan tiket
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Ambil detail tiket (event + kategori)
    function getTicketInfo(uint256 ticketId)
        external
        view
        returns (EventInfo memory, TicketCategory memory)
    {
        uint256 eventId = ticketToEvent[ticketId];
        uint256 categoryId = ticketToCategory[ticketId];
        return (events[eventId], categories[eventId][categoryId]);
    }
}
