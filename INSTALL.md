# Guia de Instalação - M-Westy Holster

Este guia explica como instalar e configurar o recurso **M-Westy Holster** em seu servidor FiveM.

---

## 📋 Pré-requisitos
Certifique-se de possuir os seguintes recursos instalados e iniciados no seu servidor:
1. **ox_lib** (Necessário para callbacks e menus)
2. Um framework compatível: **Qbox**, **QBCore**, **ESX**, **vRP Creative** ou rodar em modo **Standalone**.

---

## 🛠️ Passo a Passo de Instalação

1. **Extrair os arquivos**:
   - Extraia a pasta `M-Westy_Holster` dentro do diretório `resources/` do seu servidor (recomendado dentro de uma subpasta como `[standalone]`).

2. **Configurar o Framework**:
   - Abra o arquivo `config.lua`.
   - Localize a linha `Config.Framework` (linha 4) e defina o framework desejado:
     ```lua
     Config.Framework = 'qbox' -- Opções: 'auto', 'qb', 'qbox', 'esx', 'vrp', 'standalone'
     ```
     > [!TIP]
     > A opção `'auto'` tentará detectar o framework iniciado automaticamente. Definir o framework exato (como `'qbox'` ou `'qb'`) garante maior estabilidade na inicialização.

3. **Garantir a Inicialização no `server.cfg`**:
   - Abra o arquivo `server.cfg` do seu servidor.
   - Adicione as linhas garantindo que o `ox_lib` inicie antes do holster:
     ```cfg
     ensure ox_lib
     ensure M-Westy_Holster
     ```

---

## 🎮 Controles e Comandos do Usuário

* **Abrir Menu de Posições**: Tecla **F10** (Padrão) ou comando `/menuInteracciones`.
* **Ajustar Posição via Comando**: `/holster <posição>`
  * Exemplo para pistolas: `/holster boxers`, `/holster backhandgun`, `/holster hiphandgun`, `/holster leghandgun`, `/holster chesthandgun`.
  * Exemplo para fuzis: `/holster tacticalrifle`, `/holster assault`.
