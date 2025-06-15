// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

contract kipubank {

mapping(address => uint256) public balances;

uint256 public immutable LIMITE_UMBRAL;

uint256 public depositoCounts;
uint256 public retiroCounts;
// Evento para notificar el deposito
event evtDeposito(address indexed user, uint256 monto);

// Evento para notificar el retiro
event evtRetiro(address indexed user, uint256 monto);

    error MontoCero(); // Validacion del monto cuando es 0 
    error FondosInsuficientes(address user, uint256 requestedAmount, uint256 currentBalance); // Validacion de fondos insuficientes
    error LimiteUmbral(uint256 requestedAmount, uint256 maxAllowed); //Valida que no supere el umbral
    error ErrorTransferencia(address recipient, uint256 monto); // Valida si la transferencia fallo
    error UmbralPositivo(uint256 providedThreshold); // Validacion de que el monto del umbral no sea negativo

    modifier noCero() {
        if (msg.value == 0) {
            revert MontoCero();
        }
        _;
    }
    modifier noMontoCero(uint256 _monto) {
        if (_monto == 0) {
            revert MontoCero();
        }
        _;
    }
    modifier balanceInsuficiente(uint256 _monto) {
        if (balances[msg.sender] < _monto) {
            revert FondosInsuficientes(msg.sender, _monto, balances[msg.sender]);
        }
        _;
    }
    modifier noSuperaLimiteUmbral(uint256 _monto) {
        if (_monto > LIMITE_UMBRAL) {
            revert LimiteUmbral(_monto, LIMITE_UMBRAL);
        }
        _;
    }
    /// @dev Constructor del contrato
    /// @param _limiteUmbral Monto del umbral que se quiere setear al contrato
    constructor(uint256 _limiteUmbral) {
        if (_limiteUmbral == 0) { 
            revert UmbralPositivo(_limiteUmbral);
        }
        LIMITE_UMBRAL = _limiteUmbral;
    }

    /// @dev Funcion donde deposita el monto en el baul.
    /// @param monto Monto que desea retirar

    function deposito(uint256 monto) public payable noCero{

        // Guarda el monto en el deposito.
        balances[msg.sender] += monto;
        updateCounts(false);
        // Emite el evento de depósito.
        emit evtDeposito(msg.sender, monto);
    }

    /// @dev Funcion donde deposita el monto en el baul.
    /// @param monto Monto que desea retirar
    function retiro(uint256 monto)
        public
        noMontoCero(monto)        // Asegura que monto > 0
        balanceInsuficiente(monto) // Asegura que tenga saldo suficiente
        noSuperaLimiteUmbral(monto) // Asegura que no exceda el umbral
    {

        // Reduce el balance del usuario.
        balances[msg.sender] -= monto;

        // Transfiere monto.
        (bool success, ) = payable(msg.sender).call{value: monto}("");

        //Validador del proceso de Call.
        if (!success) {
            revert ErrorTransferencia(msg.sender, monto);
        }
        //Actualiza el contador
        updateCounts(true);
        
        // Emite el evento de retiro.
        emit evtRetiro(msg.sender, monto);
    }

    /// @dev Funcion donde actualiza los contadores.
     function updateCounts(bool _action) private {
        if(_action){
            retiroCounts++;
        }else  {    
            depositoCounts++;
        }
     }

    /// @dev Funcion donde obtiene la cantidad de Retiros realizados.
    /// @notice	Devuelve la cantidad de retiros realizados
    function verCantidadevtRetiros() external view returns (uint256 counter){
        return retiroCounts;
    }

    /// @dev Funcion donde obtiene la cantidad de Depositos realizados.
    /// @notice	Devuelve la cantidad de Depositos realizados
    function verCantidadevtDepositoos() external view returns (uint256 counter){
        return depositoCounts;
    }
}