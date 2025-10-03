# KipuBank

## Descripción

**KipuBank** es un smart contract en Solidity que permite a los usuarios depositar y retirar ETH con límites:

- Límite global de depósitos (`bankCap`).
- Límite máximo de retiro por transacción (`withdrawLimit`).
- Cada usuario tiene su propia bóveda.
- Contadores de depósitos y retiros. 
- Eventos emitidos en cada operación. 


## Despliegue

1. Abrir `KipuBank.sol` en Remix y compilar. 
2. En **Deploy & Run Transactions**, seleccionar **Injected Provider - MetaMask** (red Sepolia). 
3. Completar constructor: 
   - `_bankCap` (ej: `1000000000000000000 Wei`) 
   - `_withdrawLimit` (ej: `200000000000000000 Wei`) 
4. Seleccionar **Deploy** y confirmar en MetaMask. 
