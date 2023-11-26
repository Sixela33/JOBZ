// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract JOBZ is Ownable, ReentrancyGuard {

    struct Recipient {
        uint256 tiempoTrabajado;
        uint256 timestampActivacion;
        uint256 pagoXhora;
        bool estaActivo;
        uint256 saldoAFavor;
        uint256 tiempoEntrePagos;
    }

    IERC20 public token;
    mapping(address => Recipient) recipients;

    event RelojActivado(address indexed recipient);
    event RelojDetenido(uint256 ganancia, address indexed recipient);
    event ReceptorAgregado(address indexed recipient, uint256 pagoXhora);
    event PagoRealizado(address indexed receptor, uint256 cantidad);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        uint256 infiniteAmount = type(uint256).max;
        token.approve(address(this), infiniteAmount);
    }

    function crearReceptor(address _recipient, uint256 _pagoXhora, uint256 _tiempoEntrePagos) external onlyOwner {
        require(_pagoXhora > 0, "El pago por hora debe ser mayor que cero");
        recipients[_recipient] = Recipient({
            tiempoTrabajado: 0,
            timestampActivacion: block.timestamp,
            pagoXhora: _pagoXhora,
            estaActivo: true,
            saldoAFavor: 0,
            tiempoEntrePagos: _tiempoEntrePagos
        });

        emit ReceptorAgregado(_recipient, _pagoXhora);
    }

    function activarReloj(address _recipient) external onlyOwner nonReentrant {
        require(!recipients[_recipient].estaActivo, "Este reloj ya esta activo");
        recipients[_recipient].timestampActivacion = block.timestamp;
        recipients[_recipient].estaActivo = true;
        emit RelojActivado(_recipient);
    }

    function pararReloj(address _recipient) external onlyOwner nonReentrant {
        Recipient storage recip = recipients[_recipient];
        require(recip.estaActivo, "Este reloj no esta activo");
        
        recip.tiempoTrabajado += block.timestamp - recip.timestampActivacion;
        uint256 ganancia = (recip.tiempoTrabajado * recip.pagoXhora) / recip.tiempoEntrePagos;
        
        recip.saldoAFavor += ganancia;
        recip.estaActivo = false;

        emit RelojDetenido(ganancia, _recipient);
    }

    function getSaldoAfavor() external view returns (uint256) {
        Recipient memory recip = recipients[msg.sender];
        if (!recip.estaActivo) {
            return recip.saldoAFavor;
        }

        uint256 saldoTotal = recip.saldoAFavor + (recip.tiempoTrabajado * recip.pagoXhora) / recip.tiempoEntrePagos;

        return saldoTotal;
    }

    function recibirPago() external nonReentrant {
        Recipient storage recip = recipients[msg.sender];

        if (recip.estaActivo) {
            recip.tiempoTrabajado += block.timestamp - recip.timestampActivacion;
            recip.saldoAFavor += (recip.tiempoTrabajado * recip.pagoXhora) / recip.tiempoEntrePagos;
            recip.timestampActivacion = block.timestamp;
        }

        uint256 amountToTransfer = recip.saldoAFavor;
        require(amountToTransfer > 0, "No hay fondos para transferir");
        require(token.balanceOf(address(owner())) >= amountToTransfer, "Saldo insuficiente en el contrato");

        token.transferFrom(owner(), msg.sender, amountToTransfer);

        recip.saldoAFavor = 0;
        emit PagoRealizado(msg.sender, amountToTransfer);
    }
}
