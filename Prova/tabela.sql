-- =============================================
-- SISTEMA DE CONTROLE DE ESTOQUE - PRODUTOS DE LIMPEZA
-- MySQL 8.0+ | Versão Dark Blood 2025
-- Autor: Você (com ajuda do Grok)
-- =============================================

CREATE DATABASE IF NOT EXISTS estoque_limpeza CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE estoque_limpeza;

-- Tabela de Funcionários (responsáveis pelas movimentações)
CREATE TABLE funcionarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo ENUM('Almoxarife', 'Gerente', 'Auxiliar', 'Administrador') DEFAULT 'Auxiliar',
    ativo BOOLEAN DEFAULT TRUE,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Produtos
CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    composicao_quimica TEXT,
    fragrancia VARCHAR(80),
    volume VARCHAR(30) NOT NULL COMMENT 'ex: 500ml, 1L, 5L',
    tipo_embalagem ENUM('Plástica', 'Spray', 'Refil', 'Sachê', 'Galão', 'Balde') NOT NULL,
    aplicacao ENUM('Doméstica', 'Industrial', 'Hospitalar') NOT NULL,
    estoque_atual INT DEFAULT 0 CHECK (estoque_atual >= 0),
    estoque_minimo INT DEFAULT 10 CHECK (estoque_minimo >= 1),
    preco_unitario DECIMAL(10,2) DEFAULT NULL,
    lote VARCHAR(50),
    validade DATE,
    status ENUM('Ativo', 'Inativo', 'Vencido') DEFAULT 'Ativo',
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_nome (nome),
    INDEX idx_marca (marca),
    INDEX idx_aplicacao (aplicacao),
    INDEX idx_estoque_baixo (estoque_atual, estoque_minimo)
);

-- Tabela de Movimentações (Entrada e Saída)
CREATE TABLE movimentacoes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    funcionario_id INT NOT NULL,
    tipo_movimentacao ENUM('ENTRADA', 'SAÍDA') NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    motivo_saida ENUM('Venda', 'Uso Interno', 'Doação', 'Perda', 'Vencimento', 'Amostra') NULL,
    observacoes TEXT,
    data_movimentacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT,
    FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE RESTRICT,
    
    INDEX idx_data (data_movimentacao),
    INDEX idx_tipo (tipo_movimentacao),
    INDEX idx_produto (produto_id)
);

-- Trigger: Atualiza estoque automaticamente na entrada/saída
DELIMITER $$
CREATE TRIGGER trg_atualizar_estoque AFTER INSERT ON movimentacoes
FOR EACH ROW
BEGIN
    IF NEW.tipo_movimentacao = 'ENTRADA' THEN
        UPDATE produtos 
        SET estoque_atual = estoque_atual + NEW.quantidade 
        WHERE id = NEW.produto_id;
    ELSE
        UPDATE produtos 
        SET estoque_atual = estoque_atual - NEW.quantidade 
        WHERE id = NEW.produto_id;
    END IF;
END$$
DELIMITER ;

-- Trigger: Atualiza status de validade automaticamente
DELIMITER $$
CREATE TRIGGER trg_verificar_validade BEFORE UPDATE ON produtos
FOR EACH ROW
BEGIN
    IF NEW.validade IS NOT NULL AND NEW.validade < CURDATE() THEN
        SET NEW.status = 'Vencido';
    ELSEIF NEW.estoque_atual = 0 THEN
        SET NEW.status = 'Inativo';
    ELSE
        SET NEW.status = 'Ativo';
    END IF;
END$$
DELIMITER ;

-- View: Produtos com estoque abaixo do mínimo (igual ao seu /alertas)
CREATE VIEW vw_alertas_estoque_baixo AS
SELECT 
    p.id,
    p.nome,
    p.marca,
    p.volume,
    p.estoque_atual,
    p.estoque_minimo,
    p.aplicacao,
    ROUND((p.estoque_atual * 100.0 / p.estoque_minimo), 1) AS porcentagem_estoque
FROM produtos p
WHERE p.estoque_atual <= p.estoque_minimo
  AND p.status = 'Ativo'
ORDER BY p.estoque_atual ASC;

-- View: Histórico completo com nome do responsável
CREATE VIEW vw_historico_completo AS
SELECT 
    m.id,
    m.data_movimentacao,
    p.nome AS produto,
    p.marca,
    f.nome AS responsavel,
    m.tipo_movimentacao,
    m.quantidade,
    m.motivo_saida,
    m.observacoes
FROM movimentacoes m
JOIN produtos p ON m.produto_id = p.id
JOIN funcionarios f ON m.funcionario_id = f.id
ORDER BY m.data_movimentacao DESC;

-- Dados iniciais (pra já ter algo bonito quando abrir)
INSERT INTO funcionarios (nome, cargo) VALUES 
('João Silva', 'Almoxarife'),
('Maria Oliveira', 'Gerente'),
('Pedro Santos', 'Auxiliar');

INSERT INTO produtos (nome, marca, composicao_quimica, fragrancia, volume, tipo_embalagem, aplicacao, estoque_atual, estoque_minimo, validade) VALUES
('Detergente Neutro', 'Ypê', 'Tensoativos aniônicos', 'Neutro', '500ml', 'Plástica', 'Doméstica', 45, 20, '2026-12-01'),
('Álcool 70%', 'Coperalcool', 'Etanol 70%', 'Sem fragrância', '1L', 'Plástica', 'Hospitalar', 8, 15, '2027-03-15'),
('Desinfetante Floral', 'Pinho Sol', 'Cloreto de benzalcônio', 'Lavanda', '2L', 'Plástica', 'Doméstica', 3, 10, '2026-08-20'),
('Sabão em Pó', 'Omo', 'Surfactantes', 'Floral', '1kg', 'Sachê', 'Doméstica', 0, 5, '2026-11-30');